public class ProjectTriggerHandler extends TriggerHandler{

    public override void afterInsert(){
        //new PartnerShareHelper().addShare(trigger.new, trigger.oldMap);
        calculateProjectedDeadline(trigger.new);
    }

    public override void afterUpdate(){
        calculateProjectedDeadline(trigger.new);
        CallTFSService(trigger.new);
        //new PartnerShareHelper().deleteShare(trigger.new, trigger.oldMap);
        //new PartnerShareHelper().addShare(trigger.new, trigger.oldMap);       
    }
    
    public override void afterDelete(){
        calculateProjectedDeadline(trigger.old);
    }        
    
    private static void CallTFSService(list<Project__c> lstProjects)
    {
        system.debug('trigger context ==> ' + trigger.isExecuting + ', ' +  trigger.isUpdate);        
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
                 if (!ISTFSINTEGRATIONCLASS.isWebServiceCall)
                    ISTFSINTEGRATIONCLASS.CallTFSFutureMethod(projectIds, 'Project__c');
                 
            }

        
    }    
    
    private static void calculateProjectedDeadline(list<Project__c> newList){
        
        Map<Id, Project__c> oldMap = (Map<Id, Project__c>)( trigger.oldMap );
        Set<Id> vaildRecordTypeIdSet = new Set<Id>();        
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Project__c.getRecordTypeInfosByName();
        if(rtMapByName.containsKey('PS Project Phase Premise WFO') == false){
            return;
        }
        vaildRecordTypeIdSet.add(rtMapByName.get('PS Project Phase Premise WFO').getRecordTypeId());
        
        List<Project__c> processList = new List<Project__c>();
        Set<Id> parentProjectIdSet = new Set<Id>();
        for(Project__c newProject : newList){
            Project__c oldProject = oldMap != null ? oldMap.get(newProject.id) : null;
            if(vaildRecordTypeIdSet.contains(newProject.RecordTypeId) ){
                if(trigger.isDelete || ( oldProject == null && newProject.Projected_Deadline__c != null && newProject.ParentProject__c != null )
                    || (oldProject != null && ( newProject.Projected_Deadline__c != oldProject.Projected_Deadline__c || newProject.ParentProject__c != oldProject.ParentProject__c)) ){
                        processList.add(newProject);                   
                        parentProjectIdSet.add(newProject.ParentProject__c);
                }
                if(oldProject != null && oldProject.ParentProject__c != null && newProject.ParentProject__c != oldProject.ParentProject__c){
                    parentProjectIdSet.add(oldProject.ParentProject__c);
                }                    
            }            
        }
        
        system.debug('**** calculateProjectedDeadline(): processList - '+processList);
        system.debug('**** calculateProjectedDeadline(): parentProjectIdSet - '+parentProjectIdSet);
        
        if(parentProjectIdSet.isEmpty()){
            return;
        }
        
        List<Project__c> projectUpdateList = new List<Project__c>();
        Map<Id,Project__c> parentProjectMap = new Map<Id,Project__c>([SELECT Id, Projected_Deadline__c FROM Project__c WHERE Id IN :parentProjectIdSet]);
        AggregateResult[] aggregateList = [
            SELECT ParentProject__c, MAX(Projected_Deadline__c) maxDate FROM Project__c 
            WHERE ParentProject__c IN :parentProjectIdSet and Projected_Deadline__c != null 
            GROUP BY ParentProject__c
        ];
        
        system.debug('**** calculateProjectedDeadline(): parentProjectMap - '+parentProjectMap);
        system.debug('**** calculateProjectedDeadline(): aggregateList - '+aggregateList);
        
        for(AggregateResult ar :aggregateList){
            if(ar.get('ParentProject__c') != null && ar.get('maxDate') != null){
                Project__c parentProject = parentProjectMap.get((Id)ar.get('ParentProject__c'));
                if( parentProject.Projected_Deadline__c == null || (trigger.isDelete && (Date)ar.get('maxDate') != parentProject.Projected_Deadline__c) || (Date)ar.get('maxDate') > parentProject.Projected_Deadline__c ) {
                    parentProject.Projected_Deadline__c = (Date)ar.get('maxDate');
                    projectUpdateList.add(parentProject);
                }
            }
        }
        system.debug('**** calculateProjectedDeadline(): projectUpdateList - '+projectUpdateList);
        if(projectUpdateList.size() > 0){
            update projectUpdateList;
        }
        
    } // end of calculateProjectedDeadline()
}