/**
 * Created by jeremy.sparrell on 1/29/2018.
 */

public class ProjSubscriptionAllocationTriggerHandler extends TriggerHandler  {

    public override void beforeInsert(){
        AddParentProject();
    }

    public override void beforeDelete(){
        CheckTimeBeofreDelete();
    }

    private static void CheckTimeBeofreDelete(){
        List<Project_Subscription_Allocation__c> allocations = (List<Project_Subscription_Allocation__c>)(trigger.old);
        Set<Id> allocationIds = new Set<Id>();
        List<WorkIt2__Timing__c> timingList = new List<WorkIt2__Timing__c>();

        if(allocations.size() > 0){
            for(Project_Subscription_Allocation__c allocation : allocations){
                allocationIds.add(allocation.Id);
            }
        }

        if(allocationIds.size() > 0) {
            timingList = [
                    SELECT Id, Project_Subscription_Allocation__c
                    from WorkIt2__Timing__c
                    where Project_Subscription_Allocation__c IN :allocationIds
            ];
        }

        if(timingList.size() > 0){
            for(Project_Subscription_Allocation__c allocation : allocations){
                allocation.addError('Subscription Allocation can not be deleted as there are time enteries on the allocation. ' +
                        'Please change the status field');
            }
        }
    }

    private static void AddParentProject(){
        List<Project_Subscription_Allocation__c> allocations = (List<Project_Subscription_Allocation__c>)(trigger.new);
        Map<Id, Project_Subscription_Allocation__c> oldAllocations = (Map<Id, Project_Subscription_Allocation__c>)(trigger.oldMap);
        Map<Id, Id> phaseIds = new Map<Id, Id>();
        List<Project__c> parentProjects = new List<Project__c>();


        for(Project_Subscription_Allocation__c allocation:allocations){
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

            for (Project_Subscription_Allocation__c allocation : allocations) {
                allocation.ParentProjectId__c = phaseIds.get(allocation.Project__c);
            }
        }
    }
}