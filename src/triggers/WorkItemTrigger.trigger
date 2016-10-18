trigger WorkItemTrigger on ISTFSWorkItem__c (after insert, after update) {
 new WorkItemTriggerHandler().run();
}