global class XMPersonDeviceUploadBatch implements Database.Batchable<XMPersonDeviceUploadIterator.XMContactWrapper>, Database.AllowsCallouts, Database.Stateful{

    private Integer maxCallouts = Limits.getLimitCallouts();

    public class XMPersonDeviceUploadError{
        public String contactId;
        public String errorMessage;

        public XMPersonDeviceUploadError(String contactId, String message){
            this.contactId = contactId;
            this.errorMessage = message;
        }
    }

    // custom iterator
    global Iterable<XMPersonDeviceUploadIterator.XMContactWrapper> start(Database.BatchableContext context)
    {
        return new XMPersonDeviceUploadIterable();
    }

    global void execute(Database.BatchableContext context, List<XMPersonDeviceUploadIterator.XMContactWrapper> scope)
    {
        system.debug('execute(): no of records - ' + scope.size());

        system.debug('execute(): no of permissible callouts - ' + maxCallouts);

        if(scope.size() > (maxCallouts / 2)){
            throw new LimitException('Warning: Too many callouts anticipated. Please try with a smaller batch size.');
        }

        List<Contact> updateList = new List<Contact>();
        List<xmPerson__c> personList = new List<xmPerson__c>();

        for(XMPersonDeviceUploadIterator.XMContactWrapper wrapper : scope){

            system.debug('execute(): contact email - ' + wrapper.email);

            List<Contact> contactList = wrapper.contacts;
            if(contactList == null || contactList.size() == 0){
                continue;
            }

            system.debug('execute(): contactList - ' + contactList);

            Boolean hasPerson = false;
            String xmPersonGuid = null;

            // ID's of contacts that has no XMPerson
            Set<Id> contactIds = new Set<Id>();

            // any of the contacts has an XM Person
            for(Contact cont : contactList){
                if(cont.xmPerson__c != null && String.isNotBlank(cont.xmPerson__r.xmPersonUID__c)){
                    hasPerson = true;
                    xmPersonGuid = cont.xmPerson__r.xmPersonUID__c;
                } else{
                    contactIds.add(cont.Id);
                }
            }

            // create user for this Contact in xMatters if there isn't one already
            if(!hasPerson){

                try{
                    xmPersonGuid = createPerson(contactList[0]);
                    xmPerson__c profile = new xmPerson__c(
                            PrimaryContact__c = contactList[0].Id,
                            xmPersonUID__c = xmPersonGuid
                    );
                    personList.add(profile);
                } catch(Exception ex){
                    //errors.add(new XMPersonDeviceUploadError( cont.Id, ex.getMessage()));
                    continue;
                }

                try{
                    createDevice(contactList[0].Email, xmPersonGuid);
                } catch(Exception ex){
                    //errors.add(new XMPersonDeviceUploadError( cont.Id, ex.getMessage()));
                    continue;
                }

            }

            // relate duplicate contacts to XM person
            for(Id contactId : contactIds){
                updateList.add(
                        new Contact(
                            Id = contactId,
                            xmPerson__r = new xmPerson__c(
                                    xmPersonUID__c = xmPersonGuid
                            )
                        )
                );
            }

        }

        if(personList.size() > 0){
            database.insert(personList, false);
        }

        if(updateList.size() > 0){
            database.update(updateList, false);
        }

    } // execute()

    private String createPerson(Contact cont) {

        XMPersonModel newPerson = new XMPersonModel();
        newPerson.targetName = cont.Id;
        newPerson.firstName = cont.FirstName;
        newPerson.lastName = cont.LastName;
        newPerson.externalKey = cont.Id;
        newPerson.timezone = 'US/Mountain';


        XMRestPerson personService = new XMRestPerson();
        XMPersonModel response = personService.createPerson(newPerson);

        system.debug('createPerson(): XMRestPerson response - ' + response);

        return response.Id;

    }

    private void createDevice(String email, String xmGuid){
        XMEmailDevice device = new XMEmailDevice();
        device.emailAddress = email;
        device.name = 'Work Email';
        device.owner = xmGuid;

        XMRestDeviceService deviceService = new XMRestDeviceService();
        XMDeviceModel deviceResponse = deviceService.createDeviceForPerson(device);

        system.debug('createDevice(): XMRestDeviceService deviceResponse - ' + deviceResponse);


    }

/*
    // deprecate this method
    global Database.QueryLocator start(Database.BatchableContext context)
    {

        String contactSoql = 'SELECT Id, FirstName, LastName, Email  FROM Contact '
                + 'WHERE Deactivated__c = false AND Email != NULL AND xmPerson__c = NULL '
                + 'AND Contact_Role__c INCLUDES (\'Event Notification\',\'Maintenance Notification\') and CreatedDate > YESTERDAY '
                + 'order by Email, CreatedDate';
        return Database.getQueryLocator(contactSoql);
    }*/

    /*private List<Contact> GetNewContacts (List<Contact> contacts)
    {
        Set<Id> resultIds = (new Map<Id,SObject>(contacts)).keySet();
        List<String> Emails = getStringFieldFromList(contacts, 'Email');

        system.debug('GetNewContacts ==> resultIds ==> ' + resultIds);
        system.debug('GetNewContacts ==> Emails ==> ' + Emails);

        List<Contact>contactsNew = [SELECT Id, FirstName, LastName, Email, xmPerson__c FROM Contact WHERE Deactivated__c = false AND Email != NULL  AND Contact_Role__c INCLUDES ('Event Notification','Maintenance Notification')  And Id Not in: resultIds and Email in: Emails];
        system.debug('GetNewContacts ==> ' + contactsNew);
        return contactsNew;
    }

    private List<String> getStringFieldFromList(List<sObject> records, String field) {
        List<String> result = new List<String>();

        for (sObject record:records) {
            // Assumes excluding null/empty values
            if (!isBlank((string)record.get(field))) {
                result.add((string)record.get(field));
            }
        }

        return result;
    }

    private Boolean isBlank(String s) {
        if (s == null || s == '') {
            return true;
        }

        return false;
    }

    global void execute(Database.BatchableContext context, List<Contact> scope)
    {

        Map<string,string> existingXmPerson = new Map<string,string>();

        XMBusinessLayer business = new XMBusinessLayer();

        //Add additional contacts to the list that have emails that are the same as the emails in the list
        List<Contact> NewScopecontact = GetNewContacts(scope);

        for (Contact con : NewScopecontact )
        {
            System.debug ('execute():NewScopecontact == > processing');
            if (con.xmPerson__c != null)
            {
                System.debug ('execute():NewScopecontact == > adding existing xmPerson ==> ' +  con);
                existingXmPerson.put(con.Email, con.xmPerson__c );  //populate the list with existing xmPersons
            }
            else
            {
                System.debug ('execute():Adding Additional scope contact == > ' + con);
                scope.add(con);
            }
        }

        system.debug('execute(): no of records - ' + scope.size());
        system.debug('execute(): no of permissible callouts - ' + maxCallouts);

        //final scope size check our max call outs
        if(scope.size() > (maxCallouts / 2)){
            throw new LimitException('Warning: Too many callouts anticipated. Please try with a smaller batch size.');
        }

        List<xmPerson__c> personList = new List<xmPerson__c>();
        List<Contact> contactList = new List<Contact>();

        XMPersonDeviceUploadError[] errors = new XMPersonDeviceUploadError[]{};
        string xmPersonId;


        for(Contact cont: scope){
            XMPersonModel newPerson = new XMPersonModel();
            newPerson.targetName = cont.Id;
            newPerson.firstName = cont.FirstName;
            newPerson.lastName = cont.LastName;
            newPerson.externalKey = cont.Id;
            newPerson.timezone = 'US/Mountain';

            String xmGuid = null;
            try {

                system.debug('execute():processing ==>' +  cont );
                if (existingXmPerson.containsKey(cont.Email) == true)
                {
                    system.debug('execute():Getting xmPersonId ==>' +  cont );
                    xmPersonId = existingXmPerson.get(cont.Email);
                }

                if (xmPersonId == null)
                {
                    system.debug('xmPersonId ==>' +  xmPersonId );
                    XMRestPerson personService = new XMRestPerson();
                    XMPersonModel response = personService.createPerson(newPerson);

                    system.debug('execute(): XMRestPerson response - ' + response);

                    xmGuid = response.Id;

                    xmPerson__c profile = new xmPerson__c(
                            PrimaryContact__c = cont.Id,
                            xmPersonUID__c = xmGuid
                    );
                    //personList.add(profile);
                    database.insert(profile);
                    cont.xmPerson__c = profile.Id;
                    system.debug ('execute():new Profile ==> ' +  profile);
                    system.debug ('execute():new xmPerson ==> ' +  cont.xmPerson__c );
                }
                else
                {
                    system.debug ('execute():Setting contact to existing xmPerson ==> ' + xmPersonId );
                    cont.xmPerson__c = xmPersonId;
                    xmPersonId = null;
                }
                contactList.add(cont);
            }catch(Exception ex){
                errors.add(new XMPersonDeviceUploadError( cont.Id, ex.getMessage()));
                continue;
            }

            if(String.isBlank(xmGuid)){
                errors.add(new XMPersonDeviceUploadError( cont.Id, 'execute():User was not created in xMatters.'));
                continue;
            }

            XMEmailDevice device = new XMEmailDevice();
            device.emailAddress = cont.Email;
            device.name = 'Work Email';
            device.owner = xmGuid;

            try{
                XMRestDeviceService deviceService = new XMRestDeviceService();
                XMDeviceModel deviceResponse = deviceService.createDeviceForPerson(device);
                system.debug('execute(): adding existingXMPerson to the list - ' + cont.xmPerson__c);
                existingXmPerson.put(cont.Email, cont.xmPerson__c );
                system.debug('execute(): XMRestDeviceService deviceResponse - ' + deviceResponse);

            }catch(Exception ex){
                errors.add(new XMPersonDeviceUploadError( cont.Id, ex.getMessage()));
                continue;
            }


        }

        //if(personList.size() > 0){
        //    database.insert(personList, false);
        //}

        if(contactList.size() > 0){
            database.update(contactList, false);
        }


    }*/

    global void finish(Database.BatchableContext context)
    {


    }
}