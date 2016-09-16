trigger actionHub_Attachment on Attachment bulk (after insert) {
	
	//For Case to Incident integration, there are no actionHub rules for Attachments.
	//This block is left just in case some other integration needs to invoke actionHub
	if(!system.isFuture())    
	{
		String source = 'Cloudaction Dev 3';
		CloudactionInt.EventHandler handler = new CloudactionInt.EventHandler();        
		handler.objectSaveEvent(trigger.old, trigger.new, source);    
	}
	
	//For Case <> Incident integration, attachments are handled in custom code 
	//to remove actionHub's overhead, allowing larger attachments.
	//This should be used for any internal integration where attachments
	//will be shared by multiple Salesforce objects.
	Ca_Case_Incident_Sync.executeTrigger(trigger.new);
}