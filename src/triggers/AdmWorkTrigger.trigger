/**
 * Created by jeremy.sparrell on 1/4/2018.
 */

trigger AdmWorkTrigger on agf__ADM_Work__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new AdmWorkTriggerHandler().run();

}