public class SalesEngineeringLogic
{
    public static void SetProjectTaskSubject(List<Task> tasks, Id salesEngineeringRecordTypeId)
    {
        List<Task> projectTasks = new List<Task>();
        Set<Id> projectIds = new Set<Id>();
    	String    projectPrefix    = Schema.SObjectType.Project__c.getKeyPrefix();
        
        
        for(Task t:tasks)
        {
            if(t.WhatId != null)
            {
                if(((string)t.WhatId).startsWith(projectPrefix))
                {
                    projectTasks.add(t);
                    projectIds.add(t.WhatId);
                }
            }
        }
        
        if(!projectIds.isEmpty() && !tasks.isEmpty())
        {
            Map<Id, Project__c> projects = new Map<Id, Project__c>([SELECT Id, Account__r.Name FROM Project__c WHERE ID IN:projectIds AND RecordTypeId = :salesEngineeringRecordTypeId]);
            
            for(Task t:projectTasks)
            {
                if(projects.containsKey(t.WhatId) && string.isBlank(t.Subject) )
                {
                    t.Subject = UserInfo.getLastName() 
                                + '-' 
                                + projects.get(t.WhatId).Account__r.Name 
                                + ' [' 
                                + t.Project_Stages__c
                                + ']'
                                + ''
                                + t.Activity_Type__c
                                + '';
                }
            }
            
        }
        
    }
    
    
	public static void OpportunitySalesEngineerReassigned(Set<Id> opps, Id salesEngineeringRecordTypeId)
    {
        //only send opp ids if SalesEngineer__c has changed
        Project__c[] projects = new Project__c[]{};
        
        for(Opportunity opp:[SELECT Id, SalesEngineer__c, AccountId, OwnerId, Name, (SELECT OwnerId FROM Projects__r WHERE RecordTypeId = :salesEngineeringRecordTypeId) FROM Opportunity WHERE ID IN:opps])
        {
            if (opp.Projects__r.size() == 0)
            {
                Project__c p = new Project__c();
                // Create new Project if one doesn't exist
                    p.RecordTypeId     = salesEngineeringRecordTypeId;
                    p.Opportunity__c   = opp.Id;
                    p.Account__c       = opp.AccountId;
                    p.SalesRep__c      = opp.OwnerId;
                    p.OwnerId          = opp.SalesEngineer__c;
                    p.Summary__c       = opp.Name;
    
                projects.add(p);
                
                // Tasks are created automatically by another trigger on the Project.            
            }
            else
            // We already have projects, loop through them and reassign
            {
                 for (Project__c p: opp.Projects__r) 
                 {
                     if(p.OwnerId != opp.SalesEngineer__c)
                     {
                         p.OwnerId = opp.SalesEngineer__c;
                     	 projects.add(p);
                     }
                     // Tasks are updated via a seperate trigger on the Project.
                 }
            }
        }
        
        if(!projects.isEmpty())
        {
            upsert projects;
        }
        
    }
    
    public static void CreateNewProjectTasks(List<Project__c> projects, Id salesEngineeringRecordTypeId)
    {
        List<Task> tasks = new List<Task>();
        
        for(Project__c project:projects)
        {
            if(project.RecordTypeId == salesEngineeringRecordTypeId)
            {
                // When creating a Project, automatically create tasks on Project
                Task t1 = new Task();
                t1.OwnerId			 = project.OwnerId;
                t1.WhatId            = project.Id;
                t1.Project_Stages__c = 'Discovery';
                t1.Activity_Type__c  = 'Initial Discovery';
                t1.Description       = 'This task was automatically created.';
                    
                tasks.add(t1);
                
                /*Task t2 = new Task();
                	t2.OwnerId			 = project.OwnerId;
                    t2.WhatId            = project.Id;
                    t2.Project_Stages__c = 'Discovery';
                    t2.Activity_Type__c  = 'Demonstration';
                    t2.Description       = 'This task was automatically created.';
                    
                tasks.add(t2);
                
                
                Task t3 = new Task();
                t3.OwnerId			 = project.OwnerId;
                    t3.WhatId            = project.Id;
                    t3.Project_Stages__c = 'Design';
                    t3.Activity_Type__c  = 'Draft SO';
                    t3.Description       = 'This task was automatically created.';
                    
                tasks.add(t3);
                
                Task t4 = new Task();
                t4.OwnerId			 = project.OwnerId;
                    t4.WhatId            = project.Id;
                    t4.Project_Stages__c = 'Restate';
                    t4.Activity_Type__c  = 'Customer SO Review';
                    t4.Description       = 'This task was automatically created.';
                    
                tasks.add(t4);
                
                Task t5 = new Task();
                t5.OwnerId			 = project.OwnerId;
                    t5.WhatId            = project.Id;
                    t5.Project_Stages__c = 'Handoff';
                    t5.Activity_Type__c  = 'Project Team SO Review';
                    t5.Description       = 'This task was automatically created.';
                    
                tasks.add(t5);*/
        	}
        }
        
        if(!tasks.isEmpty())
        {
            insert tasks;
        }
    }
    
    public static void UpdateProjectRelatedOwners(List<Project__c> oldProjects, List<Project__c> newProjects, Id salesEngineeringRecordTypeId )
    {
        Map<Id, Id> newProjectOwners = new Map<Id, Id>();
        Map<Id, Id> oldProjectOwners = new Map<Id, Id>();
        Map<Id, Id> newProjectOpportunities = new Map<Id, Id>();
        List<Task> tasks = new List<Task>();
        List<Opportunity> opportunities = new List<Opportunity>();
        
        for(integer i = 0;i<newProjects.size();i++)
        {
            Project__c newProject = newProjects[i];
            Project__c oldProject = oldProjects[i];
            
            if(newProject.OwnerId != oldProject.OwnerId && newProject.RecordTypeId == salesEngineeringRecordTypeId)
            {
                newProjectOwners.put(newProject.Id, newProject.OwnerId);
                oldProjectOwners.put(oldProject.Id, oldProject.OwnerId);
                newProjectOpportunities.put(newProject.Opportunity__c, newProject.Id);
            }
        }
        
        if(!newProjectOwners.isEmpty())
        {
            for(Task t:[SELECT Id, OwnerId, WhatId FROM Task WHERE WhatId = :newProjectOwners.keySet() AND IsClosed=false])
            {
                if(t.OwnerId != newProjectOwners.get(t.WhatId) && t.OwnerId == oldProjectOwners.get(t.WhatId))
                {
                    id projectId = t.WhatId;
                    t.OwnerId = newProjectOwners.get(projectId);
                    tasks.add(t);
                }
            }
            
            for(Opportunity o:[SELECT Id, SalesEngineer__c FROM Opportunity WHERE Id IN:newProjectOpportunities.keySet()])
            {
                if(o.SalesEngineer__c != newProjectOwners.get(newProjectOpportunities.get(o.Id)))
                {
                    o.SalesEngineer__c = newProjectOwners.get(newProjectOpportunities.get(o.Id));
                    opportunities.add(o);
                }
            }
            
            if(!tasks.isEmpty())
            {
                update tasks;
            }
            
            if(!opportunities.isEmpty())
            {
                update opportunities;
            }
        }
    }
}