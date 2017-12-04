/**
 * Created by mohandaas.rangaswamy on 11/30/2017.
 */

// summarize and rollup asset NRR's to related phase project
public class AssetRollupQueueable implements Queueable {

    final Set<Id> projectIds;

    // constructor
    public AssetRollupQueueable(Set<Id> assetIds) {

        system.debug('**** AssetRollupQueueable(): assetIds - ' + assetIds);

        projectIds = new Set<Id>();

        Schema.DescribeSObjectResult projObjectResult = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> projRecordTypeInfosByName = projObjectResult.getRecordTypeInfosByName();

        Id psProjectPhaseSaasRecordTypeId = projRecordTypeInfosByName.get('PS Project Phase SaaS').getRecordTypeId();
        Id psProjectPhasePremiseRecordTypeId = projRecordTypeInfosByName.get('PS Project Phase Premise WFO').getRecordTypeId();

        Set<Id> psProjectPhaseRecordTypeIds = new Set<Id>{
                psProjectPhaseSaasRecordTypeId,
                psProjectPhasePremiseRecordTypeId
        };

        for(Project_Asset_Allocation__c allocation : [
                Select Project__c from Project_Asset_Allocation__c
                where Asset__c IN :assetIds and Project__r.RecordTypeId IN :psProjectPhaseRecordTypeIds
        ]){
            projectIds.add(allocation.Project__c);
        }

        system.debug('**** AssetRollupQueueable(): projectIds - ' + projectIds);

    }

    // interface method
    public void execute(QueueableContext context){

        if(projectIds.isEmpty()){
            return;
        }

        AssetSubscriptionRollupHelper helper = new AssetSubscriptionRollupHelper(projectIds);

        List<Project__c> phaseProjects = helper.rollupAssetFinancials();

        if(phaseProjects.size() > 0){

            Database.SaveResult[] srList = Database.update(phaseProjects, false);
            for(Integer i=0; i < srList.size(); i++){
                if(!srList[i].isSuccess()){
                    Database.Error[] errors = srList[i].getErrors();
                    if(errors.size() > 0){
                        system.debug('**** execute(): save error - ' + errors.get(0));
                        system.debug('**** execute(): record id - ' + phaseProjects[i].Id);
                    }
                }
            }

        }

    }

}