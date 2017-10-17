/**
 * Created by arnab.karsarkar on 6/16/2017.
 */

trigger SubscriptionReplicaTrigger on SubscriptionReplica__c (after insert, after update) {
    new SubscriptionReplicaTriggerHandler().run();
}