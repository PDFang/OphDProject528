trigger FeedCommentTrigger on FeedComment (after insert, before insert, before update, after update, after delete, after undelete) 
{
	new FeedCommentTriggerHandler().run();
}