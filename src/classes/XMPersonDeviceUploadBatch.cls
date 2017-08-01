global class XMPersonDeviceUploadBatch implements Database.Batchable<XMPersonDeviceUploadIterator.XMContactWrapper>, Database.AllowsCallouts, Database.Stateful{

    private Integer maxCallouts = Limits.getLimitCallouts();

    private Integer totalContacts = 0;
    private Integer uniqueContacts = 0;
    private Integer associatedContacts = 0;
    private Integer newXmPersons = 0;
    private Integer newUsers = 0;
    private Integer newDevices = 0;


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

        XMPersonDeviceUploadError[] errors = new XMPersonDeviceUploadError[]{};

        for(XMPersonDeviceUploadIterator.XMContactWrapper wrapper : scope){

            system.debug('execute(): contact email - ' + wrapper.email);

            List<Contact> contactList = wrapper.contacts;
            if(contactList == null || contactList.size() == 0){
                continue;
            }
            uniqueContacts++;
            totalContacts += contactList.size();

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
                    newUsers++;

                    xmPerson__c profile = new xmPerson__c(
                            PrimaryContact__c = contactList[0].Id,
                            xmPersonUID__c = xmPersonGuid
                    );
                    personList.add(profile);
                } catch(Exception ex){
                    errors.add(new XMPersonDeviceUploadError( contactList[0].Id, 'Failed to create a person in xMatters. ' + ex.getMessage()));
                    continue;
                }

                try{
                    createDevice(contactList[0].Email, xmPersonGuid);
                    newDevices++;
                } catch(Exception ex){
                    errors.add(new XMPersonDeviceUploadError( contactList[0].Id, 'Failed to add a new device in xMatters. ' + ex.getMessage()));
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

        } // for loop

        // insert XM Persons
        if(personList.size() > 0){

            Database.SaveResult[] results = database.insert(personList, false);
            for(Integer i = 0; i < results.size(); i++){

                Database.SaveResult result = results[i];
                if(result.isSuccess()){
                    newXmPersons++;
                } else{
                    errors.add(new XMPersonDeviceUploadError( personList[i].PrimaryContact__c, 'Failed to create XM Person. ' + result.getErrors()[0].getMessage()));
                }

            }
        }

        // update contacts
        if(updateList.size() > 0){

            Database.SaveResult[] results = database.update(updateList, false);
            for(Integer i = 0; i < results.size(); i++){

                Database.SaveResult result = results[i];
                if(result.isSuccess()){
                    associatedContacts++;
                } else{
                    errors.add(new XMPersonDeviceUploadError( updateList[i].Id, 'Failed to associate contact with XM Person. ' + result.getErrors()[0].getMessage()));
                }

            }
        }

        if(errors.size() > 0){
            sendErrorEmail(errors);
        }


    } // execute()

    // send email when the job is completed
    global void finish(Database.BatchableContext context)
    {

        AsyncApexJob a = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                        TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob WHERE Id = :context.getJobId()
        ];

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { a.CreatedBy.Email };
        message.setToAddresses(toAddresses);
        message.setSubject('XMPersonDeviceUploadBatch has completed');

        string messageBody = 'The XMPersonDeviceUploadBatch process has completed.';

        messageBody = messageBody + ' The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures. \n\n';

        messageBody = messageBody + ' No of Contacts processed - ' + totalContacts + ' \n';
        messageBody = messageBody + ' No of Contacts with distinct email - ' + uniqueContacts + ' \n';
        messageBody = messageBody + ' No of users created in xMatters - ' + newUsers + ' \n';
        messageBody = messageBody + ' No of XM Persons created - ' + newXmPersons + ' \n';
        messageBody = messageBody + ' No of Contacts associated with XM Person - ' + associatedContacts + ' \n';
        messageBody = messageBody + ' No of devices added in xMatters - ' + newDevices + ' \n';

        message.setPlainTextBody(messageBody);

        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
        }catch(system.EmailException ex){
            system.debug(ex);
        }

    }

    // create user in xMatters
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

    // add a new device in xMatters
    private void createDevice(String email, String xmGuid){

        XMEmailDevice device = new XMEmailDevice();
        device.emailAddress = email;
        device.name = 'Work Email';
        device.owner = xmGuid;

        XMRestDeviceService deviceService = new XMRestDeviceService();
        XMDeviceModel deviceResponse = deviceService.createDeviceForPerson(device);

        system.debug('createDevice(): XMRestDeviceService deviceResponse - ' + deviceResponse);

    }

    // email error information
    private void sendErrorEmail(XMPersonDeviceUploadError[] errors){

        string subject = 'XMPersonDeviceUploadBatch Errors' ;
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{};
        toAddresses = Label.DEVErrorEmailRecipient.split(',');
        email.setSenderDisplayName('Salesforce Developers');
        email.setSubject(subject);
        email.setToAddresses(toAddresses);
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        string body = '<table align="center" border="1" cellpadding="0" cellspacing="0"><thead><th><b>Contact ID</b></th><th><b>Error message</b></th></thead><tbody>' ;
        for(XMPersonDeviceUploadError error : errors)
        {
            String hrefValue = baseUrl + '/' + error.contactId;
            body += '<tr><td><a href="' + hrefValue + '">' + error.contactId + '</a></td>';
            body += '<td>' + error.errorMessage + '</td></tr>';
        }

        body += '</tbody></table>';
        email.setHtmlBody(body);

        //send email message
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }catch(system.EmailException ex){
            system.debug(ex);
        }

    }

}