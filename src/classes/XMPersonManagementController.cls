public class XMPersonManagementController {

    public string contactId{get;set;}
    public string emailString{get;set;}
    public string xmPersonId{get;set;}
    public list<XMPerson> personLists{get;set;}
    public List<Contact> contactList{get;private set;}
    public boolean isPersonMatch{get;private set;}

    public boolean getIsXmPerson(){
        return currentContact != null && currentContact.xmPerson__c != null;
    }

    public boolean getIsDuplicate(){
        return contactList != null && contactList.size() > 1;
    }

    public Contact currentContact{get;private set;}
    public Contact primaryContact{get;private set;}
    private XMPersonManagementHelper helper;

    // constructor
    public XMPersonManagementController(ApexPages.StandardController controller){

        try{
            // initialization
            isPersonMatch = false;
            personLists = new list<XMPerson>();
            contactList = new List<Contact>();
            helper = new XMPersonManagementHelper();

            // get contact info
            contactId = (string)controller.getId();
            currentContact = helper.getContactById(contactId);
            String contactEmail = currentContact.Email;

            // get duplicate contacts
            Map<Id, Contact> contactMap = new Map<Id, Contact>();
            if(string.isNotBlank(contactEmail)){
                contactMap = helper.getContactsByEmail(emailString);
//                contactMap.remove(contactId);
//                contactList.addAll(contactMap.values());
            }

            // find the person record
            if(currentContact.xmPerson__c != null) {
                // current contact has person record
                xmPersonId = currentContact.xmPerson__c;
                primaryContact = contactMap.get(currentContact.xmPerson__r.PrimaryContact__c);
            } else{
                for(Contact cont : contactList){
                    if(cont.xmPerson__c != null && !isPersonMatch) {
                        isPersonMatch = true;
                        xmPersonId = cont.xmPerson__c;
                        primaryContact = contactMap.get(cont.xmPerson__r.PrimaryContact__c);
                    }
                }
            }

            if(primaryContact != null){
                XMPerson person = new XMPerson(primaryContact);
                personLists.add(person);
            }

        } catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            return;
        }
    }

    // inserts a record in Notification Profile object and then calls out xMatters to create a Person
    public pagereference addPerson(){

        try{
            String xmGuid = helper.createXmPerson(currentContact);
            if(xmGuid != null){
                xmPerson__c newPerson = new xmPerson__c(
                        PrimaryContact__c = currentContact.Id,
                        xmPersonUID__c = xmGuid

                );
                insert newPerson;
                xmPersonId = newPerson.Id;
                currentContact.xmPerson__c = newPerson.Id;
                update currentContact;
                XMPerson person = new XMPerson(currentContact);
                personLists.add(person);
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

    public void getContact(String contactId){

        personLists = new list<XMPerson>();

        for(Contact cont : [
                select FirstName, LastName, Email, Phone, Id, AccountId,
                        Account.Name, xmPerson__c
                from Contact where id =: contactId
        ]){
            XMPerson person = new XMPerson(cont);
            personLists.add(person);
        }

    }

    public string getDeviceTypes()
    {
        return JSON.Serialize(XMPersonManagementHelper.deviceTypes);
    }

    @RemoteAction
    public static string getUserDevices(String xmPersionId)
    {

        List<xmPerson__c> persons = [Select xmPersonUID__c from xmPerson__c where Id = :xmPersionId];

        XMRestDeviceService service = new XMRestDeviceService();
        List<XMDeviceModel> deviceList = service.getAllDevicesByxMattersUserId(persons[0].xmPersonUID__c);
        XMDevice[] newDeviceList = new XMDevice[]{};
        for(XMDeviceModel device: deviceList){
            XMDevice newDevice = new XMDevice();
            newDevice.DeviceType = device.name;
            if(device instanceof XMSmsDevice){
                newDevice.DeviceValue = ((XMSmsDevice)device).phoneNumber;
            }
            if(device instanceof XMEmailDevice){
                newDevice.DeviceValue = ((XMEmailDevice)device).emailAddress;
            }
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
                smsDevice.phoneNumber = deviceValue;
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
        public XMPerson(Contact cont){
            this.firstName = cont.FirstName;
            this.lastName = cont.LastName;
            this.email = cont.Email;
            this.phone = cont.Phone;
            this.accountId = cont.AccountId;
            this.accountName = cont.Account.Name;
            this.contactId = cont.Id;
            this.xmPersonId = cont.xmPerson__c;
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