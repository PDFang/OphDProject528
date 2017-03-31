global class AccountImpactCalculationBatch implements Database.Batchable<Sobject>, Database.Stateful{

    public String query;
    private Integer lastNMonths = 13;
    private Integer totalAccounts = 0;

    static final Set<String> recordTypes = new Set<String>{
            'Customers',
            'Resell Customers',
            'Resell Partner'
    };

    public AccountImpactCalculationBatch(){

        this.query = 'Select Id, Social_Media_Presence__c, CustomerSegment__c, Brand_Visibility__c, '
            + 'Industry_Leadership_Vocality__c, Risk_of_Leaving__c, GYRStatus__c, '
            + 'Age_of_Customer_in_Months__c, IsPartner__c, Referenceable__c, Account_Net_Score__c '
            + 'from Account where RecordType.Name IN :recordTypes '
            + 'and Age_of_Customer_in_Months__c != 0 '
            + 'and (inContactGoLive__c = LAST_N_MONTHS:' + lastNMonths + ' or VCC_Go_Live__c = LAST_N_MONTHS:' + lastNMonths + ')';
        system.debug('AccountImpactCalculationBatch(): query - '+ query);

        AppConfiguration__c config = AppConfiguration__c.getInstance();
        if(config != null && config.Go_Live_Last_N_Months__c != null) {
            lastNMonths = (Integer)config.Go_Live_Last_N_Months__c;
        }
        system.debug('AccountImpactCalculationBatch(): lastNMonths - '+ lastNMonths);

    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope)
    {
        try{
            ImpactCalculationService service = new ImpactCalculationService(new AccountImpactCalculationImpl());
            service.CalculateAccountNetScore(scope);
            totalAccounts += scope.size();
        }catch(Exception ex){
            system.debug('execute(): Exception - ' + ex);
            SendErrorEmail(ex, null);
        }

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
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    mail
            });
        } catch(System.EmailException ex){
            // Just eat it
        }

    }

    private void sendErrorEmail(Exception ex, String recordId){
        try{
            inContactBaseClass.SendErrorEmail(ex, recordId);
        } catch(System.EmailException emailEx){
            system.debug('sendErrorEmail() EmailException - ' + emailEx);
        }
    }

}