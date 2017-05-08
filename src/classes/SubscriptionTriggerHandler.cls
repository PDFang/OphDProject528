/**
 * Created by arnab.karsarkar on 4/17/2017.
 */

public class SubscriptionTriggerHandler extends TriggerHandler{
    public override void afterInsert(){
        InsertSubscriptionReplica((List<SBQQ__Subscription__c>)trigger.new);
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

    public class triggerException extends Exception{}

}