public class WorkItemCommentTrggerHandler extends TriggerHandler {
  
    private static Schema.SObjectType objType;
    public override void afterInsert()
    {
        
          CallTFSService(Trigger.New);
    }
    
    public override void afterUpdate()
    {
       		CallTFSService(Trigger.New);
    }
   
	public override void beforeDelete()
    {
        errorOnDel(trigger.new);
    }
	
    
    private static void CallTFSService(list<sObject> lstComments)
    {
       set<string> commentIds = new set<String>();
        
       for(sObject comment : lstComments)
       {
           Id currentId = (Id)comment.get('Id');
       	    objType = currentId.getSObjectType();
         
     	 if(trigger.isExecuting && trigger.isUpdate)	
         {
             sObject oldRec = trigger.oldMap.get(comment.Id);
             if((comment.get('Comment__c') != oldRec.get('Comment__c') || comment.get('SyncToTFS__c') == true)
               && comment.get('ParentTFSId__c') != '')
                 
             {
                 commentIds.add(string.valueOf(comment.get('Id')));
             }
             
         }
         else if(trigger.isinsert && comment.get('ParentTFSId__c') != '')
           {
                commentIds.add(string.valueOf(comment.get('Id')));
           }  
           
           
       }
        
        system.debug('objType =>' + objType);
        
        if(lstComments.size() >= 100)
        {
            for(sObject comment : lstComments)
            {
                comment.addError('Inserting more than 100 records are not allowed in a batch. These records will not be created in TFS. Please use small batches to insert the Work Items');
            }
        }
            else if(commentIds.size() > 0)
            {               
                
                if(objType == Schema.ISTFSWorkItemComment__c.getSObjectType() && !ISTFSINTEGRATIONCLASS.isWebServiceCall)
                {
                    
                     ISTFSINTEGRATIONCLASS.CallTFSFutureMethod(commentIds, 'ISTFSWorkItemComment__c');
                }
                	
                
                if(objType == Schema.ProjectComment__c.getSObjectType() && !ISTFSINTEGRATIONCLASS.isWebServiceCall)
                	 ISTFSINTEGRATIONCLASS.CallTFSFutureMethod(commentIds, 'ProjectComment__c');
                
            }        
    }
    
    
    private static void errorOnDel(list<sObject> lstComments)
    {
         for(sObject comment : lstComments)
            {

                comment.addError('You cannot delete a comment from Salesforce');
            }
    }
}