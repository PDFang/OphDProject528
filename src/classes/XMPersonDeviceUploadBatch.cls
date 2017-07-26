global class XMPersonDeviceUploadBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful{

    private Integer maxCallouts = Limits.getLimitCallouts();

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

        system.debug(scope.size());
        system.debug(maxCallouts);

        if(scope.size() > (maxCallouts / 2)){
            throw new LimitException('Warning: Too many callouts anticipated. Please try with a smaller batch size. ');
        }

        List<xmPerson__c> personList = new List<xmPerson__c>();
        List<Contact> contactList = new List<Contact>();

        for(Contact cont: scope){

            XMPersonModel newPerson = new XMPersonModel();
            newPerson.targetName = cont.Id;
            newPerson.firstName = cont.FirstName;
            newPerson.lastName = cont.LastName;
            newPerson.externalKey = cont.Id;
            newPerson.timezone = 'US/Mountain';
            XMRestPerson restService = new XMRestPerson();
            XMPersonModel response = restService.createPerson(newPerson);

            String xmGuid = response.Id;
            xmPerson__c profile;
            if(xmGuid != null){

                XMEmailDevice device = new XMEmailDevice();
                device.emailAddress = cont.Email;
                device.name = 'Work Email';
                device.owner = xmGuid;

                XMRestDeviceService service = new XMRestDeviceService();
                XMDeviceModel deviceResponse = service.createDeviceForPerson(device);

                profile = new xmPerson__c(
                        PrimaryContact__c = cont.Id,
                        xmPersonUID__c = xmGuid
                );
                personList.add(profile);

                cont.xmPerson__c = profile.Id;
                contactList.add(cont);

            }

        }

        if(personList.size() > 0){
            insert personList;
        }

        if(contactList.size() > 0){
            update contactList;
        }


    }

    global void finish(Database.BatchableContext context)
    {


    }
}