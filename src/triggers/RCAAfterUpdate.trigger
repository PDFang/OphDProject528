trigger RCAAfterUpdate on RCA__c (after update) 
{
    
	List<Case> cases = new List<Case>();
	Set<Id> publishedCaseIds = new Set<Id>();
	Set<Id> unPublishedCaseIds = new Set<Id>();
	Map<Id,Id> eventManagers = new Map<Id,Id>();
	
	for(integer i=0;i<trigger.size;i++)
	{
		RCA__c oldRca = trigger.old[i];
		RCA__c newRca = trigger.new[i];
		
		if(!oldRca.RFEPublished__c && newRca.RFEPublished__c)
		{
			publishedCaseIds.add(newRca.Event__c);
		}
		
		if(oldRca.RFEPublished__c && !newRca.RFEPublished__c)
		{
			unPublishedCaseIds.add(newRca.Event__c);
		}
		
		if(oldRca.EventCommander__c != newRca.EventCommander__c)
		{
			eventManagers.put(newRCA.Event__c,newRca.EventCommander__c);
		}
		
	}
    
    if(!System.isFuture())
    {
    	RCAClass.SyncRelatedCases(publishedCaseIds, unPublishedCaseIds, eventManagers);
    }
    /*
    Map<Id,Case> impactedCases = new Map<Id,Case>([SELECT Id, RFEPublished__c, ParentId FROM Case WHERE ParentId IN :publishedCaseIds OR ParentId IN :unPublishedCaseIds OR ID IN :publishedCaseIds OR ID IN :unPublishedCaseIds OR ID IN :eventManagers.keySet()]);
    
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
            
            cases.add(c);
        }
	
        if(!cases.isEmpty())
        {
            update cases;
        }
        
    }
	*/

}