/**
 * Created by arnab.karsarkar on 4/17/2017.
 */

public class SubscriptionTriggerHandler extends TriggerHandler{
    public static Boolean InSubscriptionCustomTrigger = false;

    public override void afterInsert(){
        InsertSubscriptionReplica((List<SBQQ__Subscription__c>) trigger.new);
    }

    public override void afterUpdate(){
        SubscriptionReplicaTriggerHandler.InSubscriptionTrigger = true;
        if (InSubscriptionCustomTrigger == false)
        {
            UpdateSubscriptionReplica((Map<Id, SBQQ__Subscription__c>) trigger.newMap);
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

    @TestVisible
    private static void UpdateSubscriptionReplica(Map<Id, SBQQ__Subscription__c> lstSubscriptions) {

        list<SubscriptionReplica__c> lstUpdateSubscriptionReplicas = new list<SubscriptionReplica__c>();

        //update certain fields to SubscriptionReplica table since they are not formula fields there
        for(SubscriptionReplica__c subscriptionReplica : [
                SELECT Id, Status1__c, Install_Date__c, Implemented_Product__c, Subscription__c FROM subscriptionReplica__c
                WHERE Subscription__c IN : lstSubscriptions.keyset()
        ]){
            SBQQ__Subscription__c subscription = lstSubscriptions.get(SubscriptionReplica.Subscription__c);
            subscriptionReplica.Status1__c = subscription.Status__c;
            subscriptionReplica.Install_Date__c = subscription.Install_Date__c;
            subscriptionReplica.Implemented_Product__c = subscription.Implemented_Product__c;

            // add changed SubscriptionReplica to update list
            lstUpdateSubscriptionReplicas.add(subscriptionReplica);
        }

        if(lstUpdateSubscriptionReplicas.size() > 0){
            update lstUpdateSubscriptionReplicas;
        }
    }

    public class triggerException extends Exception{}

}