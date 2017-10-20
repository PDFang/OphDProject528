/**
 * Created by arnab.karsarkar on 6/16/2017.
 */

public with sharing class SubscriptionReplicaTriggerHandler extends TriggerHandler {
    public static Boolean InSubscriptionTrigger = false;

    public override void beforeUpdate()
    {
        UpdateSubscriptionReplicaFromProjectPhase();
    }

    public override void afterInsert()
    {
        AttachParentProject();
    }

    public override void afterUpdate(){
        SubscriptionTriggerHandler.InSubscriptionCustomTrigger = true;
        if (InSubscriptionTrigger == false)
        {
            UpdateSubscription((List<SubscriptionReplica__c>) trigger.new, (Map<Id, SubscriptionReplica__c>)trigger.oldMap);
        }
    }

    // Get associated Project Phase information and update to SubscriptionReplica
    public static void UpdateSubscriptionReplicaFromProjectPhase(){

        Set<String> subscriptionReplicaIds = new Set<String>();
        List<SubscriptionReplica__c> newSubscriptionReplicas = (List<SubscriptionReplica__c>)( trigger.new );
        Map<Id, SubscriptionReplica__c> oldMap  = (Map<Id, SubscriptionReplica__c>) ( trigger.oldMap );
        Map<Id, Date> projectPhaseDates  = new Map<Id, Date>();

        for(SubscriptionReplica__c subscriptionReplica : newSubscriptionReplicas)
        {
            subscriptionReplicaIds.add(subscriptionReplica.Subscription__c);
        }

        // collect Project Phase information from Subscription table
        for(SBQQ__Subscription__c subscription : [
                SELECT Id, Project_Phase__r.ActualProjectGoLiveDate__c FROM SBQQ__Subscription__c
                WHERE Id IN : subscriptionReplicaIds
        ]){
            if(!projectPhaseDates.containsKey(subscription.Id))
            {
                projectPhaseDates.put(subscription.Id, subscription.Project_Phase__r.ActualProjectGoLiveDate__c);
            }
        }

        for(SubscriptionReplica__c newSubscriptionReplica : newSubscriptionReplicas)
        {
            SubscriptionReplica__c oldSubscriptionReplica = (oldMap != null) ? oldMap.get(newSubscriptionReplica.Id) : null;
            if (oldSubscriptionReplica != null)
            {
                // only update if status has set to '4 - Delivered' once already
                if(newSubscriptionReplica.Status1__c == '4 - Delivered' && oldSubscriptionReplica.Delivered__c != true){

                    Date goLiveDate = projectPhaseDates.get(newSubscriptionReplica.Subscription__c);
                    newSubscriptionReplica.Install_Date__c = goLiveDate ;
                    newSubscriptionReplica.Delivered__c = true;
                }
            }
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
    // Update Subscription and associated Implemented Product
    private static void UpdateSubscription(List<SubscriptionReplica__c> lstSubscriptionReplicas, Map<Id, SubscriptionReplica__c> oldMap) {

        list<SBQQ__Subscription__c> lstUpdateSubscriptions = new list<SBQQ__Subscription__c>();
        list<ImplementedProduct__c> lstUpdateImplementedProducts = new list<ImplementedProduct__c>();
        Map<Id, Date> ImplementationProductDates  = new Map<Id, Date>();

        //update certain fields in Subscription table
        for ( SubscriptionReplica__c subscriptionReplica : lstSubscriptionReplicas) {

            SubscriptionReplica__c oldSubscriptionReplica = (oldMap != null) ? oldMap.get(subscriptionReplica.Id) : null;
            if (oldSubscriptionReplica != null)
            {
                // do not update back to subscription table if it ever set to '4 - Delivered'
                if (oldSubscriptionReplica.Delivered__c != true) {
                    SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(Id = subscriptionReplica.Subscription__c);
                    subscription.Status__c = subscriptionReplica.Status1__c;
                    subscription.Install_Date__c = subscriptionReplica.Install_Date__c;
                    subscription.Implemented_Product__c = subscriptionReplica.Implemented_Product__c;

                    // add changed Subscriptions to update list
                    lstUpdateSubscriptions.add(subscription);

                    // only update implemented product when first time the subscription status set to '4 - Delivered'
                    if (subscriptionReplica.Implemented_Product__c != null && subscriptionReplica.Install_Date__c != null) {
                        if (subscriptionReplica.Status1__c == '4 - Delivered' && oldSubscriptionReplica.Delivered__c != true) {
                            if (!ImplementationProductDates.containsKey(subscriptionReplica.Implemented_Product__c)) {
                                ImplementationProductDates.put(subscriptionReplica.Implemented_Product__c, subscriptionReplica.Install_Date__c);
                            }
                        }
                    }
                }
            }
        }

        //update certain fields in Implemented Product table
        for ( ImplementedProduct__c implementedProduct : [
                SELECT Id, Status__c, GoLiveDate__c FROM ImplementedProduct__c
                WHERE Id IN : ImplementationProductDates.keyset()
        ]){


            Date installDate = ImplementationProductDates.get(implementedProduct.Id);
            implementedProduct.GoLiveDate__c = installDate;
            implementedProduct.Status__c = 'Implemented';

            // add changed implementedProduct to update list
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