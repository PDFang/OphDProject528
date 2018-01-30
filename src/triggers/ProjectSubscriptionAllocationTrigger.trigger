/**
 * Created by jeremy.sparrell on 1/29/2018.
 */

trigger ProjectSubscriptionAllocationTrigger on Project_Subscription_Allocation__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new ProjSubscriptionAllocationTriggerHandler().run();
}