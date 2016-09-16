global class CaseWorkflowBatch implements Database.Batchable<sObject>{
 	global final String strQuery; 

    global CaseWorkflowBatch(string query)
    {
        strQuery = query;
    }
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
    	return Database.getQueryLocator(strQuery);
    }
 
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
    	//create list for update
  		List<Case> listCase = new List<Case>();
  		List<CaseComment> ccom = new List<CaseComment>();
  		
  		//loop through case records
       	for(SObject objSObject : scope)
       	{
      		Case c = (Case)objSObject;
      		
      		//process Waiting on Customer records
      		if(c.Status == 'Waiting on Customer')
      		{
	      		if(c.WaitingOnCustomerProcessFlag__c == 3)
	      		{
	      			//close out the ticket
	      			//c.WaitingOnCustomerProcessFlag__c = 4;
	      			
	      			c.WaitingOnCustomerProcessFlag__c = 0;
	      			c.Status = 'Closed';
	      			if(c.Disposition__c == null) {c.Disposition__c = 'System Closed - Waiting On Customer';}
	      			c.SystemClosed__c = true;
	      			
	      			CaseComment cc = new CaseComment();
	      			cc.ParentId = c.Id;
	      			cc.IsPublished = false;
	      			cc.CommentBody = 'Case was system closed. Waiting on Customer over 72 hours.';
	      			
	      			ccom.add(cc);
	      		} 
	      		else if(c.WaitingOnCustomerProcessFlag__c == 2)
      			{
      				c.WaitingOnCustomerProcessFlag__c = 3;
      				
      				CaseComment cc = new CaseComment();
	      			cc.ParentId = c.Id;
	      			cc.IsPublished = false;
	      			cc.CommentBody = 'Second Waiting on Customer notice email was sent to the customer.';
	      			
	      			ccom.add(cc);
      			}
	      		else if(c.WaitingOnCustomerProcessFlag__c == 1)
      			{
      				c.WaitingOnCustomerProcessFlag__c = 2;
      				
      				CaseComment cc = new CaseComment();
	      			cc.ParentId = c.Id;
	      			cc.IsPublished = false;
	      			cc.CommentBody = 'First Waiting on Customer notice email was sent to the customer.';
	      			
	      			ccom.add(cc);
      			}
      			else if(c.WaitingOnCustomerProcessFlag__c == 0 || c.WaitingOnCustomerProcessFlag__c == null)
      			{
      				c.WaitingOnCustomerProcessFlag__c = 1;
      			}
      		}
      		
      		//process Resolved records
      		if(c.Status == 'Resolved')
      		{
      			
      			if(c.ResolvedProcessFlag__c == 3)
      			{
      				//close out the case
      				//c.ResolvedProcessFlag__c = 4;
      				
      				c.ResolvedProcessFlag__c = 0;
      				c.Status = 'Closed';
      				if(c.Disposition__c == null) {c.Disposition__c = 'System Closed - Resolved';}
      				c.SystemClosed__c = true;
      				
      				CaseComment cc = new CaseComment();
	      			cc.ParentId = c.Id;
	      			cc.IsPublished = false;
	      			cc.CommentBody = 'Case was system closed. Resolved over 72 hours.';
	      			
	      			ccom.add(cc);
      			}
      			else if(c.ResolvedProcessFlag__c == 2)
      			{
      				c.ResolvedProcessFlag__c = 3;
      				
      				CaseComment cc = new CaseComment();
	      			cc.ParentId = c.Id;
	      			cc.IsPublished = false;
	      			cc.CommentBody = 'Second Resolved notice email was sent to the customer.';
	      			
	      			ccom.add(cc);
      			}
      			else if(c.ResolvedProcessFlag__c == 1)
      			{
      				c.ResolvedProcessFlag__c = 2;
      				
      				CaseComment cc = new CaseComment();
	      			cc.ParentId = c.Id;
	      			cc.IsPublished = false;
	      			cc.CommentBody = 'First Resolved notice email was sent to the customer.';
	      			
	      			ccom.add(cc);
      			}
      			else if(c.ResolvedProcessFlag__c == 0 || c.ResolvedProcessFlag__c == null)
      			{
      				c.ResolvedProcessFlag__c = 1;
      			}
      		}
      		
      		
      		
      		listCase.add(c);
   			
       }     
       //update records
       if (listCase.size() > 0 ) {update listCase;}
       if (ccom.size() > 0) {insert ccom;}
    }

    global void finish(Database.BatchableContext BC)
    {
	    AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
	    TotalJobItems, CreatedBy.Email, ExtendedStatus
	    FROM AsyncApexJob WHERE Id =
	    :BC.getJobId()];
	   	// Send an email to the Apex job's submitter notifying of job completion. 
	    
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] {a.CreatedBy.Email};
		mail.setToAddresses(toAddresses);
		mail.setSubject('Case Workflow Batch ' + a.Status);
		mail.setPlainTextBody
		('The batch Apex job processed ' + a.TotalJobItems +
		 ' batches with '+ a.NumberOfErrors + ' failures.' + '/n/r' + a.ExtendedStatus);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	
	    

    }
}