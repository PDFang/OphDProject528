public class ProjectTriggerHandler extends TriggerHandler{

    public override void afterInsert(){
        new PartnerShareHelper().addShare(trigger.new, trigger.oldMap);
    }

    public override void afterUpdate(){
        new PartnerShareHelper().deleteShare(trigger.new, trigger.oldMap);
        new PartnerShareHelper().addShare(trigger.new, trigger.oldMap);
        //CallTFSService(trigger.new);
    }
    
/*    
     private static void CallTFSService(list<Project__c> lstProjects)
    {
        
       set<string> projectIds = new set<String>();
        
       for(Project__c proj : lstProjects)
       {
        if(proj.TFSId__c != '' )
        {
            if(trigger.isExecuting && trigger.isUpdate && proj.SyncToTFS__c == true)    
            {
                projectIds.add(proj.Id);
            }
         
        }
       }    
        
        system.debug('projectIds ==> ' + projectIds);
        
        if(lstProjects.size() >= 100)
        {
            for(Project__c proj : lstProjects)
            {
                proj.addError('Inserting more than 100 records are not allowed in a batch. These records will not be created in TFS. Please use small batches to insert the Work Items');
            }
        }
            else if(projectIds.size() > 0)
            {
                 ISTFSINTEGRATIONCLASS.CallTFSFutureMethod(projectIds, 'Project__c');
                 
            }

        
    }    
*/    
}