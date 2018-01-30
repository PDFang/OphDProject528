/**
 * Created by jeremy.sparrell on 1/30/2018.
 */

public class ProjectAssetAllocationTriggerHandler extends TriggerHandler{

    public override void beforeInsert(){
        AddParentProject();
    }

    private static void AddParentProject(){
        List<Project_Asset_Allocation__c> allocations = (List<Project_Asset_Allocation__c>)(trigger.new);
        Map<Id, Project_Asset_Allocation__c> oldAllocations = (Map<Id, Project_Asset_Allocation__c>)(trigger.oldMap);
        Map<Id, Id> phaseIds = new Map<Id, Id>();
        List<Project__c> parentProjects = new List<Project__c>();


        for(Project_Asset_Allocation__c allocation:allocations){
            if(allocation.Project__c != null && (allocation.ParentProjectId__c == null || allocation.Project__c != oldAllocations.get(allocation.Id).Project__c)){
                phaseIds.put(allocation.Project__c,null);
            }
        }

        if(!phaseIds.isEmpty()) {
            for (Project__c phaseProject : [SELECT Id, ParentProject__c FROM Project__c WHERE ID IN :phaseIds.keySet()]) {
                if(phaseProject.ParentProject__c != null) {
                    phaseIds.put(phaseProject.Id, phaseProject.ParentProject__c);
                }
            }

            for (Project_Asset_Allocation__c allocation : allocations) {
                allocation.ParentProjectId__c = phaseIds.get(allocation.Project__c);
            }
        }
    }
}