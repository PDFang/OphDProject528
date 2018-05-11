trigger CaseEmailTrigger on EmailMessage (after insert) 
{
	new CaseEmailTriggerHandler().run();
	
}