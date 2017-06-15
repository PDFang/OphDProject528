/**
 * Created by william.nelson on 6/15/2017.
 */

public with sharing class PSProjectAssetAttachment {

    public static void AttachAssetsByIdToParentProject (list<id> QouteLineid, list<id>AssetsId, List<id> SubscriptionsId ){
        //should pass in ids of duplicate assets

        Set<id> OpportunityIds = new Set<id>();
        if (AssetsId.size() > 0){
            Map<id,List<Asset>> OpportunityMap = new Map<id,List<Asset>>();
            for ( SBQQ__QuoteLine__c qouteLine : [select SBQQ__Quote__r.SBQQ__Opportunity2__c, (select id from SBQQ__Assets__r where id in : AssetsId) from SBQQ__QuoteLine__c where id in : QouteLineid])
            {
                if(!OpportunityMap.containsKey(qouteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c)){
                    OpportunityMap.put(qouteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c, qouteLine.SBQQ__Assets__r);
                }
            }
        }
        else
        {
            //Map<id,List<SubscriptionReplica__c>> OpportunityMap = new Map<id,List<SubscriptionReplica__c>>();
            //for ( SBQQ__QuoteLine__c qouteLine : [select SBQQ__Quote__r.SBQQ__Opportunity2__c, (select id from SBQQ__Subscriptions__r where id in : SubscriptionsId ) from SBQQ__QuoteLine__c where id in : QouteLineid])
            //{
            //    if(!OpportunityMap.containsKey(qouteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c)){
            //        OpportunityMap.put(qouteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c, qouteLine.SBQQ__Subscriptions__r);
            //    }
            //}



        }





    }


}