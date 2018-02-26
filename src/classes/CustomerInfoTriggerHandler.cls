
public class CustomerInfoTriggerHandler extends TriggerHandler {

    protected override void afterInsert(){
        CalculateGainsightNetScore((List<JBCXM__CustomerInfo__c>) trigger.new, (Map<Id, JBCXM__CustomerInfo__c>) trigger.oldMap);
    }

    protected override void afterUpdate(){
        CalculateGainsightNetScore((List<JBCXM__CustomerInfo__c>) trigger.new, (Map<Id, JBCXM__CustomerInfo__c>) trigger.oldMap);
    }

    private void CalculateGainsightNetScore(List<JBCXM__CustomerInfo__c> newList, Map<Id, JBCXM__CustomerInfo__c> oldMap) {

        Set<Id> custInfoIdSet = new Set<Id>();
        for(JBCXM__CustomerInfo__c newRecord : newList){
            JBCXM__CustomerInfo__c oldRecord = (oldMap != null) ? oldMap.get(newRecord.Id) : null;
            // Is new record or dependent fields updated
            if(oldRecord == null || recalculateScore(newRecord, oldRecord)){
                custInfoIdSet.add(newRecord.Id);
            }
        }
        system.debug('CalculateGainsightNetScore(): custInfoIdSet - ' + custInfoIdSet);

        if(custInfoIdSet.size() > 0 && !system.isFuture() && !system.isBatch()){
            system.debug('CalculateGainsightNetScore(): Calling CalculateGainsightNetScoreFuture');
            CalculateGainsightNetScoreFuture(custInfoIdSet);
        }
    }

    private boolean recalculateScore(JBCXM__CustomerInfo__c newRecord, JBCXM__CustomerInfo__c oldRecord){
        return newRecord.JBCXM__CurScoreId__c != oldRecord.JBCXM__CurScoreId__c
                || newRecord.JBCXM__MRR__c != oldRecord.JBCXM__MRR__c
                || newRecord.JBCXM_Credits__c != oldRecord.JBCXM_Credits__c;
    }

    @Future
    private static void CalculateGainsightNetScoreFuture(Set<Id> custInfoIdSet){

        List<JBCXM__CustomerInfo__c> custInfoList = new List<JBCXM__CustomerInfo__c>();
        for(JBCXM__CustomerInfo__c custInfo : [
                SELECT Id, JBCXM__Account__c, JBCXM__Account__r.Gainsight_Net_Score__c,
                        JBCXM__CurScoreId__c, JBCXM__CurScoreId__r.JBCXM__Score__c,
                        JBCXM__ASV__c, JBCXM_CreatedCases__c, JBCXM_OpenCases__c, JBCXM_Credits__c,
                        JBCXM_MTTR_IN_Weeks__c, JBCXM_MTTR_IN_Hours__c, JBCXM__MRR__c
                FROM JBCXM__CustomerInfo__c
                where Id IN :custInfoIdSet
        ]){
            custInfoList.add(custInfo);
        }

        system.debug('CalculateGainsightNetScoreFuture(): custInfoList - ' + custInfoList);

        if(custInfoList.size() > 0){
            ImpactCalculationService calculationService = new ImpactCalculationService(new GainsightImpactCalculationImpl());
            calculationService.CalculateGainsightNetScore(custInfoList);
        }

    }

}