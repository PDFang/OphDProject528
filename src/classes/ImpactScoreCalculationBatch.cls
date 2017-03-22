global class ImpactScoreCalculationBatch implements Database.Batchable<Sobject>, Database.Stateful{

    private string query;

    public ImpactScoreCalculationBatch(ImpactCalculationConstants.ImpactScoreType objectType){

        if (objectType == ImpactCalculationConstants.ImpactScoreType.AccountNetScore) { // Account object
            this.query = 'Select Id, Social_Media_Presence__c, CustomerSegment__c, Brand_Visibility__c, '
                    + 'Industry_Leadership_Vocality__c, Risk_of_Leaving__c, GYRStatus__c, '
                    + 'Age_of_Customer_in_Months__c, IsPartner__c, Referenceable__c '
                    + 'from Account where RecordType.Name IN :ImpactCalculationConstants.recordTypes';

        } else if(objectType == ImpactCalculationConstants.ImpactScoreType.IncidentNetScore) { // Case Object

        } else if(objectType == ImpactCalculationConstants.ImpactScoreType.GainsightNetScore) {  //Customer Info Gainsight
            this.query = 'SELECT Id,JBCXM__Account__c,JBCXM__CurScoreId__c,JBCXM__CurScoreId__r.JBCXM__Score__c, '
                    + 'JBCXM__ASV__c,JBCXM_CreatedCases__c,JBCXM_OpenCases__c,JBCXM_Credits__c, JBCXM_MTTR__c '
                    + 'FROM JBCXM__CustomerInfo__c';
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
    }

    global void finish(Database.BatchableContext BC) {

    }
}
