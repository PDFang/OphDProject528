/**
 * Created by jeremy.sparrell on 1/30/2018.
 */

public class ProjectAssetAllocationTriggerHandler extends TriggerHandler{

    public override void beforeInsert(){
        AddParentProject();
    }

    public override void beforeDelete(){
        CheckTimeBeofreDelete();
    }

    public override void afterDelete(){
        rollupNRRToPhase();
    }

    static set<string> closedProjectStatus = new set<String>{
            'Closed',
            'Cancelled',
            'Suspended'
    };

    @TestVisible
    private static String assetRollupQueueableJobID;


    private static void CheckTimeBeofreDelete(){
        List<Project_Asset_Allocation__c> allocations = (List<Project_Asset_Allocation__c>)(trigger.old);
        Set<Id> allocationIds = new Set<Id>();
        List<WorkIt2__Timing__c> timingList = new List<WorkIt2__Timing__c>();

        if(allocations.size() > 0){
            for(Project_Asset_Allocation__c allocation : allocations){
                allocationIds.add(allocation.Id);
            }
        }

        if(allocationIds.size() > 0) {
            timingList = [
                    SELECT Id, Project_Asset_Allocation__c
                    from WorkIt2__Timing__c
                    where Project_Asset_Allocation__c IN :allocationIds
            ];
        }

        if(timingList.size() > 0){
            for(Project_Asset_Allocation__c allocation : allocations){
                allocation.addError('Asset Allocation can not be deleted as there are time enteries on the allocation. Please update the allocation quantity to Zero instead. ');
            }
        }
    }

    private static void AddParentProject(){
        List<Project_Asset_Allocation__c> allocations = (List<Project_Asset_Allocation__c>)(trigger.new);
        Map<Id, Project_Asset_Allocation__c> oldAllocations = (Map<Id, Project_Asset_Allocation__c>)(trigger.oldMap);
        Map<Id, Id> phaseIds = new Map<Id, Id>();
        List<Project__c> parentProjects = new List<Project__c>();
        set<Id> closedProjectIds = new set<Id>();
        set<Id> assetIds = new set<Id>();


        for(Project_Asset_Allocation__c allocation:allocations){
            if(allocation.Project__c != null){
                phaseIds.put(allocation.Project__c,null);
            }
        }

        if(!phaseIds.isEmpty()) {
            for (Project__c phaseProject : [SELECT Id, ParentProject__c, Phase_Status__c, ActualProjectGoLiveDate__c FROM Project__c WHERE ID IN :phaseIds.keySet()]) {
                if(phaseProject.ParentProject__c != null) {
                    phaseIds.put(phaseProject.Id, phaseProject.ParentProject__c);
                }
                if(closedProjectStatus.contains(phaseProject.Phase_Status__c) || phaseProject.ActualProjectGoLiveDate__c != null){
                    closedProjectIds.add(phaseProject.Id);
                }
            }

            for (Project_Asset_Allocation__c allocation : allocations) {
                allocation.ParentProjectId__c = phaseIds.get(allocation.Project__c);
                if(closedProjectIds.contains(allocation.Project__c)){
                        allocation.Implemented__c = true;
                        allocation.Phase_Implemented_Quantity__c = allocation.Quantity_Allocation__c;
                        allocation.Phase_Implemented__c = allocation.Percent_Allocation__c;
                        assetIds.add(allocation.Asset__c);
                }
            }
        }

        if(!assetIds.isEmpty() && !system.isFuture()){
            UpdateAsset(assetIds);
        }

    }

    @Future
    public static void UpdateAsset(set<Id> assetIds){
            ProjectTriggerHandler.updateAssetFullyImplemented(assetIds);
    }

    private static void rollupNRRToPhase(){
        List<Project_Asset_Allocation__c> lstallocations = (List<Project_Asset_Allocation__c>)(trigger.old);
        set<id> projectIdsets = new set<Id>();
        for(Project_Asset_Allocation__c allocation : lstallocations){
            if(allocation.Project__c != null){
                projectIdsets.add(allocation.Project__c);
            }
        }

        System.debug('rollupNRRToPhase => projectIdsets ==>' + projectIdsets );

        if(projectIdsets.size() > 0 && assetRollupQueueableJobID == null && RollupUtility.isRollupEnabled){
            if(limits.getQueueableJobs() < limits.getLimitQueueableJobs()) {
                AssetRollupQueueable queueable = new AssetRollupQueueable();
                queueable.projectIds = projectIdsets;
                assetRollupQueueableJobID = System.enqueueJob(queueable);
                system.debug('**** rollupNRRToPhase(): assetRollupQueueableJobID - ' + assetRollupQueueableJobID);
            }
        }

    }

}

