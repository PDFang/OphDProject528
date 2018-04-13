/**
 * Created by jeremy.sparrell on 1/30/2018.
 */

trigger ProjectAssetAllocationTrigger on Project_Asset_Allocation__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new ProjectAssetAllocationTriggerHandler().run();
}