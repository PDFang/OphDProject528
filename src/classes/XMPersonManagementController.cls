public class XMPersonManagementController {

    public string contactId{get;set;}
    public string emailString{get;set;}
    public string xmPersonId{get;set;}
    public Contact currentContact{get;private set;}
    public XMPerson person{get;set;}
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
            helper = new XMPersonManagementHelper();

            // get contact info
            contactId = (string)controller.getId();
            currentContact = helper.getContactById(contactId);
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
            person = new XMPerson(primaryContact);

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
            contactMap.remove(contactId);
            contactList.addAll(contactMap.values());
        }

    }

    // inserts a record in Notification Profile object and then calls out xMatters to create a Person
    public pagereference addPerson(){

        try{
            String xmGuid = helper.createXmPerson(person);
            if(xmGuid != null){
                xmPerson__c newPerson = new xmPerson__c(
                        PrimaryContact__c = currentContact.Id,
                        xmPersonUID__c = xmGuid,
                        Timezone__c = person.timezone
                );
                insert newPerson;
                xmPersonId = newPerson.Id;
                currentContact.xmPerson__c = newPerson.Id;
                update currentContact;
            }
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
        XMDevice[] newDeviceList = new XMDevice[]{};
        List<xmPerson__c> persons = [Select xmPersonUID__c from xmPerson__c where Id = :xmPersionId];
        if(persons.isEmpty()){
            return null;
        }

        XMRestDeviceService service = new XMRestDeviceService();
        List<XMDeviceModel> deviceList = service.getAllDevicesByxMattersUserId(persons[0].xmPersonUID__c);

        for(XMDeviceModel device: deviceList){
            XMDevice newDevice = new XMDevice();
            newDevice.DeviceType = device.name;
            if(device instanceof XMSmsDevice){
                newDevice.DeviceValue = ((XMSmsDevice)device).phoneNumber;
            }
            if(device instanceof XMEmailDevice){
                newDevice.DeviceValue = ((XMEmailDevice)device).emailAddress;
            }
            //newDevice.deviceId = device.id;
            newDeviceList.add(newDevice);
        }
        return JSON.Serialize(newDeviceList);
    }

    @RemoteAction
    public static string addNewDevice(String xmPersionId, String deviceType, String deviceValue)
    {
        String result;
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
        }

        return result;
    }

    public class XMPerson{
        public string firstName{get;set;}
        public string lastName{get;set;}
        public string email{get;set;}
        public string phone{get;set;}
        public string accountId{get;set;}
        public string accountName{get;set;}
        public string contactId{get;set;}
        public string xmPersonId{get;set;}
        public string timezone{get;set;}

        public XMPerson(Contact cont){
            this.firstName = cont.FirstName;
            this.lastName = cont.LastName;
            this.email = cont.Email;
            this.phone = cont.Phone;
            this.accountId = cont.AccountId;
            this.accountName = cont.Account.Name;
            this.contactId = cont.Id;
            this.xmPersonId = cont.xmPerson__c;
            this.timezone = (cont.xmPerson__c != null && cont.xmPerson__r.Timezone__c != null) ? cont.xmPerson__r.Timezone__c : '';
        }
    }


    public class XMDevice{
        public string deviceType{get;set;}
        public string deviceValue{get;set;}
        public string priorityThreshold{get;set;}
        public string deviceId{get;set;}

        public XMDevice(){

        }
    }

}