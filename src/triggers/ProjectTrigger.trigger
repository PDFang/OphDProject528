trigger ProjectTrigger on Project__c(before update, before insert, after insert, after update, after delete)
{

	new ProjectTriggerHandler().run();

}