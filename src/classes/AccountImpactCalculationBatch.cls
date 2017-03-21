/**
 * Created by mohandaas.rangaswamy on 3/20/2017.
 */

global class AccountImpactCalculationBatch implements Database.Batchable<Sobject>, Database.Stateful{

    public String query;
    private Integer totalAccounts = 0;

    static final Set<String> recordTypes = new Set<String>{
            'Customers',
            'Resell Customers',
            'Resell Partner'
    };

    public AccountImpactCalculationBatch(){

        Map<String,Schema.RecordTypeInfo> rtMapByName  = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Set<Id> recordTypeIds = new Set<Id>();
        recordTypeIds.add(rtMapByName.get('Customers').getRecordTypeId());
        recordTypeIds.add(rtMapByName.get('Resell Customers').getRecordTypeId());
        recordTypeIds.add(rtMapByName.get('Resell Partner').getRecordTypeId());

        this.query = 'Select Id, Social_Media_Presence__c, CustomerSegment__c, Brand_Visibility__c, '
            + 'Industry_Leadership_Vocality__c, Risk_of_Leaving__c, GYRStatus__c, '
            + 'Age_of_Customer_in_Months__c, IsPartner__c, Referenceable__c '
            + 'from Account where Age_of_Customer_in_Months__c != null '
            + 'and RecordTypeId IN :recordTypeIds '
            + 'and (inContactGoLive__c = LAST_N_DAYS:365 or VCC_Go_Live__c = LAST_N_DAYS:365)';
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope)
    {
        ImpactCalculationService service = new ImpactCalculationService(new AccountImpactCalculationImpl());
        service.CalculateAccountNetScore(scope);
        totalAccounts += scope.size();
    }

    global void finish(Database.BatchableContext BC)
    {
        AsyncApexJob a = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                        TotalJobItems, ExtendedStatus
                FROM AsyncApexJob
                WHERE Id = :BC.getJobId()
        ];

        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{
                userInfo.getUserEmail()
        };
        mail.setToAddresses(toAddresses);
        mail.setSubject('Account Impact Calculation Batch ' + a.Status);
        mail.setPlainTextBody('The batch Apex job processed '
                + a.TotalJobItems
                + ' batches with '
                + a.NumberOfErrors
                + ' failures.' + '\n\n'
                + 'The batch Apex job processed ' + totalAccounts + ' accounts.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                mail
        });

    }
}