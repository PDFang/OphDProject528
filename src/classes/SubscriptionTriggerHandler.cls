/**
 * Created by arnab.karsarkar on 4/17/2017.
 */

public class SubscriptionTriggerHandler extends TriggerHandler{

    public static Boolean InSubscriptionCustomTrigger = false;
    private static Id subscriptionRollupQueueableJobID;

    public override void beforeUpdate()
    {
        UpdateSubscriptionFromProjectPhase();
    }

    public override void afterInsert(){
        InsertSubscriptionReplica((List<SBQQ__Subscription__c>) trigger.new);
        rollupMRRToPhaseProject();
    }

    public override void afterUpdate(){
        SubscriptionReplicaTriggerHandler.InSubscriptionTrigger = true;
        if (InSubscriptionCustomTrigger == false)
        {
            UpdateSubscriptionReplica((Map<Id, SBQQ__Subscription__c>) trigger.newMap, (Map<Id, SBQQ__Subscription__c>)trigger.oldMap);
        }
        rollupMRRToPhaseProject();
    }

    protected override void afterDelete(){
        rollupMRRToPhaseProject();
    }

    // roll-up subscription MRR's to related phase project
    private static void rollupMRRToPhaseProject() {

        system.debug('**** started rollupMRRToPhaseProject() ');

        List<SBQQ__Subscription__c> newList = (List<SBQQ__Subscription__c>) (trigger.isDelete ? trigger.old : trigger.new);

        Map<Id, SBQQ__Subscription__c> oldMap = (Map<Id, SBQQ__Subscription__c>) trigger.oldMap;

        Set<Id> phaseProjectIdSet = new Set<Id>();

        for (SBQQ__Subscription__c newSubscription : newList) {

            SBQQ__Subscription__c oldSubscription = oldMap != null ? oldMap.get(newSubscription.Id) : null;

            if (trigger.isInsert && newSubscription.Project_Phase__c != null){
                system.debug('**** rollupMRRToPhaseProject(): created subscription ');
                phaseProjectIdSet.add(newSubscription.Project_Phase__c);
            } else if (trigger.isUpdate){
                system.debug('**** rollupMRRToPhaseProject(): updated subscription ');
                phaseProjectIdSet.add(newSubscription.Project_Phase__c);
                if (newSubscription.Project_Phase__c != oldSubscription.Project_Phase__c) {
                    phaseProjectIdSet.add(oldSubscription.Project_Phase__c);
                }
            } else if (trigger.isDelete) {
                system.debug('**** rollupMRRToPhaseProject(): deleted subscription ');
                phaseProjectIdSet.add(newSubscription.Project_Phase__c);
            }

        }

        phaseProjectIdSet.remove(null);

        system.debug('**** rollupMRRToPhaseProject(): phaseProjectIdSet - ' + phaseProjectIdSet);

        if(phaseProjectIdSet.size() > 0 && subscriptionRollupQueueableJobID == null){
            subscriptionRollupQueueableJobID = System.enqueueJob(new SubscriptionRollupQueueable(phaseProjectIdSet));
            system.debug('**** rollupMRRToPhaseProject(): subscriptionRollupQueueableJobID - ' + subscriptionRollupQueueableJobID);
        }

    }

    // Get associated Project Phase information and update to Subscription
    public static void UpdateSubscriptionFromProjectPhase(){

        Set<String> subscriptionIds = new Set<String>();
        List<SBQQ__Subscription__c> newSubscriptions = (List<SBQQ__Subscription__c>)( trigger.new );
        Map<Id, SBQQ__Subscription__c> oldMap  = (Map<Id, SBQQ__Subscription__c>) ( trigger.oldMap );
        Map<Id, Date> projectPhaseDates  = new Map<Id, Date>();


        for(SBQQ__Subscription__c subscription : newSubscriptions)
        {
            subscriptionIds.add(subscription.Id);
        }

        // collect Project Phase information from Subscription table
        for(SBQQ__Subscription__c subscription : [
                SELECT Id, Project_Phase__r.ActualProjectGoLiveDate__c FROM SBQQ__Subscription__c
                WHERE Id IN : subscriptionIds
        ]){
            if(!projectPhaseDates.containsKey(subscription.Id))
            {
                projectPhaseDates.put(subscription.Id, subscription.Project_Phase__r.ActualProjectGoLiveDate__c);
            }
        }

        for(SBQQ__Subscription__c newSubscription : newSubscriptions)
        {
            SBQQ__Subscription__c oldSubscription = (oldMap != null) ? oldMap.get(newSubscription.Id) : null;
            if (oldSubscription != null)
            {
                // only update if status has set to '4 - Delivered'
                if(newSubscription.Status__c == '4 - Delivered' && oldSubscription.Status__c != '4 - Delivered'){

                    Date goLiveDate = projectPhaseDates.get(newSubscription.Id);
                    newSubscription.Install_Date__c = goLiveDate; //goLiveDate ;
                }
            }
        }
    }


    private static boolean throwExceptionBollean = false;

    @TestVisible
    private static void InsertSubscriptionReplica(list<SBQQ__Subscription__c> lstSubscriptions){

        try{
            List<SubscriptionReplica__c> lstSubscriptionReplicas = new list<SubscriptionReplica__c>();
            for(SBQQ__Subscription__c subscription : lstSubscriptions){
                SubscriptionReplica__c newReplica = new SubscriptionReplica__c();
                newReplica.Subscription__c = subscription.Id;
                newReplica.AccountLookup__c = subscription.SBQQ__Account__c;
                newReplica.QuoteLineLookup__c = subscription.SBQQ__QuoteLine__c;
                newReplica.Implemented_Product__c = subscription.Implemented_Product__c;
                newReplica.Status1__c = subscription.Status__c;
                lstSubscriptionReplicas.add(newReplica);
            }

            insert lstSubscriptionReplicas;

        }Catch(Exception ex){
            for(SBQQ__Subscription__c subscription : lstSubscriptions)
            {
                subscription.addError('Insert Failed. An Error Occured during creation of Subscription Replica object -' + ex.getMessage());
            }
        }
    }


    private static void UpdateSubscriptionReplica(Map<Id, SBQQ__Subscription__c> lstSubscriptions, Map<Id, SBQQ__Subscription__c> oldMap) {

        list<SubscriptionReplica__c> lstUpdateSubscriptionReplicas = new list<SubscriptionReplica__c>();
        list<ImplementedProduct__c> lstUpdateImplementedProducts = new list<ImplementedProduct__c>();
        Map<Id, Date> ImplementationProductDates  = new Map<Id, Date>();
        boolean isUpdate;

        //update certain fields to SubscriptionReplica table since they are not formula fields there
        for(SubscriptionReplica__c subscriptionReplica : [
                SELECT Id, Status1__c, Install_Date__c, Implemented_Product__c, Subscription__c FROM subscriptionReplica__c
                WHERE Subscription__c IN : lstSubscriptions.keyset()
        ]){
            isUpdate = false;
            SBQQ__Subscription__c subscription = lstSubscriptions.get(SubscriptionReplica.Subscription__c);
            SBQQ__Subscription__c oldSubscription = (oldMap != null) ? oldMap.get(SubscriptionReplica.Subscription__c) : null;
            if (subscriptionReplica.Status1__c != subscription.Status__c
                    || subscriptionReplica.Install_Date__c != subscription.Install_Date__c
                    || subscriptionReplica.Implemented_Product__c != subscription.Implemented_Product__c) {
                isUpdate = true;
            }

            subscriptionReplica.Status1__c = subscription.Status__c;
            subscriptionReplica.Install_Date__c = subscription.Install_Date__c;
            subscriptionReplica.Implemented_Product__c = subscription.Implemented_Product__c;

            // add changed SubscriptionReplica to update list
            if (isUpdate) {
                lstUpdateSubscriptionReplicas.add(subscriptionReplica);

                // only update implemented product when first time the subscription status set to '4 - Delivered'
                if (subscription.Implemented_Product__c != null && subscription.Install_Date__c != null) {
                    if (subscription.Status__c == '4 - Delivered' && oldSubscription.Status__c != '4 - Delivered') {
                        if (!ImplementationProductDates.containsKey(subscription.Implemented_Product__c)) {
                            ImplementationProductDates.put(subscription.Implemented_Product__c, subscription.Install_Date__c);
                        }
                    }
                }

            }

            // update implemenation product
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

        if(lstUpdateSubscriptionReplicas.size() > 0){
            update lstUpdateSubscriptionReplicas;
        }

        if(lstUpdateImplementedProducts.size() > 0){
            update lstUpdateImplementedProducts;
        }
    }

    public class triggerException extends Exception{}

}