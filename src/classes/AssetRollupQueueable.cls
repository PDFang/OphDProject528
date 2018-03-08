/**
 * Created by mohandaas.rangaswamy on 11/30/2017.
 */

// summarize and rollup asset NRR's to related phase project
public class AssetRollupQueueable implements Queueable {

    public Set<Id> projectIds;
    private final set<id> parentProjectIds;
    // constructor
    public AssetRollupQueueable(Set<Id> assetIds) {

        system.debug('**** AssetRollupQueueable(): assetIds - ' + assetIds);

        projectIds = new Set<Id>();
        parentProjectIds = new set<Id>();

        Schema.DescribeSObjectResult projObjectResult = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> projRecordTypeInfosByName = projObjectResult.getRecordTypeInfosByName();

        Id psProjectPhaseSaasRecordTypeId = projRecordTypeInfosByName.get('PS Project Phase SaaS').getRecordTypeId();
        Id psProjectPhasePremiseRecordTypeId = projRecordTypeInfosByName.get('PS Project Phase Premise WFO').getRecordTypeId();
        Id psParentProjectSaaSId = projRecordTypeInfosByName.get('PS Parent Project - SaaS').getRecordTypeId();
        Id psParentProjectPremiseId = projRecordTypeInfosByName.get('PS Parent Project - Premise').getRecordTypeId();

        Set<Id> psProjectPhaseRecordTypeIds = new Set<Id>{
                psProjectPhaseSaasRecordTypeId,
                psProjectPhasePremiseRecordTypeId
        };

        Set<Id> parentProjectRecordTypeIds = new Set<Id>{
                psParentProjectSaaSId,
                psParentProjectPremiseId
        };


        for(Project_Asset_Allocation__c allocation : [
                Select Project__c, Asset__r.Parent_Project__c from Project_Asset_Allocation__c
                where Asset__c IN :assetIds and Project__r.RecordTypeId IN :psProjectPhaseRecordTypeIds
        ]){
            projectIds.add(allocation.Project__c);
            parentProjectIds.add(allocation.Asset__r.Parent_Project__c);
        }


        for(Asset a : [select Id, Parent_Project__c from Asset
                       where id in :assetIds and Parent_Project__r.RecordTypeId in: parentProjectRecordTypeIds]){

            parentProjectIds.add(a.Parent_Project__c);
        }


        system.debug('**** AssetRollupQueueable(): projectIds - ' + projectIds);
        system.debug('**** AssetRollupQueueable(): parentProjectIds - ' + parentProjectIds);

    }

    public AssetRollupQueueable(){}

    // interface method
    public void execute(QueueableContext context){

        /*if(projectIds.isEmpty()){
            return;
        }*/

        AssetSubscriptionRollupHelper helper = new AssetSubscriptionRollupHelper(projectIds);

        List<Project__c> projects = helper.rollupAssetFinancials();
        projects.addAll(helper.rollupCancelledQuantity(parentProjectIds));

        if(projects.size() > 0){

            Database.SaveResult[] srList = Database.update(projects, false);
            for(Integer i=0; i < srList.size(); i++){
                if(!srList[i].isSuccess()){
                    Database.Error[] errors = srList[i].getErrors();
                    if(errors.size() > 0){
                        system.debug('**** execute(): save error - ' + errors.get(0));
                        system.debug('**** execute(): record id - ' + projects[i].Id);
                    }
                }
            }

        }

    }

}