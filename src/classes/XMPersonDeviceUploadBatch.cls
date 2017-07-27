global class XMPersonDeviceUploadBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful{

    private Integer maxCallouts = Limits.getLimitCallouts();

    public class XMPersonDeviceUploadError{
        public String contactId;
        public String errorMessage;

        public XMPersonDeviceUploadError(String contactId, String message){
            this.contactId = contactId;
            this.errorMessage = message;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext context)
    {

        String contactSoql = 'SELECT Id, FirstName, LastName, Email FROM Contact '
                + 'WHERE Deactivated__c = false AND Email != NULL AND xmPerson__c = NULL '
                + 'AND Contact_Role__c INCLUDES (\'Event Notification\',\'Maintenance Notification\') '
                + 'order by Email, CreatedDate';
        return Database.getQueryLocator(contactSoql);

    }

    global void execute(Database.BatchableContext context, List<Contact> scope)
    {

        system.debug('execute(): no of records - ' + scope.size());
        system.debug('execute(): no of permissible callouts - ' +maxCallouts);

        if(scope.size() > (maxCallouts / 2)){
            throw new LimitException('Warning: Too many callouts anticipated. Please try with a smaller batch size.');
        }

        List<xmPerson__c> personList = new List<xmPerson__c>();
        List<Contact> contactList = new List<Contact>();

        XMPersonDeviceUploadError[] errors = new XMPersonDeviceUploadError[]{};

        for(Contact cont: scope){

            XMPersonModel newPerson = new XMPersonModel();
            newPerson.targetName = cont.Id;
            newPerson.firstName = cont.FirstName;
            newPerson.lastName = cont.LastName;
            newPerson.externalKey = cont.Id;
            newPerson.timezone = 'US/Mountain';

            String xmGuid = null;
            try{
                XMRestPerson personService = new XMRestPerson();
                XMPersonModel response = personService.createPerson(newPerson);

                system.debug('execute(): XMRestPerson response - ' + response);

                xmGuid = response.Id;

                xmPerson__c profile = new xmPerson__c(
                        PrimaryContact__c = cont.Id,
                        xmPersonUID__c = xmGuid
                );
                personList.add(profile);

                cont.xmPerson__c = profile.Id;
                contactList.add(cont);

            }catch(Exception ex){
                errors.add(new XMPersonDeviceUploadError( cont.Id, ex.getMessage()));
                continue;
            }

            if(String.isBlank(xmGuid)){
                errors.add(new XMPersonDeviceUploadError( cont.Id, 'User was not created in xMatters.'));
                continue;
            }

            XMEmailDevice device = new XMEmailDevice();
            device.emailAddress = cont.Email;
            device.name = 'Work Email';
            device.owner = xmGuid;

            try{
                XMRestDeviceService deviceService = new XMRestDeviceService();
                XMDeviceModel deviceResponse = deviceService.createDeviceForPerson(device);

                system.debug('execute(): XMRestDeviceService deviceResponse - ' + deviceResponse);

            }catch(Exception ex){
                errors.add(new XMPersonDeviceUploadError( cont.Id, ex.getMessage()));
                continue;
            }

        }

        if(personList.size() > 0){
            database.insert(personList, false);
        }

        if(contactList.size() > 0){
            database.update(contactList, false);
        }


    }

    global void finish(Database.BatchableContext context)
    {


    }
}