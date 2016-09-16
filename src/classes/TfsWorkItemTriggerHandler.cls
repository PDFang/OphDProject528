public class TfsWorkItemTriggerHandler extends TriggerHandler 
{
    public TfsWorkItemTriggerHandler(){}
    
    public override void beforeInsert()
    {
        Set<string> tfsIds = new Set<string>();
		for(TfsWorkItem__c wi:(List<TfsWorkItem__c>)trigger.new)
	    {
	    	tfsIds.add(wi.Name);	    	
	    }
		
		Map<Id,TfsWorkItem__c> existingWorkItems = new Map<Id,TfsWorkItem__c>([SELECT ID, Name FROM TfsWorkItem__c WHERE Name IN :tfsIds]);
		
		if(!existingWorkItems.isEmpty())
		{
			for(TfsWorkItem__c wi:(List<TfsWorkItem__c>)trigger.new)
		    {
                for(TfsWorkItem__c ewi:existingWorkItems.values())
                {
                    if(wi.Name == ewi.Name)
                    {
                        wi.addError('TFS Work Item ' + wi.Name + ' already exists.');
                    }
                }
		    }
		}
    }
    
    public override void afterInsert()
    {
		for(TfsWorkItem__c wi:(List<TfsWorkItem__c>)trigger.new)
	    {
	     	if(wi.Name.isNumeric() && wi.TfsExternalId__c == null)
	        {
	         	TfsAccess.SyncTfsWorkItemAsync(wi.Id, integer.valueOf(wi.Name));   
	        }
		
	    }
    }
    
	public override void afterUpdate()
    {
        Set<Id> awaitingSupportInfoIds = new Set<Id>();
        Set<Id> verifyCustomerInfoIds = new Set<Id>();
        
        for(integer i=0;i<trigger.new.size();i++)
        {
            TfsWorkItem__c newItem = (TfsWorkItem__c)trigger.new[i];
            TfsWorkItem__c oldItem = (TfsWorkItem__c)trigger.old[i];
            
            //update tfs 
            if(NeedsToUpdateTfs(oldItem, newItem))
            { 
                TfsAccess.TfsUpdateBugAsync(newItem.Id);
            }
            
            //cases to update if awaiting support info
            if(newItem.UptivityState__c == 'Awaiting Support Info' && oldItem.UptivityState__c != 'Awaiting Support Info')
            {
                awaitingSupportInfoIds.add(newItem.Id);
            }
            
            //cases to update if Verify Customer
            if(newItem.UptivityState__c == 'Customer Verify' && oldItem.UptivityState__c != 'Customer Verify')
            {
                verifyCustomerInfoIds.add(newItem.Id);
            }
        }
        
        if(!awaitingSupportInfoIds.isEmpty())
        {
            UpdateCaseStatus(awaitingSupportInfoIds,'Awaiting Support Info');
        }
        
        if(!verifyCustomerInfoIds.isEmpty())
        {
            UpdateCaseStatus(verifyCustomerInfoIds,'Customer Verify');
        }
    }
    
    private boolean NeedsToUpdateTfs(TfsWorkItem__c oldItem, TfsWorkItem__c newItem)
    {
        boolean results = !system.isFuture() && UserInfo.getLastName() != '_castiron' && oldItem.TfsExternalId__c != null && newItem.TFSExternalID__c != null;
        return results;
    }
    
    private void UpdateCaseStatus(Set<Id> workItemIds, string newStatus)
    {
        Case[] cases = new Case[]{};
        cases = [SELECT Id, Status FROM Case WHERE TfsWorkItem__c IN :workItemIds];
        
        if(!cases.isEmpty())
        {
            for(Case c:cases)
            {
                c.Status = newStatus;
            }
            
            update cases;
        }
    }
}