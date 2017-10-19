/**
 * Created by arnab.karsarkar on 6/16/2017.
 */

trigger SubscriptionReplicaTrigger on SubscriptionReplica__c (before update, after insert, after update) {
    new SubscriptionReplicaTriggerHandler().run();
}