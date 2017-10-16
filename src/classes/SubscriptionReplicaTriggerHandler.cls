/**
 * Created by arnab.karsarkar on 6/16/2017.
 */

public with sharing class SubscriptionReplicaTriggerHandler extends TriggerHandler {
    public static Boolean InSubscriptionTrigger = false;

    public override void afterInsert()
    {
        AttachParentProject();
    }

    public override void afterUpdate(){
        SubscriptionTriggerHandler.InSubscriptionCustomTrigger = true;
        if (InSubscriptionTrigger == false)
        {
            UpdateSubscription((Map<Id, SubscriptionReplica__c>) trigger.oldMap);
        }
    }

    public static void AttachParentProject(){
        Set<Id> subscriptionIds = new Set<Id>();
        Set<Id> quoteLineIds = new Set<Id>();
        List<SubscriptionReplica__c> newList = (List<SubscriptionReplica__c>)( trigger.new );
        for(SubscriptionReplica__c newSubscriptionReplica : newList){
            if(newSubscriptionReplica.QuoteLineLookup__c != null){
                quoteLineIds.add(newSubscriptionReplica.QuoteLineLookup__c);
                subscriptionIds.add(newSubscriptionReplica.Id);
            }
        }
        if(quoteLineIds.size() > 0){
            PSProjectAssetAttachment.AttachAssetsByIdToParentProject(quoteLineIds, new set<Id>(), subscriptionIds);
        }
    }

    @TestVisible
    private static void UpdateSubscription(Map<Id, SubscriptionReplica__c> subscriptionReplicas) {
        //update the subscription table
        //Install Date
        //ProductImplemented
        //Status
    }

}