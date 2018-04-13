/**
 * Created by arnab.karsarkar on 6/16/2017.
 */

public with sharing class SubscriptionReplicaTriggerHandler extends TriggerHandler {
    public static Boolean InSubscriptionTrigger = false;

    public override void beforeUpdate()
    {
        //UpdateSubscriptionReplicaFromProjectPhase();
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

    /*/ Get associated Project Phase information and update to SubscriptionReplica
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
    */
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


    // Update Subscription and associated Implemented Product
    private static void UpdateSubscription(List<SubscriptionReplica__c> lstSubscriptionReplicas, Map<Id, SubscriptionReplica__c> oldMap) {

        list<SBQQ__Subscription__c> lstUpdateSubscriptions = new list<SBQQ__Subscription__c>();
        list<ImplementedProduct__c> lstUpdateImplementedProducts = new list<ImplementedProduct__c>();
        Map<Id, Date> ImplementationProductDates  = new Map<Id, Date>();
	    set<id> subscriptionIds = new set<Id>();
        //update certain fields in Subscription table
        for ( SubscriptionReplica__c subscriptionReplica : lstSubscriptionReplicas) {

            SubscriptionReplica__c oldSubscriptionReplica = new SubscriptionReplica__c();
            if(oldMap != null){
                oldSubscriptionReplica = oldMap.get(subscriptionReplica.Id);
            }
            if (oldSubscriptionReplica != null)
            {

                if(!subscriptionIds.contains(subscriptionReplica.Subscription__c)){
                    SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(Id = subscriptionReplica.Subscription__c);
                    subscription.Total_Allocated_Quantity__c = subscriptionReplica.Total_Allocated_Quantity__c;
                    subscription.Total_Implemented_Quantity__c = subscriptionReplica.Total_Implemented_Quantity__c;
                    subscription.Logged_Hours__c = subscriptionReplica.Logged_Hours__c;
                    subscription.Allocated_Hours__c = subscriptionReplica.Total_Allocated_Hours__c;

                    // add changed Subscriptions to update list
                    lstUpdateSubscriptions.add(subscription);

                    // do not update back to subscription table if it ever set to '4 - Delivered'
                    if (oldSubscriptionReplica.Delivered__c != true) {

                        subscription.Status__c = subscriptionReplica.Status1__c;
                        subscription.Install_Date__c = subscriptionReplica.Install_Date__c;
                        subscription.Implemented_Product__c = subscriptionReplica.Implemented_Product__c;

                    }
                    subscriptionIds.add(subscriptionReplica.Subscription__c);
                }

            }
        }

        if(lstUpdateSubscriptions.size() > 0){
            update lstUpdateSubscriptions;
        }

        //if(lstUpdateImplementedProducts.size() > 0){
        //    update lstUpdateImplementedProducts;
        //}
    }

}