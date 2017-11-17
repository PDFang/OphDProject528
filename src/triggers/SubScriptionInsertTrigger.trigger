/**
 * Created by arnab.karsarkar on 4/17/2017.
 */

trigger SubScriptionInsertTrigger on SBQQ__Subscription__c (before update, after insert, after update) {
new SubscriptionTriggerHandler().run();
}