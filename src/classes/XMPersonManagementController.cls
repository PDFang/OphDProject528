public class XMPersonManagementController{

    public string xmPersonId{get;set;}
    public Contact currentContact{get;private set;}
    public XMPersonWrapper person{get;set;}
    public List<Contact> contactList{get;private set;}
    public List<AssociatedContactList> customContactList{get;private set;}
    public boolean isPersonMatch{get;private set;}
    public boolean isPersonRemoved{get;private set;}
    private string xmPersonGuid;
    public boolean displayBatchStatusText{get;private set;}
    public string nextFireTime{get;private set;}

    public string getTimezone(){
        return person != null ? person.timezone : null;

    }

    public string getTimezoneDisplayName(){
        return person != null && person.timezone != null ? TimeZone.getTimeZone(person.timezone).getDisplayName() : null;
    }

    public boolean getIsXmPerson(){
        return currentContact != null && currentContact.xmPerson__c != null;
    }

    public boolean getIsValidContact(){
        return currentContact != null;
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

        contactId = (string)controller.getId();
	    customContactList = new list<AssociatedContactList>();
        isPersonRemoved = false;
        loadContact();
        displayBatchStatusText = false;
        batchStatus();

    }

    private void loadContact(){
        try{
            // initialization
            isPersonMatch = false;
            contactList = new List<Contact>();

            // get current contact info
            xmPersonGuid = '';
            helper = new XMPersonManagementHelper(contactId);
            currentContact = helper.getCurrentContact();
            contactEmail = currentContact.Email;
            system.debug('XMPersonManagementController(): currentContact - '+currentContact);


            // find the associated person record
            if(currentContact.xmPerson__c != null && currentContact.xmPerson__r.xmPersonUID__c != null) {
                // current contact has person record
                xmPersonId = currentContact.xmPerson__c;
                xmPersonGuid = currentContact.xmPerson__r.xmPersonUID__c;
            }

            if(string.isNotBlank(contactEmail)){
                // get duplicate contacts
	            findDuplicateContacts();
                for(Contact cont : contactList){
                    if(cont.xmPerson__c != null && !isPersonMatch) {
                        // duplicate contact is associated with a person record
                        isPersonMatch = true;
                        xmPersonId = cont.xmPerson__c;
                        xmPersonGuid = cont.xmPerson__r.xmPersonUID__c;
                    }

                }
            }

            system.debug('xmPersonGuid =>' + xmPersonGuid);
            //if(string.isNotBlank(xmPersonGuid) && !isPersonRemoved)
            if(string.isNotBlank(xmPersonGuid)){
                person = XMPersonManagementHelper.getXmPersonByGuid(xmPersonGuid);
            }else if(currentContact.XmattersUid__c != null){
                isPersonMatch = true;
                xmPersonGuid = currentContact.XmattersUid__c;
                person = XMPersonManagementHelper.getXmPersonByGuid(xmPersonGuid);
            }
            if(person == null){
                person = new XMPersonWrapper(currentContact);
            }
            system.debug('person =>' + person);
            //findAssociatedContacts();
        } catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage() + ' at line ' + ex.getLineNumber()));
            return;
        }
    }

    // contacts with same email
    private void findDuplicateContacts(){

        contactList = new List<Contact>();
        if(string.isNotBlank(contactEmail)){
            Map<Id, Contact> contactMap = helper.getContactsByEmail(contactEmail);
            contactMap.remove(contactId);
            System.debug('contactMap' + contactMap);
            contactList.addAll(contactMap.values());

        }
	    customContactList = helper.getContactsWithProducts(contactList);
        System.debug('contactList' + contactList);
        System.debug('customContactList' + customContactList);

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

            if(null != contactList){
                for(Contact cnt: contactList){
                    helper.associateContact(cnt.Id, xmPersonId);
                }
            }
            findDuplicateContacts();
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
            if(xmPersonId == null){
                xmPersonId = [select Id from xmPerson__c where xmPersonUID__c = :currentContact.XmattersUid__c Limit 1].Id;
            }
            helper.associateContact('', xmPersonId);

            if(null != contactList){
                for(Contact contact: contactList){
                    helper.associateContact(contact.Id, xmPersonId);
                }
            }
            findDuplicateContacts();
            ApexPages.currentPage().getParameters().put('rowId', '');

        }
        catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }
        return null;
    }

    // remove contact's association from xmPerson
    public pagereference dissociateContact(){

        try{
            String contactRowId = ApexPages.currentPage().getParameters().get('removeId');
            string currentxmPersonGuid = [select xmPerson__r.xmPersonUID__c from Contact where id = :contactRowId Limit 1].xmPerson__r.xmPersonUID__c;
            helper.removeContactAssociation(contactRowId, currentxmPersonGuid);
            ApexPages.currentPage().getParameters().put('removeId', '');

            if(null != contactList){
                for(Contact contact: contactList){
                    helper.removeContactAssociation(contact.Id, currentxmPersonGuid);
                }
            }
//            findDuplicateContacts();
//            loadContact();
        }
        catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }
        return null;
    }




    // returns various device types
    public string getDeviceTypes()
    {
        return JSON.Serialize(XMPersonManagementHelper.deviceTypes);
    }

    // retrieves all the devices for a person in xMatters
    @RemoteAction
    public static string getUserDevices(String contactId)
    {
        XMDeviceWrapper[] newDeviceList = new XMDeviceWrapper[]{};
        try{
            String xmPersonGuid = XMPersonManagementHelper.getXmPersonGuid(contactId);

            newDeviceList = XMPersonManagementHelper.getUserDevices(xmPersonGuid);

        }catch(Exception ex){
            system.debug('getUserDevices(): exception - '+ex);
            newDeviceList = new XMDeviceWrapper[]{};
        }

        return JSON.Serialize(newDeviceList);

    }

    // adds a new device in xMatters
    @RemoteAction
    public static string addNewDevice(String contactId, String deviceName, String deviceValue)
    {
        String result;
        String message = '';

        try{
            String xmPersonGuid = XMPersonManagementHelper.getXmPersonGuid(contactId);

            String deviceId = XMPersonManagementHelper.addDevice(xmPersonGuid, deviceName, deviceValue);
            result = (deviceId != null) ? 'Success' : 'Failed';

        }catch(Exception ex){
            result = 'Failed';
            message = ex.getMessage();
        }

        return sendResponse(result, message);

    }

    // updates device information in xMatters including time frames
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

    // removes a device in xMatters
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

    // retrieves all available product cluster groups for the contact's account. In addition, groups selected for the xMatters person
    @RemoteAction
    public static string getProductGroups(String contactId, String type){

        XMGroupProductCluster[] xmGroupList;

        try{
            xmGroupList = XMPersonManagementHelper.getProductGroups(contactId, type);
        }catch(Exception ex){
            xmGroupList = new XMGroupProductCluster[]{};
        }

        return JSON.Serialize(xmGroupList);

    }

    // add or remove xMatters person to/from the group
    @RemoteAction
    public static string updateGroupSubscription(String groupJson , String contactId, string notificationtype){

        String result;
        String message = '';
        try{
            String xmPersonGuid = XMPersonManagementHelper.getXmPersonGuid(contactId);

            system.debug('updateGroups(): groupJson - '+groupJson);
            XMGroupProductCluster[] xmGroupList = (XMGroupProductCluster[])JSON.deserialize(groupJson, List<XMGroupProductCluster>.class);
            system.debug('updateGroups(): xmGroupList - '+xmGroupList);

            XMPersonManagementHelper.updateXmGroupSubscription(xmGroupList, xmPersonGuid, notificationtype);
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

    public void batchStatus(){

        list<xmGroupChangeRequest__c> groupChangeRequests
                = new list<xmGroupChangeRequest__c>([select id from xmGroupChangeRequest__c where NotificationProfile__c =: xmPersonId and xMDeviceId__c != null and Status__c = 'In Queue']);


        List<CronTrigger> jobs = new list<CronTrigger>([SELECT Id, NextFireTime  FROM CronTrigger WHERE State = 'WAITING' and CronJobDetail.Name like 'Group_Chnage_Request_batch%' order by CreatedDate desc Limit 1]);

        if(jobs.size() > 0){
            long milliseconds = jobs[0].NextFireTime.getTime() - Datetime.now().getTime();
            Long seconds = milliseconds / 1000;
            Long minutes = seconds / 60;
            if(minutes >= 1)
                nextFireTime = string.valueOf(minutes) + ' minutes';
            else
                 nextFireTime = string.valueOf(seconds) + ' seconds';
        }


        if(groupChangeRequests.size() > 0){
            displayBatchStatusText = true;
        }
        else{
            displayBatchStatusText = false;
        }


    }

    // returns various device types
    public void getContacts()
    {
        findDuplicateContacts();
        loadContact();
    }

}