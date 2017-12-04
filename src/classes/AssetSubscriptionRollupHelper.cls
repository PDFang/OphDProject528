/**
 * Created by mohandaas.rangaswamy on 12/1/2017.
 */

public class AssetSubscriptionRollupHelper {

    final Map<Id, Project__c> projectCache;

    public AssetSubscriptionRollupHelper(Set<Id> projectIds){

        Schema.DescribeSObjectResult projObjectResult = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> projRecordTypeInfosByName = projObjectResult.getRecordTypeInfosByName();

        Id psProjectPhaseSaasRecordTypeId = projRecordTypeInfosByName.get('PS Project Phase SaaS').getRecordTypeId();
        Id psProjectPhasePremiseRecordTypeId = projRecordTypeInfosByName.get('PS Project Phase Premise WFO').getRecordTypeId();

        Set<Id> psProjectPhaseRecordTypeIds = new Set<Id>{
                psProjectPhaseSaasRecordTypeId,
                psProjectPhasePremiseRecordTypeId
        };

        // project record type must be 'PS Project Phase SaaS' or 'PS Project Phase Premise WFO'
        projectCache = new Map<Id, Project__c>([
                Select Id, Contracted_NRR__c, Actual_NRR__c,
                        Contracted_MRR__c, Actual_MRR__c
                from Project__c
                where Id IN :projectIds and RecordTypeId in :psProjectPhaseRecordTypeIds
        ]);

        system.debug('**** execute(): ProjectRollupHelper - ' + projectCache);

    }

    // summarize and rollup subscription MRR's to related phase project
    public List<Project__c> rollupSubscriptionFinancials(){

        List<Project__c> phaseProjects = new List<Project__c>();

        if(projectCache.isEmpty()){
            return phaseProjects;
        }

        for (AggregateResult ar : [
                Select sum(Contracted_MRR__c) totalContractedMRR, sum(Actual_MRR__c) totalActualMRR,
                        Project_Phase__c
                from SBQQ__Subscription__c
                where Project_Phase__c IN :projectCache.keySet()
                group by Project_Phase__c
        ]){

            system.debug('**** rollupSubscriptionFinancials(): ar - ' + ar);

            Project__c project = new Project__c(
                    Id = (Id) ar.get('Project_Phase__c'),
                    Contracted_MRR__c = ar.get('totalContractedMRR') != null ? (Decimal) ar.get('totalContractedMRR') : 0,
                    Actual_MRR__c = ar.get('totalActualMRR') != null ? (Decimal) ar.get('totalActualMRR') : 0
            );

            Project__c projectOld = projectCache.get(project.Id);
            system.debug('**** rollupSubscriptionFinancials(): projectOld - ' + projectOld);

            if(project.Contracted_MRR__c != projectOld.Contracted_MRR__c
                    || project.Actual_MRR__c != projectOld.Actual_MRR__c)
            {
                system.debug('**** rollupSubscriptionFinancials(): one or more fields value have changed');
                phaseProjects.add(project);
            }
        }

        return phaseProjects;

    }

    // summarize and rollup asset NRR's to related phase project
    public List<Project__c> rollupAssetFinancials(){

        List<Project__c> phaseProjects = new List<Project__c>();

        if(projectCache.isEmpty()){
            return phaseProjects;
        }

        for (AggregateResult ar : [
                Select sum(Contracted_NRR__c) totalContractedNRR, sum(Actual_NRR__c) totalActualNRR,
                        Project_Phase__c
                from Asset
                where Project_Phase__c IN :projectCache.keySet()
                group by Project_Phase__c
        ]){

            system.debug('**** rollupAssetFinancials(): ar - ' + ar);

            Project__c project = new Project__c(
                    Id = (Id) ar.get('Project_Phase__c'),
                    Contracted_NRR__c = ar.get('totalContractedNRR') != null ? (Decimal) ar.get('totalContractedNRR') : 0,
                    Actual_NRR__c = ar.get('totalActualNRR') != null ? (Decimal) ar.get('totalActualNRR') : 0
            );

            Project__c projectOld = projectCache.get(project.Id);
            system.debug('**** rollupAssetFinancials(): projectOld - ' + projectOld);

            if(project.Contracted_NRR__c != projectOld.Contracted_NRR__c
                    || project.Actual_NRR__c != projectOld.Actual_NRR__c)
            {
                system.debug('**** rollupAssetFinancials(): one or more fields value have changed');
                phaseProjects.add(project);
            }
        }

        return phaseProjects;

    }


}