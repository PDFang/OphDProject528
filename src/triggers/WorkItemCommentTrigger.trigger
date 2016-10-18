trigger WorkItemCommentTrigger on ISTFSWorkItemComment__c (after insert, after update, before delete) {
 new WorkItemCommentTrggerHandler().run();
}