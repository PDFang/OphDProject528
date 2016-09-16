trigger RCABeforeInsert on RCA__c (before insert, before update) 
{
	
	Map<ID,ID> caseCommanders = new Map<Id,ID>();
	Set<ID> caseIds = new Set<ID>();
	
	
	
	if(trigger.isInsert)
	{
		
		//get a list of case Ids.
		for(RCA__c rca:trigger.new)
		{
			caseIds.add(rca.Event__c);
		}
		
		if([SELECT COUNT() FROM RCA__c WHERE Event__c IN :caseIds] > 0)
		{
			trigger.new[0].addError('This event already has an RCA. Only one RCA can be created per event.');
		}
		
		//populate map with case info
		Map<ID,Case> cases = new Map<ID,Case>([SELECT ID, EventCommander__c FROM Case WHERE ID IN :caseIds]);
		
		
		//get event commander and assign
		for(RCA__c rca:trigger.new)
		{
			if(cases.get(rca.Event__c).EventCommander__c != NULL)
			{
				rca.OwnerId = cases.get(rca.Event__c).EventCommander__c;
				rca.EventCommander__c = rca.OwnerId;
			}
			else
			{
				rca.addError('The Event must have an Event Manager before an RCA can be created.');
			}
		}
	}
	
	if(trigger.isUpdate)
	{
		for(integer i=0;i < trigger.size;i++)
		{
			RCA__c newRCA = trigger.new[i];
			RCA__c oldRCA = trigger.old[i];
			
			if(oldRCA.Status__c != 'Event Summary Completed' && oldRCA.Status__c != 'RFE Draft Complete' && newRCA.Status__c == 'Event Summary Completed')
			{
				newRCA.OwnerId = newRCA.CustomerAdvocate__c;
				newRCA.EventSummaryCompleted__c = true;
				newRCA.EventSummaryDateTime__c = system.now();
			}
		
		}
	}
}