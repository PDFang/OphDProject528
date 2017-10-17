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
            UpdateSubscription((List<SubscriptionReplica__c>) trigger.new);
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
    private static void UpdateSubscription(List<SubscriptionReplica__c> lstSubscriptionReplicas) {

        list<SBQQ__Subscription__c> lstUpdateSubscriptions = new list<SBQQ__Subscription__c>();
        list<ImplementedProduct__c> lstUpdateImplementedProducts = new list<ImplementedProduct__c>();

        Set<String> subscriptionReplicaIds = new Set<String>();
        Map<Id, Date> ImplementationProductIds  = new Map<Id, Date>();

        for ( SubscriptionReplica__c subscriptionReplica : lstSubscriptionReplicas)
        {
            subscriptionReplicaIds.add(subscriptionReplica.Id);
        }

        //update certain fields in Subscription table
        for ( SubscriptionReplica__c subscriptionReplica : [
                SELECT Id, Status__c, Install_Date__c, ImplementedProduct__c, Subscription__c FROM SubscriptionReplica__c
                WHERE Id IN : subscriptionReplicaIds]){
            system.debug('**** UpdateSubscription() : subscription__c - '+subscriptionReplica.Subscription__c);
            SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(Id = subscriptionReplica.Subscription__c);
            subscription.Status__c = subscriptionReplica.Status__c;
            subscription.Install_Date__c = subscriptionReplica.Install_Date__c;     // ?? assume Install date is set before I come here
            subscription.Implemented_Product__c = subscriptionReplica.ImplementedProduct__c;

            // add changed Subscriptions to update list
            lstUpdateSubscriptions.add(subscription);

            // collect Implemented Product information
            ImplementationProductIds.put(subscriptionReplica.ImplementedProduct__c, subscriptionReplica.Install_Date__c);
        }

        //update certain fields in Implemented Product table
        for ( ImplementedProduct__c implementedProduct : [
                SELECT Id, Status__c, GoLiveDate__c FROM ImplementedProduct__c
                WHERE Id IN : ImplementationProductIds.keyset()]){

            implementedProduct.Status__c = 'Implemented';
            implementedProduct.GoLiveDate__c = (Date)ImplementationProductIds.get(implementedProduct.Id);
            lstUpdateImplementedProducts.add(implementedProduct);
        }

        if(lstUpdateSubscriptions.size() > 0){
            update lstUpdateSubscriptions;
        }

        if(lstUpdateImplementedProducts.size() > 0){
            update lstUpdateImplementedProducts;
        }
    }

}