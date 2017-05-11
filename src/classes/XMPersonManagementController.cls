public class XMPersonManagementController{

    public string contactId{get;set;}
    public string emailString{get;set;}
    public string xmPersonId{get;set;}
    public string timezone{get;set;}
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
                timezone = currentContact.xmPerson__r.Timezone__c;
                primaryContact = helper.getContactById(currentContact.xmPerson__r.PrimaryContact__c);
            } else if(string.isNotBlank(contactEmail)){
                // if any of the duplicate contacts has a person record
                Map<Id, Contact> contactMap = helper.getContactsByEmail(contactEmail);
                contactMap.remove(contactId);
                for(Contact cont : contactMap.values()){
                    if(cont.xmPerson__c != null && !isPersonMatch) {
                        isPersonMatch = true;
                        xmPersonId = cont.xmPerson__c;
                        timezone = cont.xmPerson__r.Timezone__c;
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
            timezone = person.timezone;
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
        try{
            List<xmPerson__c> persons = [Select xmPersonUID__c from xmPerson__c where Id = :xmPersionId];
            if(persons.size() > 0){
                newDeviceList = XMPersonManagementHelper.getUserDevices(persons[0].xmPersonUID__c);
            }
        }catch(Exception ex){
            system.debug('getUserDevices(): exception - '+ex);
            newDeviceList = new XMDeviceWrapper[]{};
        }

        return JSON.Serialize(newDeviceList);

    }

    @RemoteAction
    public static string addNewDevice(String xmPersionId, String deviceType, String deviceValue)
    {
        String result;
        String message = '';

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

        return sendResponse(result, message);

    }

    @RemoteAction
    public static string updateDevice(String deviceJson){

        String result;
        String message = '';
        try{
            system.debug('updateDevice(): deviceJson - '+deviceJson);
            XMDeviceWrapper deviceWrapper = (XMDeviceWrapper)JSON.deserialize(deviceJson, XMDeviceWrapper.class);
            system.debug('updateDevice(): deviceWrapper - '+deviceWrapper);

            XMPersonManagementHelper.updateDevice(deviceWrapper);
            result = 'Success';
        }catch(Exception ex){
            result = 'Failed';
            message = ex.getMessage();
        }

        return sendResponse(result, message);

    }

    @RemoteAction
    public static string deleteDevice(String deviceId){

        String result;
        String message = '';
        try{
            XMPersonManagementHelper.deleteDevice(deviceId);
            result = 'Success';
        }catch(Exception ex){
            result = 'Failed';
            message = ex.getMessage();
        }

        return sendResponse(result, message);
    }

    private static string sendResponse(String result, string message){

        System.JSONGenerator generator = Json.createGenerator(true);
        generator.writeStartObject();
        generator.writeStringField('result', result);
        generator.writeStringField('message', message);
        return generator.getAsString();

    }

}