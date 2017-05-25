public class XMPersonManagementController{

    public string xmPersonId{get;set;}
    public Contact currentContact{get;private set;}
    public XMPersonWrapper person{get;set;}
    public List<Contact> contactList{get;private set;}
    public boolean isPersonMatch{get;private set;}

    public string getTimezone(){
        return person != null ? person.timezone : null;
    }

    public string getTimezoneDisplayName(){
        return person != null && person.timezone != null ? TimeZone.getTimeZone(person.timezone).getDisplayName() : null;
    }

    public boolean getIsXmPerson(){
        return currentContact != null && currentContact.xmPerson__c != null;
    }

    public boolean getIsDuplicate(){
        return contactList != null && contactList.size() > 0;
    }

    public List<SelectOption> getTimezones(){
        return XMPersonManagementHelper.getTimezones();
    }

    private string contactId;
    private String contactEmail;
    private XMPersonManagementHelper helper;

    // constructor
    public XMPersonManagementController(ApexPages.StandardController controller){

        try{
            // initialization
            isPersonMatch = false;
            contactList = new List<Contact>();

            // get current contact info
            contactId = (string)controller.getId();
            helper = new XMPersonManagementHelper(contactId);
            currentContact = helper.getCurrentContact();
            contactEmail = currentContact.Email;
            system.debug('XMPersonManagementController(): currentContact - '+currentContact);

            String xmPersonGuid = null;
            // find the associated person record
            if(currentContact.xmPerson__c != null && currentContact.xmPerson__r.xmPersonUID__c != null) {
                // current contact has person record
                xmPersonId = currentContact.xmPerson__c;
                xmPersonGuid = currentContact.xmPerson__r.xmPersonUID__c;
            }

            if(string.isNotBlank(contactEmail)){
                // get duplicate contacts
                Map<Id, Contact> contactMap = helper.getContactsByEmail(contactEmail);
                contactMap.remove(contactId);
                contactList.addAll(contactMap.values());
                for(Contact cont : contactMap.values()){
                    if(cont.xmPerson__c != null && !isPersonMatch) {
                        // duplicate contact is associated with a person record
                        isPersonMatch = true;
                        xmPersonId = cont.xmPerson__c;
                        xmPersonGuid = cont.xmPerson__r.xmPersonUID__c;
                    }
                }
            }

            if(string.isNotBlank(xmPersonGuid)){
                person = XMPersonManagementHelper.getXmPersonByGuid(xmPersonGuid);
            } else{
                person = new XMPersonWrapper(currentContact);
            }

            //findAssociatedContacts();
        } catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            return;
        }
    }

    // contacts with same email
    private void findDuplicateContacts(){

        contactList = new List<Contact>();
        if(string.isNotBlank(contactEmail)){
            Map<Id, Contact> contactMap = helper.getContactsByEmail(contactEmail);
            contactMap.remove(contactId);
            contactList.addAll(contactMap.values());
        }

    }

    // go back to contact details
    public pagereference goBack(){

        return new ApexPages.StandardController(currentContact).view();

    }

    // calls out xMatters to create a Person and then inserts a record in Notification Profile object
    public pagereference addPerson(){

        try{
            xmPersonId = helper.createXmPerson(person);
            system.debug('addPerson(): currentContact - '+currentContact);
            //findDuplicateContacts();
        }
        catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }

        return null;
    }

    // associate the contact with an existing person record matched by email
    public pagereference associateContact(){

        try{
            String contactRowId = ApexPages.currentPage().getParameters().get('rowId');
            helper.associateContact(contactRowId, xmPersonId);
            ApexPages.currentPage().getParameters().put('rowId', '');
            findDuplicateContacts();
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
    public static string getUserDevices(String xmPersonId)
    {
        XMDeviceWrapper[] newDeviceList = new XMDeviceWrapper[]{};
        try{
            List<xmPerson__c> persons = [Select xmPersonUID__c from xmPerson__c where Id = :xmPersonId];
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
    public static string addNewDevice(String contactId, String deviceName, String deviceValue)
    {
        String result;
        String message = '';

        try{
            List<Contact> contactList = [
                    Select xmPerson__c, xmPerson__r.xmPersonUID__c
                    from Contact where Id = :contactId
            ];
            String xmPersonGuid = contactList[0].xmPerson__r.xmPersonUID__c;
            system.debug('addNewDevice(): contactList - '+ contactList);

            String deviceId = XMPersonManagementHelper.addDevice(xmPersonGuid, deviceName, deviceValue);
            result = (deviceId != null) ? 'Success' : 'Failed';
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

    @RemoteAction
    public static string getProductGroups(String contactId){

        XMGroupProductCluster[] xmGroupList;

        try{
            xmGroupList = XMPersonManagementHelper.getProductGroups(contactId);
        }catch(Exception ex){
            xmGroupList = new XMGroupProductCluster[]{};
        }

        return JSON.Serialize(xmGroupList);

    }

    @RemoteAction
    public static string updateGroups(String groupJson){

        String result;
        String message = '';
        try{
            system.debug('updateGroups(): groupJson - '+groupJson);
            XMGroupProductCluster[] xmGroupList = (XMGroupProductCluster[])JSON.deserialize(groupJson, XMGroupProductCluster.class);
            system.debug('updateGroups(): xmGroupList - '+xmGroupList);

            //XMPersonManagementHelper.updateDevice(deviceWrapper);
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