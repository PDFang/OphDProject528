/**
 * Created by arnab.karsarkar on 9/14/2017.
 */

trigger EDAAfterInsertTrigger on EDA__c (after insert) {
 new EDATriggerHandler().run();
}