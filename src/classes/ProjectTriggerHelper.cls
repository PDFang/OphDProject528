public class ProjectTriggerHelper
{
	/*
	  This method takes a list of PhasedProjects and updates the parent objects Planned hour field with total from the childs 
	  planned hour field.
	 */
	public static void updateParentPlannedHours(List<Project__c> listNewProjects, Id projectId)
	{
		List<Project__c> parentPhasedProjectsUpdate = new List<Project__c> ();
		Set<Id> setParentRecords = new Set<Id> ();

		for (Project__c childProject : listNewProjects)
		{
			if (childProject.ParentProject__c != null && childProject.RecordTypeId == projectId)
			{
				setParentRecords.add(childProject.ParentProject__c);
			}
		}

        if(setParentRecords.size() > 0)
        {
            AggregateResult[] groupedProjectResults = [SELECT ParentProject__c parentProject, Sum(PlannedHours__c) totalPlannedHours FROM Project__c WHERE ParentProject__c in :setParentRecords GROUP BY ParentProject__c];

            for (AggregateResult groupedProject : groupedProjectResults)
            {
                Project__c parent = new Project__c(Id = (Id) groupedProject.get('parentProject'));
                parent.PlannedHours__c = (Decimal) groupedProject.get('totalPlannedHours');
    
                parentPhasedProjectsUpdate.add(parent);
            }
    
            // Update Parent Accounts
            if (!parentPhasedProjectsUpdate.isEmpty())
            {
                update parentPhasedProjectsUpdate;
            }
        }
		
	}

	/*
	  This method will take a list of updated phased projects and change the status for the related assets 
	 */
	public static void updateAssetStatusForPhasedProject(List<Project__c> listNewProjects, Map<Id, Project__c> oldMapProjects)
	{
		List<Asset> assetsToUpdate = new List<Asset> ();
		List<SBQQ__Subscription__c> subscriptionsToUpdate = new List<SBQQ__Subscription__c> ();
		
		Map<Id, ImplementedProduct__c> implementedProductToUpdate = new Map<Id, ImplementedProduct__c> ();
		Map<Id, Project__c> projectsToUpdate = new Map<Id, Project__c> ();
		Set<Id> setProjectIds = new set<Id>();
        
        for(Project__c proj : listNewProjects)
        {
            // Ensure that we are only running this if the GoLive date actually changed and its not null
            if(proj.ActualProjectGoLiveDate__c != oldMapProjects.get(proj.Id).ActualProjectGoLiveDate__c
               	&& proj.ActualProjectGoLiveDate__c != null)
            	setProjectIds.add(proj.Id);            
        }
        
        system.debug('setProjectIds ==>' + setProjectIds);
        
        
        if(setProjectIds.size() > 0)
        {
            for (Asset assetRecord :[SELECT Id, Status, Project_Phase__r.ActualProjectGoLiveDate__c, ImplementedProduct__c FROM Asset WHERE Project_Phase__c in :listNewProjects AND Project_Phase__r.Go_Live_Locked__c = false])
            {
                    Project__c oldValue = oldMapProjects.get(assetRecord.Project_Phase__c);                    
                    // Update Asset Status to Delivered				
                    assetRecord.Status = '4 - Delivered'; // TODO: Should find how to dynamically find this value
                    assetsToUpdate.add(assetRecord);
    
                    if (!implementedProductToUpdate.containsKey(assetRecord.ImplementedProduct__c) && assetRecord.ImplementedProduct__c != null)
                    {
                        // Update associated Implemented Product Status to Implemented and set GoLiveDate
                        ImplementedProduct__c ip = new ImplementedProduct__c
                        (
                         Id = assetRecord.ImplementedProduct__c,
                         GoLiveDate__c = assetRecord.Project_Phase__r.ActualProjectGoLiveDate__c,
                         Status__c = 'Implemented'
                        );
    
                        implementedProductToUpdate.put(assetRecord.ImplementedProduct__c, ip);
                    }
    
                    Project__c project = new Project__c(Id = oldValue.Id, Go_Live_Locked__c = true);
    
                    projectsToUpdate.put(project.Id, project);
                }                  
		

            for (SBQQ__Subscription__c subscriptionRecord :[SELECT Id, Status__c, Project_Phase__r.ActualProjectGoLiveDate__c, Implemented_Product__c FROM SBQQ__Subscription__c WHERE Project_Phase__c in :listNewProjects AND Project_Phase__r.Go_Live_Locked__c = false])
            {
                Project__c oldValue = oldMapProjects.get(subscriptionRecord.Project_Phase__c);
               
                    // Update Asset Status to Delivered
                    subscriptionRecord.Status__c = '4 - Delivered'; // TODO: Should find how to dynamically find this value
                    subscriptionsToUpdate.add(subscriptionRecord);
    
                    if (!implementedProductToUpdate.containsKey(subscriptionRecord.Implemented_Product__c) && subscriptionRecord.Implemented_Product__c != null)
                    {
                        // Update associated Implemented Product Status to Implemented and set GoLiveDate
                        ImplementedProduct__c ip = new ImplementedProduct__c
                        (
                         Id = subscriptionRecord.Implemented_Product__c,
                         GoLiveDate__c = subscriptionRecord.Project_Phase__r.ActualProjectGoLiveDate__c,
                         Status__c = 'Implemented'
                        );
    
                        implementedProductToUpdate.put(subscriptionRecord.Implemented_Product__c, ip);
                    }
    
                    Project__c project = new Project__c(Id = oldValue.Id, Go_Live_Locked__c = true);
                    projectsToUpdate.put(project.Id, project);
                }            
          }
		if (!implementedProductToUpdate.isEmpty())
		{
			update implementedProductToUpdate.values();
		}

		if (!assetsToUpdate.isEmpty())
		{
			update assetsToUpdate;
		}

		if (!projectsToUpdate.isEmpty())
		{
			update projectsToUpdate.values();
		}

		if (!subscriptionsToUpdate.isEmpty())
		{
			update subscriptionsToUpdate;
		}
	}


	/*
	  This method takes a list of new projects and create tasks
	 */
	public static void createProjectTasks(List<Project__c> listNewProjects)
	{
		Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c;
		Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

		//Get Order management record type id 
		Id OMRtId = rtMapByName.get('Order Management').getRecordTypeId();
		Id prodRedRtId = rtMapByName.get('Product Readiness Project').getRecordTypeId();
		Id dedProvRecordTypeId = rtMapByName.get('Dedicated Provisioning').getRecordTypeId();
		Id salesEngineeringRecordTypeId = rtMapByName.get('Sales Engineering Project').getRecordTypeId();
		Id psProjectPhaseSaasRecordTypeId = rtMapByName.get('PS Project Phase SaaS').getRecordTypeId();

		//get custom settings
		List<OrderManagementTask__c> omt = [SELECT o.Type__c, o.DaysUntilDue__c, o.PartnerOrder__c, o.NewOrder__c, o.MoveOrder__c, o.DisconnectOrder__c, o.Description__c, o.CustomerOrder__c, o.AddOrder__c FROM OrderManagementTask__c o ORDER BY o.Order__c];
		List<ProductReadinessTask__c> prd = ProductReadinessTask__c.getAll().values();
		List<DedicatedProvisioningTask__c> dedProvTasks = [SELECT d.Task__c, d.TaskType__c, d.Sip__c, d.Order__c, d.NetworkOrders__c, d.Name, d.Mpls__c, d.IpSec__c, d.IntelT__c, d.IntelDS3__c, d.Disconnects__c, d.Dia__c, d.IntelligentTDS3Migration__c, d.COLO__c From DedicatedProvisioningTask__c d ORDER BY Order__c];
		List<Task> tasks = new List<Task> ();

		// Loop through all the projects and create the necessary tasks
		for (Project__c p : listNewProjects)
		{
			//only dedicated provisioning
			if (p.RecordTypeId == dedProvRecordTypeId)
			{
				for (DedicatedProvisioningTask__c ded : dedProvTasks)
				{
					if (
					(p.ProjectType__c == 'Intelligent T' && ded.IntelT__c)
					    || (p.ProjectType__c == 'Intelligent DS3' && ded.IntelDS3__c)
					    || (p.ProjectType__c == 'MPLS' && ded.Mpls__c)
					    || (p.ProjectType__c == 'DIA' && ded.Dia__c)
					    || (p.ProjectType__c == 'SIP' && ded.Sip__c)
					    || (p.ProjectType__c == 'IPSec' && ded.IpSec__c)
					    || (p.ProjectType__c == 'Network Orders' && ded.NetworkOrders__c)
					    || (p.ProjectType__c == 'Disconnects' && ded.Disconnects__c)
					    || (p.ProjectType__c == 'Intelligent-T/DS3 Migration' && ded.IntelligentTDS3Migration__c
                        || (p.ProjectType__c == 'COLO' && ded.COLO__C))
					)
					{
						Task t = new Task();
						t.Subject = ded.Task__c;
						t.WhatId = p.Id;
						t.Type = ded.TaskType__c;
						t.Order__c = ded.Order__c;

						tasks.add(t);
					}

				}
			}
			//only order management
			if (p.RecordTypeId == OMRtId)
			{
				for (OrderManagementTask__c o : omt)
				{
					if (
					(p.RequestType__c == 'Add' && p.ProjectType__c == 'Partner' && o.PartnerOrder__c && o.AddOrder__c)
					    || (p.RequestType__c == 'New' && p.ProjectType__c == 'Partner' && o.PartnerOrder__c && o.NewOrder__c)
					    || (p.RequestType__c == 'Move' && p.ProjectType__c == 'Partner' && o.PartnerOrder__c && o.MoveOrder__c)
					    || (p.RequestType__c == 'Disconnect' && p.ProjectType__c == 'Partner' && o.PartnerOrder__c && o.DisconnectOrder__c)
					    || (p.RequestType__c == 'Add' && p.ProjectType__c == 'Customer' && o.CustomerOrder__c && o.AddOrder__c)
					    || (p.RequestType__c == 'New' && p.ProjectType__c == 'Customer' && o.CustomerOrder__c && o.NewOrder__c)
					    || (p.RequestType__c == 'Move' && p.ProjectType__c == 'Customer' && o.CustomerOrder__c && o.MoveOrder__c)
					    || (p.RequestType__c == 'Disconnect' && p.ProjectType__c == 'Customer' && o.CustomerOrder__c && o.DisconnectOrder__c)

					)
					{
						Task t = new Task();
						t.Subject = o.Description__c;
						t.WhatId = p.Id;
						t.Type = o.Type__c;

						if (o.DaysUntilDue__c != null)
						{
							t.ActivityDate = system.today() + integer.valueOf(o.DaysUntilDue__c);
						}

						tasks.add(t);
					}

				}
			}

			//product readiness tasks
			if (p.RecordTypeId == prodRedRtId)
			{
				for (ProductReadinessTask__c pr : prd)
				{
					if (
					(p.PricingRateReview__c && pr.CorePlus__c && pr.DependsOn__c == Null)
					    ||
					(!p.PricingRateReview__c && !pr.CorePlus__c && pr.CoreFirstTask__c)
					)
					{

						Task t = new Task();
						t.Subject = pr.Name;
						t.WhatId = p.Id;
						t.Type = pr.TaskType__c;
						t.Description = pr.Description__c;
						t.Order__c = pr.Order__c;

						if (pr.AssignTo__c == 'Concept Owner')
						{
							t.OwnerId = p.OwnerId;
						}
						else
						{
							t.OwnerId = pr.AssignTo__c;
						}

						if (pr.DaysPrior__c != null && p.TargetLaunchDate__c != Null)
						{
							t.ActivityDate = p.TargetLaunchDate__c - integer.valueOf(pr.DaysPrior__c);
							t.IsReminderSet = true;
							t.ReminderDateTime = datetime.newInstance(p.TargetLaunchDate__c - integer.valueOf(pr.DaysPrior__c), Time.newInstance(0, 0, 0, 0));
						}

						tasks.add(t);
					}

				}
			}
		}

		if (!tasks.isEmpty())
		{
			insert tasks;
		}
	}

	/*
	  Creates Projects in a new Status and Assigns an owner
	 */
	public static void assignProjectOwners(List<Project__c> listNewProjects)
	{
		//get assignment values
		List<ObjectAssignment__c> oa = [SELECT ObjectRecordTypeId__c, AssignmentValue__c, AssignmentSubValue__c, UserID__c FROM ObjectAssignment__c WHERE ObjectName__c = 'Project__c'];
		String itRt = inContactBaseClass.SelectRecordTypeIDByName('IT Project Request', 'Project__c');

		if (!oa.isEmpty())
		{
			for (Project__c p : listNewProjects)
			{
				// All new it projects need to go to backlogged status
				if (p.RecordTypeId == itRt)
				{
					p.ProjectStatus__c = 'New';
				}

				for (ObjectAssignment__c o : oa)
				{
					if (p.RecordTypeId == o.ObjectRecordTypeID__c)
					{
						if (p.ProjectType__c == o.AssignmentValue__c && p.ProjectSubType__c == o.AssignmentSubValue__c)
						{
							p.OwnerId = o.UserID__c;
							break;
						}
						else if (p.ProjectType__c == o.AssignmentValue__c && o.AssignmentSubValue__c == NULL)
						{
							p.OwnerId = o.UserID__c;

						}
						else if (o.AssignmentValue__c == 'Default')
						{
							p.OwnerId = o.UserId__c;
						}
					}
				}
			}
		}
	}

	/*
	  Set Status for IT and DBA Projects baed on 
	 */
	public static void setStatusForITAndDbaProjects(List<Project__c> listNewProjects, Map<Id, Project__c> oldProject)
	{
		Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c;
		Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

		//Get Order management record type id 
		Id itRt = rtMapByName.get('IT Project Request').getRecordTypeId();
		Id dbaRT = rtMapByName.get('Database Administration Request').getRecordTypeId();

		for (Project__c newProjectRecord : listNewProjects)
		{
			Project__c oldProj = oldProject.get(newProjectRecord.Id);
			Project__c newProj = newProjectRecord;

			//for dba requests that are closed or cancelled assign back to creator
			if (newProj.RecordTypeId == dbaRT)
			{
				if (
				((newProj.ProjectStatus__c == 'Closed' || newProj.ProjectStatus__c == 'Canceled')
				 && (oldProj.ProjectStatus__c != 'Closed' || oldProj.ProjectStatus__c != 'Canceled'))
				    || (newProj.ProjectStatus__c == 'Return For Changes' && oldProj.ProjectStatus__c != 'Return For Changes')
				    || (newProj.ProjectStatus__c == 'Needs More Information' && oldProj.ProjectStatus__c != 'Needs More Information')
				)
				{
					newProj.OwnerId = newProj.CreatedById;
				}
			}

			//for IT projects
			//if (newProj.RecordTypeId == itRt)
			//{
				//cannot change the status after it is done
				//if (oldProj.ProjectStatus__c == 'Closed')
				//{
					//newProjectRecord.AddError('Cannot edit projects once they are in a "Closed" status. Open a new project if additional features are needed.');
				//}
			//}
		}
	}

	// Assign Phase# to PS Phase projects
	// Method refactored to avoid a DML update
    public static void setNextPhaseNumber(List<Project__c> listNewProjects ){
      
        Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        //get record type ids 
        Id phaseSaasProject = rtMapByName.get('PS Project Phase SaaS').getRecordTypeId();
        Id phasePremiseProject = rtMapByName.get('PS Project Phase Premise WFO').getRecordTypeId();

		Set<Id> parentProjectIds = new Set<Id>();
        List<Project__c> projectsToUpdate = new List<Project__c>();
        
        for (Project__c newProjectRecord : listNewProjects) {

			if ((newProjectRecord.RecordTypeId == phaseSaasProject || newProjectRecord.RecordTypeId == phasePremiseProject) && newProjectRecord.ParentProject__c != null
					&& (newProjectRecord.Phase__c == '0' || newProjectRecord.Phase__c == null)){
				parentProjectIds.add(newProjectRecord.ParentProject__c);
				projectsToUpdate.add(newProjectRecord);
			}
		}

		system.Debug('setNextPhaseNumber(): projectsToUpdate - ' + projectsToUpdate);

		if(projectsToUpdate.isEmpty()) {
			return;
		}

		Map<Id, Integer> parentMaxPhaseMap = new Map<Id, Integer>();
		// Get max Phase# grouped by parent project
		for(AggregateResult groupedProjectResult : [Select max (Phase__c) maxPhase, ParentProject__c From Project__c where ParentProject__c = :parentProjectIds group by ParentProject__c]) {

			Integer maxPhase = groupedProjectResult.get('maxPhase') != null ? Integer.valueOf(groupedProjectResult.get('maxPhase')) : 0;
			Id parentProjectId = (Id) groupedProjectResult.get('ParentProject__c');
			parentMaxPhaseMap.put(parentProjectId, maxPhase);
		}


		for (Project__c newProjectRecord : projectsToUpdate){
			Integer maxPhaseNumber =  parentMaxPhaseMap.containsKey(newProjectRecord.ParentProject__c) ? parentMaxPhaseMap.get(newProjectRecord.ParentProject__c) : 0;
			maxPhaseNumber++;
			newProjectRecord.Phase__c = String.valueOf(maxPhaseNumber);
			parentMaxPhaseMap.put(newProjectRecord.ParentProject__c, maxPhaseNumber);
		}

    }

}