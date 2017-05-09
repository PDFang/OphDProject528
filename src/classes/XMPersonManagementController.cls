public class XMPersonManagementController {

    public string contactId{get;set;}
    public string emailString{get;set;}
    public string xmPersonId{get;set;}
    public Contact currentContact{get;private set;}
    public XMPersonWrapper person{get;set;}
    public List<Contact> contactList{get;private set;}
    public boolean isPersonMatch{get;private set;}

    public boolean getIsXmPerson(){
        return currentContact != null && currentContact.xmPerson__c != null;
    }

    public boolean getIsDuplicate(){
        return contactList != null && contactList.size() > 0;
    }

    public List<SelectOption> getTimezones(){
        return XMPersonManagementHelper.getTimezones();
    }

    private Contact primaryContact;
    private XMPersonManagementHelper helper;

    // constructor
    public XMPersonManagementController(ApexPages.StandardController controller){

        try{
            // initialization
            isPersonMatch = false;
            contactList = new List<Contact>();


            // get contact info
            contactId = (string)controller.getId();
            helper = new XMPersonManagementHelper(contactId);
            currentContact = helper.getCurrentContact();
            String contactEmail = currentContact.Email;

            // find the person record and its associated primary contact
            if(currentContact.xmPerson__c != null) {
                // current contact has person record
                xmPersonId = currentContact.xmPerson__c;
                primaryContact = helper.getContactById(currentContact.xmPerson__r.PrimaryContact__c);
            } else if(string.isNotBlank(contactEmail)){
                // if any of the duplicate contacts has a person record
                Map<Id, Contact> contactMap = helper.getContactsByEmail(contactEmail);
                contactMap.remove(contactId);
                for(Contact cont : contactMap.values()){
                    if(cont.xmPerson__c != null && !isPersonMatch) {
                        isPersonMatch = true;
                        xmPersonId = cont.xmPerson__c;
                        primaryContact = helper.getContactById(cont.xmPerson__r.PrimaryContact__c);
                    }
                }
            }

            if(primaryContact == null){
                primaryContact = currentContact;
            }
            person = new XMPersonWrapper(primaryContact);

            findAssociatedContacts();
        } catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            return;
        }
    }

    private void findAssociatedContacts(){

        contactList = new List<Contact>();
        if(string.isNotBlank(xmPersonId)){
            Map<Id, Contact> contactMap = helper.getContactsByXmPerson(xmPersonId);
            //contactMap.remove(contactId);
            contactList.addAll(contactMap.values());
        }

    }

    // calls out xMatters to create a Person and then inserts a record in Notification Profile object
    public pagereference addPerson(){

        try{
            xmPersonId = helper.createXmPerson(person);
            findAssociatedContacts();
        }
        catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }

        return null;
    }

    // associate the contact with an existing person record matched by email
    public pagereference associateContact(){


        try{
            currentContact.xmPerson__c = xmPersonId;
            update currentContact;
        }
        catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }
        return null;
    }

    public string getDeviceTypes()
    {
        return JSON.Serialize(XMPersonManagementHelper.deviceTypes);
    }

    @RemoteAction
    public static string getUserDevices(String xmPersionId)
    {
        XMDeviceWrapper[] newDeviceList = new XMDeviceWrapper[]{};
        List<xmPerson__c> persons = [Select xmPersonUID__c from xmPerson__c where Id = :xmPersionId];
        if(persons.size() > 0){
            XMRestDeviceService service = new XMRestDeviceService();
            List<XMDeviceModel> deviceList = service.getAllDevicesByxMattersUserId(persons[0].xmPersonUID__c);

            for(XMDeviceModel device: deviceList){
                XMDeviceWrapper newDevice = new XMDeviceWrapper();
                newDevice.deviceType = device.name;
                if(device instanceof XMSmsDevice){
                    newDevice.deviceValue = ((XMSmsDevice)device).phoneNumber;
                }
                if(device instanceof XMEmailDevice){
                    newDevice.deviceValue = ((XMEmailDevice)device).emailAddress;
                }
                newDevice.deviceId = device.id;
                newDeviceList.add(newDevice);
            }
        }


        return JSON.Serialize(newDeviceList);
    }

    @RemoteAction
    public static string addNewDevice(String xmPersionId, String deviceType, String deviceValue)
    {
        String result;
        String message = null;

        try{
            List<xmPerson__c> persons = [Select xmPersonUID__c from xmPerson__c where Id = :xmPersionId];

            XMDeviceModel device;
            if(deviceType.contains('Email')){
                XMEmailDevice emailDevice = new XMEmailDevice();
                emailDevice.emailAddress = deviceValue;
                device = emailDevice;

            } else if(deviceType.contains('Phone')){
                XMSmsDevice smsDevice = new XMSmsDevice();
                smsDevice.phoneNumber = '+1' + deviceValue;
                device = smsDevice;
            }
            device.name = deviceType;
            device.owner = persons[0].xmPersonUID__c;

            XMRestDeviceService service = new XMRestDeviceService();
            XMDeviceModel response = service.createDeviceForPerson(device);
            result = response != null ? 'Success' : 'Failed';
        }catch(Exception ex){
            result = 'Failed';
            message = ex.getMessage();
        }

        System.JSONGenerator generator = Json.createGenerator(true);
        generator.writeStartObject();
        generator.writeStringField('result', result);
        generator.writeStringField('message', message);
        return generator.getAsString();

    }

    @RemoteAction
    public static string updateDevice(String deviceJson){

        String result;
        String message = null;
        try{
            XMDeviceWrapper deviceWrapper = (XMDeviceWrapper)JSON.deserialize(deviceJson, XMDeviceWrapper.class);
            XMDeviceModel device;
            if(deviceWrapper.deviceType.contains('Email')){
                XMEmailDevice emailDevice = new XMEmailDevice();
                emailDevice.emailAddress = deviceWrapper.deviceValue;
                device = emailDevice;

            } else if(deviceWrapper.deviceType.contains('Phone')){
                XMSmsDevice smsDevice = new XMSmsDevice();
                smsDevice.phoneNumber = '+1' + deviceWrapper.deviceValue;
                device = smsDevice;
            }
            device.name = deviceWrapper.deviceType;
            device.id = deviceWrapper.deviceId;
            XMRestDeviceService service = new XMRestDeviceService();
            service.updateDeviceInformation(device);
            result = 'Success';
        }catch(Exception ex){
            result = 'Failed';
            message = ex.getMessage();
        }

        System.JSONGenerator generator = Json.createGenerator(true);
        generator.writeStartObject();
        generator.writeStringField('result', result);
        generator.writeStringField('message', message);
        return generator.getAsString();

    }

//    @RemoteAction
//    public static string deleteDevice(String deviceJson){
//
//        String result;
//        String message = null;
//        try{
//
//        }
//    }

}