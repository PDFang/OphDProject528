global class HelpDeskWebServices 
{
	
	WebService static String CreateHelpDeskTasks(ID caseId, string requestType)
	{
		requestType = '%' + requestType + '%';
		List<Task> tasks = new List<Task>();
		
		Case c = [SELECT Id, Assigned_To__c FROM Case WHERE Id = :caseId];
		List<HelpDeskTask__c> hdTasks = [SELECT Name, RequestType__c, Subject__c, DaysUntilDue__c FROM HelpDeskTask__c WHERE RequestType__c LIKE :requestType OR RequestType__c = 'All' ORDER BY Order__c];
		
		for(HelpDeskTask__c h:hdTasks)
		{
			Task t = new Task();
			t.Subject = h.Subject__c;
			t.WhatId = c.Id;
			t.Type = 'Help Desk';
			
			if(h.DaysUntilDue__c != null)
			{
				t.ActivityDate = system.today() + integer.valueOf(h.DaysUntilDue__c);
			}
			
			tasks.add(t);
		}
		
		if(!tasks.isEmpty())
		{
			insert tasks;
		}
		
		return 'Tasks have been created.'; 
	}
	
	public static testMethod void TestHelpDeskWebservices()
	{
		HelpDeskTask__c hd = new HelpDeskTask__c();
		hd.Subject__c = 'Test';
		hd.RequestType__c = 'Software';	
		hd.Name = 'Test';
		hd.Order__c = 1;
		hd.DaysUntilDue__c = 3;
		
		insert hd;
		
		//set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
		
		Case c = new Case();
		c.Subject = 'Test';
		c.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Help Desk', 'Case');
		c.setOptions(dmo);
		
		insert c;
		
		HelpDeskWebServices.CreateHelpDeskTasks(c.Id, 'Software');
	}

}