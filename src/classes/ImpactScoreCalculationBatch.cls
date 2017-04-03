global class ImpactScoreCalculationBatch implements Database.Batchable<Sobject>, Database.Stateful{

    public string query;
    private string recordType;
    private ImpactCalculationConstants.ImpactScoreType scoreType;
    private integer recordCount = 0;

    Set<String> accountRecordTypes = ImpactCalculationConstants.recordTypes;

    public ImpactScoreCalculationBatch(ImpactCalculationConstants.ImpactScoreType scoreType){

        this.scoreType = scoreType;
        if (scoreType == ImpactCalculationConstants.ImpactScoreType.AccountNetScore) { // Account object
            this.query = 'Select Id, Social_Media_Presence__c, CustomerSegment__c, Brand_Visibility__c, '
                    + 'Industry_Leadership_Vocality__c, Risk_of_Leaving__c, GYRStatus__c, '
                    + 'Age_of_Customer_in_Months__c, IsPartner__c, Referenceable__c, Account_Net_Score__c '
                    + 'from Account where RecordType.Name IN :accountRecordTypes';

        } else if(scoreType == ImpactCalculationConstants.ImpactScoreType.IncidentNetScore) { // Case Object
            this.query = 'Select Id, Severity__c, Business_Impacted__c, Quality_of_Workaround__c, '
                    + 'Related_to_Previous_Known_Issue__c, Security_Issue__c, Workaround_Available__c '
                    + 'From Case '
                    + 'Where RecordType.Name = \'Incident\' and (Status = \'Assigned to Known Issue\''
                    + 'OR IsClosed = false)';

        } else if(scoreType == ImpactCalculationConstants.ImpactScoreType.GainsightNetScore) {  //Customer Info Gainsight
            this.query = 'SELECT Id, JBCXM__Account__c, JBCXM__Account__r.Gainsight_Net_Score__c, JBCXM__CurScoreId__c, JBCXM__CurScoreId__r.JBCXM__Score__c, '
                    + 'JBCXM__ASV__c, JBCXM_CreatedCases__c, JBCXM_OpenCases__c, JBCXM_Credits__c, '
                    + 'JBCXM_MTTR_IN_Weeks__c, JBCXM_MTTR_IN_Hours__c '
                    + 'FROM JBCXM__CustomerInfo__c '
                    + 'WHERE JBCXM__Account__r.RecordType.Name in :accountRecordTypes';
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }


    global void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        try{
            recordType = scope[0].getSObjectType().getDescribe().getName();
            system.debug('execute(): recordType - ' + recordType);
            if(scope[0] instanceof Account){
                ImpactCalculationService service = new ImpactCalculationService(new AccountImpactCalculationImpl());
                TriggerHandler.bypass('AccountTriggerHandler');
                service.CalculateAccountNetScore(scope);
            } else if(scope[0] instanceof Case) {
                ImpactCalculationService service = new ImpactCalculationService(new IncidentImpactCalculationImplementation());
                service.CalculateIncidentNetScore(scope);
                TriggerHandler.bypass('CaseTriggerHandler');
                Database.SaveResult[] saveResults = Database.update(scope, false);
                for(Database.SaveResult result :saveResults){
                    if(result.isSuccess() == false){
                        system.debug('execute(): error - '+ result.getErrors()[0]);
                        sendErrorEmail(result.getErrors()[0].getMessage(), result.getId());
                    }
                }
            } else if (scope[0] instanceof JBCXM__CustomerInfo__c){
                ImpactCalculationService service = new ImpactCalculationService(new GainsightImpactCalculationImpl());
                TriggerHandler.bypass('CustomerInfoTriggerHandler');
                service.CalculateGainsightNetScore(scope);
            }
            this.recordCount += scope.size();
        } catch(Exception ex){
            system.debug('execute(): Exception - ' + ex);
            SendErrorEmail(ex, recordType);
        } finally{
            TriggerHandler.clearAllBypasses();
        }


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
                + 'The batch Apex job processed ' + this.recordCount + ' ' + recordType + '.');
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    mail
            });
        } catch(System.EmailException ex){
            system.debug('finish() EmailException - ' + ex);
        }
    }

    private void sendErrorEmail(Exception ex, String recordType){
        try{
            inContactBaseClass.SendErrorEmail(ex, recordType);
        } catch(System.EmailException emailEx){
            system.debug('sendErrorEmail() EmailException - ' + emailEx);
        }
    }

    private void sendErrorEmail(String errorMessage, String recordId){
        try{
            inContactBaseClass.SendErrorEmail(errorMessage, recordId);
        } catch(System.EmailException emailEx){
            system.debug('sendErrorEmail() EmailException - ' + emailEx);
        }
    }

}
