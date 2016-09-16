trigger AssetsProjectTrigger on Asset (after insert, after update, after delete) 
{
/*
    Set<Id> phaseIds = new Set<Id>();
    Set<Id> projectIds = new Set<Id>();
    
	if(!trigger.isDelete)
    {
        for(integer i=0; i<trigger.new.size();i++)
        {
          
            Asset newAsset = trigger.new[i];
            
            if(trigger.isInsert)
            {
                if(newAsset.Project_Phase__c != null)
                {
                    phaseIds.add(newAsset.Project_Phase__c);
                }
           
                if(newAsset.Parent_Project__c != null)
                {
                    projectIds.add(newAsset.Parent_Project__c);
                }
            }            
            
            if(trigger.isUpdate)
            {
             	Asset oldAsset = trigger.old[i];
                // Project Phase, Parent Project, Final Price or Price is changed
            	if (newAsset.project_Phase__c != oldAsset.Project_Phase__C
                    || newAsset.Parent_Project__c != oldAsset.Parent_Project__c
                    || newAsset.FinalPrice__c != oldAsset.FinalPrice__c
                    || newAsset.Price != oldAsset.Price)
            	{
                    if (oldAsset.Project_Phase__c != Null )
                    {
                        phaseIds.add(oldAsset.Project_Phase__c);
                    }
                    if (newAsset.Project_Phase__c != Null) {
                        phaseIds.add(newAsset.Project_Phase__c);
                    }
                    if (oldAsset.Parent_Project__c != Null)
                    {
                        projectIds.add(oldAsset.Parent_Project__c);
                    }
                    if (newAsset.Parent_Project__c != Null)
                    {
                        projectIds.add(newAsset.Parent_Project__c);
                    }
            	}
            }
        }
        
    } 
    else
    {
        for(Asset a: trigger.old)
        {
            if(a.Project_Phase__c != null)
            {
                phaseIds.add(a.Project_Phase__c);
            }
            
            if(a.Parent_Project__c != null)
            {
                projectIds.add(a.Parent_Project__c);
            }
        }
    }
    
    system.debug('projectIds ==>' + projectIds);
    system.debug('phaseIds ==>' + phaseIds);
 	   
    if(!phaseIds.isEmpty())
    {
    	Map<Id, Project__c> phases = ProjectClass.ProjectPhaseAssetSummary(phaseIds);
        update phases.values();
    }
    if(!projectIds.isEmpty())
    {
    	Map<Id, Project__c> parentProjects = ProjectClass.ProjectParentAssetSummary(projectIds);
        update parentProjects.values();
    }
    
*/
}