public class WorkItemTriggerHandler extends TriggerHandler {
  
    public override void afterInsert()
    {
        
       CallTFSService(Trigger.New);
    }
    
    public override void afterUpdate()
    {
       		CallTFSService(Trigger.New);
    }
   
    private static void CallTFSService(list<ISTFSWorkItem__c> lstWorkItems)
    {
       set<string> workItemIds = new set<String>();
        
       for(ISTFSWorkItem__c wi : lstWorkItems)
       {
       		    
           
     	 if(trigger.isExecuting && trigger.isUpdate)	
         {
             ISTFSWorkItem__c oldRec = (ISTFSWorkItem__c)trigger.oldMap.get(wi.Id);
             if(wi.Area__c != oldRec.Area__c || wi.Priority__c != oldRec.Priority__c
               || wi.Product__c != oldRec.Product__c || wi.PrivacyImpact__c != oldRec.PrivacyImpact__c
               || wi.Risk__c != oldRec.Risk__c || wi.Details__c != oldRec.Details__c ||wi.Team__c != oldRec.Team__c
               || wi.SyncToTFS__c == true
               )
             {
                 workItemIds.add(wi.Id);
             }
             
         }
         else if(wi.Team__c != null && wi.Area__c != null && trigger.isInsert)
           {
               workItemIds.add(wi.Id);
           }  
           
           
       }
		system.debug('workItemIds - '+ workItemIds);        
        if(lstWorkItems.size() >= 100)
        {
            for(ISTFSWorkItem__c workItem : lstWorkItems)
            {
                workItem.addError('Inserting more than 100 records are not allowed in a batch. These records will not be created in TFS. Please use small batches to insert the Work Items');
            }
        }
            else if(workItemIds.size() > 0)
            {
                if (!ISTFSINTEGRATIONCLASS.isWebServiceCall)
                 	ISTFSINTEGRATIONCLASS.CallTFSFutureMethod(workItemIds, 'ISTFSWorkItem__c');
            }
        
       
        
        
    }
    
    
    
}