trigger TfsWorkItemTrigger on TfsWorkItem__c (after insert, before insert, before update, after update, after delete, after undelete) 
{
	new TfsWorkItemTriggerHandler().run();
}