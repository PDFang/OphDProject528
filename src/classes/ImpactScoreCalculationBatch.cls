global class ImpactScoreCalculationBatch implements Database.Batchable<Sobject>, Database.Stateful{

    private string query;
    private ImpactCalculationConstants.ImpactScoreType scoreType;
    private integer batchSizeRecordCount;

    Set<String> recordTypes = ImpactCalculationConstants.recordTypes;

    public ImpactScoreCalculationBatch(ImpactCalculationConstants.ImpactScoreType scoreType){

        this.scoreType = scoreType;

        if (scoreType == ImpactCalculationConstants.ImpactScoreType.AccountNetScore) { // Account object
            this.query = 'Select Id, Social_Media_Presence__c, CustomerSegment__c, Brand_Visibility__c, '
                    + 'Industry_Leadership_Vocality__c, Risk_of_Leaving__c, GYRStatus__c, '
                    + 'Age_of_Customer_in_Months__c, IsPartner__c, Referenceable__c '
                    + 'from Account where RecordType.Name IN :recordTypes';

        } else if(scoreType == ImpactCalculationConstants.ImpactScoreType.IncidentNetScore) { // Case Object

            //TODO: Mohan said he will fix this when he has time.

        } else if(scoreType == ImpactCalculationConstants.ImpactScoreType.GainsightNetScore) {  //Customer Info Gainsight
            this.query = 'SELECT Id,JBCXM__Account__c,JBCXM__CurScoreId__c,JBCXM__CurScoreId__r.JBCXM__Score__c, '
                    + 'JBCXM__ASV__c,JBCXM_CreatedCases__c,JBCXM_OpenCases__c,JBCXM_Credits__c, JBCXM_MTTR__c '
                    + 'FROM JBCXM__CustomerInfo__c WHERE JBCXM__Account__r.RecordType.Name in :recordTypes';
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }


    global void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        if(scope[0] instanceof Account){
            ImpactCalculationService service = new ImpactCalculationService(new AccountImpactCalculationImpl());
            service.CalculateAccountNetScore(scope);
        } else if(scope[0] instanceof Case) {
            ImpactCalculationService service = new ImpactCalculationService(new IncidentImpactCalculationImplementation());
            service.CalculateIncidentNetScore(scope);
        } else if (scope[0] instanceof JBCXM__CustomerInfo__c){
            ImpactCalculationService service = new ImpactCalculationService(new GainsightImpactCalculationImpl());
            service.CalculateGainsightNetScore(scope);
        }

        this.batchSizeRecordCount += scope.size();
    }

    global void finish(Database.BatchableContext BC) {
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
        mail.setSubject(scoreType + ' Calculation Batch  ' + a.Status);
        mail.setPlainTextBody('The batch Apex job processed '
                + a.TotalJobItems
                + ' batches with '
                + a.NumberOfErrors
                + ' failures.' + '\n\n'
                + 'The batch Apex job processed ' + this.batchSizeRecordCount + ' accounts.');
        try{

        } catch(System.EmailException ex){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    mail
            });
        }
    }
}
