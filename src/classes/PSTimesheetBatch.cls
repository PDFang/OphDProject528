global class PSTimesheetBatch implements Database.Batchable<sObject>  
{
	global final String gstrQuery = 'SELECT Id, Name FROM User WHERE IsActive = true AND Id IN(SELECT UserOrGroupId FROM GroupMember WHERE Group.Name = \'PS Timesheets\')';

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
    	return Database.getQueryLocator(gstrQuery);
    }
 
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
    	date startDate = system.today().toStartOfWeek();
    	date endDate = startDate + 6;
    	
    	Set<ID> users = new Set<Id>();
    	Timesheet__c[] existing = new Timesheet__c[]{}; 
    	List<Timesheet__c> newTS = new List<Timesheet__c>();
    	List<TimesheetDay__c> tsDays = new List<TimesheetDay__c>();
    	
    	
    	for(SObject objSObject : scope)
       	{
      		User u = (User)objSObject;
      		users.add(u.Id);
       	}
       	
       	existing = [SELECT OwnerId FROM Timesheet__c WHERE OwnerId IN:users AND StartDate__c = :startDate];
    	
    	if(!existing.isEmpty())
    	{
	    	for(Timesheet__c ts:existing)
	    	{
	    		if(users.contains(ts.OwnerId))
	    		{
	    			users.remove(ts.OwnerId);
	    		}
	    	}
    	}
    	
    	if(!users.isEmpty())
    	{
    	
	    	for(ID u:users)
	    	{
	    		Timesheet__c ts = new Timesheet__c();
	    		ts.OwnerId = u;
	    		ts.StartDate__c = startDate;
	    		ts.EndDate__c = endDate;
	    		ts.Status__c = 'Open';
	    		
	    		newTS.add(ts);
	    		    		
	    	}
	    	
	    	insert newTS;
	    	
	    	
	    	for(Timesheet__c ts:newTS)
	    	{
		    	for(integer i=0;i<7;i++)
				{
					TimesheetDay__c td = new TimesheetDay__c();
					td.Timesheet__c = ts.Id;
					td.Date__c = startDate + i;
					
					tsDays.add(td);
				}
	    	}
	    	
	    	insert tsDays;
    	}
    }
    

    global void finish(Database.BatchableContext BC)
    {
	    AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
	    TotalJobItems, CreatedBy.Email
	    FROM AsyncApexJob WHERE Id =
	    :BC.getJobId()];
	   	// Send an email to the Apex job's submitter notifying of job completion. 
	    
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] {a.CreatedBy.Email};
		mail.setToAddresses(toAddresses);
		mail.setSubject('PS Timesheet Batch ' + a.Status);
		mail.setPlainTextBody
		('The batch Apex job processed ' + a.TotalJobItems +
		 ' batches with '+ a.NumberOfErrors + ' failures.');
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	
	    

    }

}