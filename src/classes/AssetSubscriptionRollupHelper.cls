/**
 * Created by mohandaas.rangaswamy on 12/1/2017.
 */

public class AssetSubscriptionRollupHelper {

    final Map<Id, Project__c> projectCache;

    public AssetSubscriptionRollupHelper(Set<Id> projectIds){

        // project record type must be 'PS Project Phase SaaS' or 'PS Project Phase Premise WFO'
        projectCache = new Map<Id, Project__c>([
                Select Id, Contracted_NRR__c, Actual_NRR__c,
                        Contracted_MRR__c, Actual_MRR__c,
                        Asset_Logged_Hours__c, Subscription_Logged_Hours__c,
                        Asset_Allocated_Hours__c, Subscription_Allocated_Hours__c
                from Project__c
                where Id IN :projectIds
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
                Select sum(Subscription__r.Contracted_MRR__c) totalContractedMRR, sum(Subscription__r.Actual_MRR__c) totalActualMRR,
                        sum(Logged_Hours__c) loggedHours, sum(Hours_Allocated__c) allocatedHours, Project__c
                from Project_Subscription_Allocation__c
                where Project__c IN :projectCache.keySet()
                group by Project__c
        ]){

            system.debug('**** rollupSubscriptionFinancials(): ar - ' + ar);

            Project__c project = new Project__c(
                    Id = (Id) ar.get('Project__c'),
                    Contracted_MRR__c = ar.get('totalContractedMRR') != null ? (Decimal) ar.get('totalContractedMRR') : 0,
                    Actual_MRR__c = ar.get('totalActualMRR') != null ? (Decimal) ar.get('totalActualMRR') : 0,
                    Subscription_Allocated_Hours__c = ar.get('allocatedHours') != null ? (Decimal) ar.get('allocatedHours') : 0,
                    Subscription_Logged_Hours__c = ar.get('loggedHours') != null ? (Decimal) ar.get('loggedHours') : 0
            );

            Project__c projectOld = projectCache.get(project.Id);
            system.debug('**** rollupSubscriptionFinancials(): projectOld - ' + projectOld);

            if(project.Contracted_MRR__c != projectOld.Contracted_MRR__c
                    || project.Actual_MRR__c != projectOld.Actual_MRR__c
                    || project.Subscription_Allocated_Hours__c != projectOld.Subscription_Allocated_Hours__c
                    || project.Subscription_Logged_Hours__c != projectOld.Subscription_Logged_Hours__c)
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
                Select sum(Asset__r.Contracted_NRR__c) totalContractedNRR, sum(Asset__r.Actual_NRR__c) totalActualNRR,
                        sum(Logged_Hours__c) loggedHours, sum(Hours_Allocated__c) allocatedHours, Project__c
                from Project_Asset_Allocation__c
                where Project__c IN :projectCache.keySet()
                group by Project__c
        ]){

            system.debug('**** rollupAssetFinancials(): ar - ' + ar);

            Project__c project = new Project__c(
                    Id = (Id) ar.get('Project__c'),
                    Contracted_NRR__c = ar.get('totalContractedNRR') != null ? (Decimal) ar.get('totalContractedNRR') : 0,
                    Actual_NRR__c = ar.get('totalActualNRR') != null ? (Decimal) ar.get('totalActualNRR') : 0,
                    Asset_Allocated_Hours__c = ar.get('allocatedHours') != null ? (Decimal) ar.get('allocatedHours') : 0,
                    Asset_Logged_Hours__c = ar.get('loggedHours') != null ? (Decimal) ar.get('loggedHours') : 0
            );

            Project__c projectOld = projectCache.get(project.Id);
            system.debug('**** rollupAssetFinancials(): projectNew - ' + project);

            if(project.Contracted_NRR__c != projectOld.Contracted_NRR__c
                    || project.Actual_NRR__c != projectOld.Actual_NRR__c
                    || project.Asset_Allocated_Hours__c != projectOld.Asset_Allocated_Hours__c
                    || project.Asset_Logged_Hours__c != projectOld.Asset_Logged_Hours__c)
            {
                system.debug('**** rollupAssetFinancials(): one or more fields value have changed');
                phaseProjects.add(project);
            }
        }

        return phaseProjects;

    }


}