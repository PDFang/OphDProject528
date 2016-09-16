public class RCAClass 
{
	
    @future
    public static void SyncRelatedCases(Set<Id> publishedCaseIds, Set<Id> unPublishedCaseIds, Map<Id,Id> eventManagers)
    {
        Map<Id,Case> impactedCases = new Map<Id,Case>([SELECT Id, RFEPublished__c, ParentId FROM Case WHERE ParentId IN :publishedCaseIds OR ParentId IN :unPublishedCaseIds OR ID IN :publishedCaseIds OR ID IN :unPublishedCaseIds OR ID IN :eventManagers.keySet()]);
		List<Case> casesToUpdate = new List<Case>();
        
        if(!impactedCases.isEmpty())
        {
            for(Case c: impactedCases.values())
            {
                if(publishedCaseIds.contains(c.Id) || publishedCaseIds.contains(c.ParentId) )
                {
                    c.RFEPublished__c = true; 
                    c.RFEPublishedDateTime__c = system.now();
                }
                else if(unPublishedCaseIds.contains(c.Id) || unPublishedCaseIds.contains(c.ParentId))
                {
                    c.RFEPublished__c = false;
                    c.RFEPublishedDateTime__c = null;
                }
                
                if(eventManagers.containsKey(c.Id))
                {
                    c.EventCommander__c = eventManagers.get(c.Id);
                }
                
                casesToUpdate.add(c);
            }
        
            if(!casesToUpdate.isEmpty())
            {
                update casesToUpdate;
            }
            
        }
    }
}