trigger actionHub_CaseComment on CaseComment bulk (after insert,after update) 
{
	if(!system.isFuture())
    {
        System.Debug('************** actionHub_CaseComment on CaseComment - System.IsFuture() is not true. Executing.');
	    Ca_Case_Incident_Sync.CaseComment_executeTrigger(trigger.new);
    }
}