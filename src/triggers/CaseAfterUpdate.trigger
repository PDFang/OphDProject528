trigger CaseAfterUpdate on Case (after update) 
{
	if(TriggerHandler.isBypassed('CaseTriggerHandler')){
		system.debug('By passed CaseAfterUpdate trigger');
		return;
	}
	Schema.DescribeSObjectResult d = Schema.SObjectType.Case; 
	Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
	
	//Get Order management record type id
	Id reBillRecType = rtMapByName.get('Re-Bill Request').getRecordTypeId();
	Id contractAuditRecordType = rtMapByName.get('Contract Billing Audit').getRecordTypeId();
	Id knownIssueRecordType = rtMapByName.get('Known Issue').getRecordTypeId();
	
	List<Approval.ProcessSubmitRequest> reqList = new List<Approval.ProcessSubmitRequest>();
	Set<Id> eventManagerChange = new Set<Id>();
    List<Task> tasks = new List<Task>();
	List<CaseComment> ccs = new List<CaseComment>();
	List<Case> cases = new List<Case>();
    Set<String> closedStatuses = CaseAssignmentClass.GetClosedStatuses();
    Set<ID> reOpenedCases = new Set<Id>();
    Set<Id> closedKnownIssues = new Set<id>();
    
		
	for(integer i=0;i<trigger.new.size();i++)
	{
		Case oldRec = trigger.old[i];
		Case newRec = trigger.new[i];
		
		
        //submit contract audits for approval
        if(!closedStatuses.contains(oldRec.Status) && closedStatuses.contains(newRec.Status) && newRec.RecordTypeId == contractAuditRecordType)
        {
        	// Create an approval request for the account
	        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
	        req1.setComments('Submitting Contract Audit for approval.');
	        req1.setObjectId(newRec.id);
	        
	        // Submit the approval request for the account
	        Approval.ProcessResult result = Approval.process(req1);
        }
        
        //get closed known issues
        if(!closedStatuses.contains(oldRec.Status) && closedStatuses.contains(newRec.Status) && newRec.RecordTypeId == knownIssueRecordType)
        {
			closedKnownIssues.add(newRec.Id);
        }
		
		if(oldRec.EventCommander__c != newRec.EventCommander__c)
		{
			eventManagerChange.add(newRec.Id);
		}
		
		if(newRec.RecordTypeId == reBillRecType)
		{
			if(oldRec.Status <> 'Request Review' && newRec.Status == 'Request Review')
			{
				Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        		req1.setComments('Submitting request for approval.');
        		req1.setObjectId(newRec.id);
        		
        		reqList.add(req1);
        		
			}
			
		}
		
		if(newRec.WorkDuration__c > 0 || newRec.PublicComment__c != NULL)
		{
			Case c = newRec.Clone(true);
			c.WorkDuration__c = NULL;
			c.PublicComment__c = NULL;
			cases.add(c);
		}
		
		//check for work duration and public comment
        if(newRec.WorkDuration__c > 0)
		{
			Task t = new Task();
            t.ActivityDate = date.today();
            t.WhatId = newRec.Id;
            t.WorkDuration__c = newRec.WorkDuration__c;
            t.Subject = 'Log Time on Case ' + String.valueof(newRec.CaseNumber);
            t.Status = 'Completed';
            t.Type = 'Time Tracking';
			
			tasks.add(t);
		}
		
		if(newRec.PublicComment__c != NULL)
		{
			CaseComment cc = new CaseComment();
			cc.CommentBody = newRec.PublicComment__c;
			cc.ParentId = newRec.Id;
			cc.IsPublished = true;
			
			ccs.add(cc);
		}
		
		
        //remove resolved date
        if((newRec.Status != 'Resolved' && !closedStatuses.contains(newRec.Status) && oldRec.ResolvedDate__c != NULL))
        {
        	reOpenedCases.add(newRec.Id);
        }
        
        
        if(oldRec.KnownIssue__c != NULL && newRec.KnownIssue__c == NULL)
        {
		    //set default assignment rule     
		    Case reassignCase = newRec.clone(true);
		      
	        database.DMLOptions dmo = new database.DMLOptions();
	        dmo.assignmentRuleHeader.useDefaultRule = true;
	        
	        reassignCase.setOptions(dmo);
	        cases.add(reassignCase);
        }
		
	}
	
	if(!reqList.isEmpty())
	{
		List<Approval.ProcessResult> result = Approval.process(reqList);
	}
	
	//create case comments
	if(!cases.isEmpty())
	{
		update cases;
	}
	
	//create tasks
	if(!tasks.isEmpty())
	{
		insert tasks;
	}
	
	//create case comments
	if(!ccs.isEmpty())
	{
		insert ccs;
	}
	
	if(!eventManagerChange.isEmpty())
	{
		List<RCA__c> rcaUpdates = new List<RCA__c>();
		
		for(RCA__c rca:[SELECT Id, EventCommander__c, Event__r.EventCommander__c FROM RCA__c WHERE Event__c IN :eventManagerChange])
		{
			rca.EventCommander__c = rca.Event__r.EventCommander__c;
			
			rcaUpdates.add(rca);
		}
		
		update rcaUpdates;
	}
	
	
    if(!reOpenedCases.isEmpty() && !System.isFuture())
    {
    	CaseAssignmentClass.ReopenSlaMilestone(reOpenedCases);
    }
	
    if(!closedKnownIssues.isEmpty())
    {
        CaseAssignmentClass.KnowIssueClosed(closedKnownIssues);
    }
	
}