trigger TaskAfterUpdateTrigger on Task (after update) 
{
	
	Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c; 
	Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
	Id prodRedRtId = rtMapByName.get('Product Readiness Project').getRecordTypeId();
	
	
	List<ProductReadinessTask__c> prd = ProductReadinessTask__c.getAll().values();
	Project__c[] relatedProjects = new Project__c[]{};
	Map<Id,Project__c> projMap = new Map<Id,Project__c>();
	List<Task> tasks = new List<Task>();
	Set<Id> whatIds = new Set<Id>();
	
	for(Task tx:trigger.new)
	{
		whatIds.add(tx.WhatId);
	}
	
	
	if(!whatIds.isEmpty())
	{
		relatedProjects = [SELECT Id, TargetLaunchDate__c, OwnerId, RecordTypeId, ClosedDate__c, ProjectStatus__c FROM Project__c WHERE RecordTypeId = :prodRedRtId AND Id IN :whatIds];
		
		if(!relatedProjects.isEmpty())
		{
			
			for(Project__c p:relatedProjects)
			{
				projMap.put(p.Id,p);
			}
	
			for(Task tx:trigger.new)
			{
				if(tx.Order__c!=NULL && tx.IsClosed && !tx.PreviouslyClosed__c)
				{
					if(projMap.get(tx.WhatId).RecordTypeId == prodRedRtId && projMap.get(tx.WhatId).ProjectStatus__c != 'Canceled')
					{
						for(ProductReadinessTask__c pr:prd)
						{
							if(pr.DependsOn__c == tx.Order__c)
							{
								Task t = new Task();
								t.Subject = pr.Name;
								t.WhatId = tx.WhatId;
								t.Type = pr.TaskType__c;
								t.Description = pr.Description__c;
								t.Order__c = pr.Order__c;
								
								if(pr.AssignTo__c == 'Concept Owner')
								{
									t.OwnerId = projMap.get(tx.WhatId).OwnerId;
								}
								else
								{
									t.OwnerId = pr.AssignTo__c;
								}
								
								if(pr.DaysPrior__c != null && projMap.get(tx.WhatId).TargetLaunchDate__c != Null)
								{
									t.ActivityDate = projMap.get(tx.WhatId).TargetLaunchDate__c - integer.valueOf(pr.DaysPrior__c);
									t.IsReminderSet = true;
									t.ReminderDateTime = datetime.newInstance(projMap.get(tx.WhatId).TargetLaunchDate__c - integer.valueOf(pr.DaysPrior__c),Time.newInstance(0,0,0,0));
								}
								
														
								tasks.add(t);
							}
							
						}
					}
				}
			}
		}
	}
	
	if(!tasks.isEmpty())
	{
		insert tasks;
	}
}