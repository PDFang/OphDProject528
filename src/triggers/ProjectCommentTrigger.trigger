trigger ProjectCommentTrigger on ProjectComment__c (after insert, after update, before delete) {
 new WorkItemCommentTrggerHandler().run();
}