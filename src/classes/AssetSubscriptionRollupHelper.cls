/**
 * Created by mohandaas.rangaswamy on 12/1/2017.
 */

public class AssetSubscriptionRollupHelper {

    final Map<Id, Project__c> projectCache;

    public AssetSubscriptionRollupHelper(Set<Id> projectIds){

        // project record type must be 'PS Project Phase SaaS' or 'PS Project Phase Premise WFO'
        projectCache = new Map<Id, Project__c>([
                Select Id, Contracted_NRR__c, Actual_NRR__c,
                        Contracted_MRR__c, Actual_MRR__c,On_Hold_NRR__c,On_Hold_MRR__c,
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
        Map<id, Project__c> mapPrhaseProjects = new map<Id, Project__c>();
        if(projectCache.isEmpty()){
            return phaseProjects;
        }

        for (AggregateResult ar : [
                Select sum(Allocated_MRR__c) totalAllocateddMRR, sum(Delivered_MRR__c) totalDeliveredMRR,
                        sum(Logged_Hours__c) loggedHours, sum(Hours_Allocated__c) allocatedHours, sum(On_Hold_MRR__c) totalOnHoldMRR, Project__c
                from Project_Subscription_Allocation__c
                where Project__c IN :projectCache.keySet()
                group by Project__c
        ]){

            system.debug('**** rollupSubscriptionFinancials(): ar - ' + ar);

            Project__c project = new Project__c(
                    Id = (Id) ar.get('Project__c'),
                    Contracted_MRR__c = ar.get('totalAllocateddMRR') != null ? (Decimal) ar.get('totalAllocateddMRR') : 0,
                    Actual_MRR__c = ar.get('totalDeliveredMRR') != null ? (Decimal) ar.get('totalDeliveredMRR') : 0,
                    Subscription_Allocated_Hours__c = ar.get('allocatedHours') != null ? (Decimal) ar.get('allocatedHours') : 0,
                    Subscription_Logged_Hours__c = ar.get('loggedHours') != null ? (Decimal) ar.get('loggedHours') : 0,
                    On_Hold_MRR__c = ar.get('totalOnHoldMRR') != null ? (Decimal) ar.get('totalOnHoldMRR') : 0
            );

            Project__c projectOld = projectCache.get(project.Id);
            system.debug('**** rollupSubscriptionFinancials(): projectOld - ' + projectOld);

            if(project.Contracted_MRR__c != projectOld.Contracted_MRR__c
                    || project.Actual_MRR__c != projectOld.Actual_MRR__c
                    || project.Subscription_Allocated_Hours__c != projectOld.Subscription_Allocated_Hours__c
                    || project.Subscription_Logged_Hours__c != projectOld.Subscription_Logged_Hours__c
		            || project.On_Hold_MRR__c != projectOld.On_Hold_MRR__c)
            {
                system.debug('**** rollupSubscriptionFinancials(): one or more fields value have changed');
                phaseProjects.add(project);
            }
            mapPrhaseProjects.put(project.Id, project);
        }

        for(Project__c proj : projectCache.values()){
            if(!mapPrhaseProjects.containsKey(proj.Id)){
                if(proj.Contracted_MRR__c != 0
                        || proj.Actual_MRR__c != 0
                        || proj.Asset_Allocated_Hours__c != 0
                        || proj.Asset_Logged_Hours__c != 0
                        || proj.On_Hold_MRR__c != 0){
                    phaseProjects.add(new Project__c( Id = proj.Id, Contracted_MRR__c = 0,Actual_MRR__c = 0, Asset_Allocated_Hours__c = 0, Asset_Logged_Hours__c =0, On_Hold_MRR__c = 0));
                }
            }
        }

        return phaseProjects;

    }

    // summarize and rollup asset NRR's to related phase project
    public List<Project__c> rollupAssetFinancials(){

        List<Project__c> phaseProjects = new List<Project__c>();
        Map<id, Project__c> mapPrhaseProjects = new map<Id, Project__c>();
        if(projectCache.isEmpty()){
            return phaseProjects;
        }

        for (AggregateResult ar : [
                Select sum(Allocated_NRR__c) totalContractedNRR, sum(Delivered_NRR__c) totalDeliveredNRR,
                        sum(Logged_Hours__c) loggedHours, sum(Hours_Allocated__c) allocatedHours, sum(On_Hold_NRR__c) totalOnHoldNRR, Project__c
                from Project_Asset_Allocation__c
                where Project__c IN :projectCache.keySet()
                group by Project__c
        ]){

            system.debug('**** rollupAssetFinancials(): ar - ' + ar);

            Project__c project = new Project__c(
                    Id = (Id) ar.get('Project__c'),
                    Contracted_NRR__c = ar.get('totalContractedNRR') != null ? (Decimal) ar.get('totalContractedNRR') : 0,
                    Actual_NRR__c = ar.get('totalDeliveredNRR') != null ? (Decimal) ar.get('totalDeliveredNRR') : 0,
                    Asset_Allocated_Hours__c = ar.get('allocatedHours') != null ? (Decimal) ar.get('allocatedHours') : 0,
                    Asset_Logged_Hours__c = ar.get('loggedHours') != null ? (Decimal) ar.get('loggedHours') : 0,
                    On_Hold_NRR__c = ar.get('totalOnHoldNRR') != null ? (Decimal) ar.get('totalOnHoldNRR') : 0
            );

            Project__c projectOld = projectCache.get(project.Id);
            system.debug('**** rollupAssetFinancials(): projectNew - ' + project);

            if(project.Contracted_NRR__c != projectOld.Contracted_NRR__c
                    || project.Actual_NRR__c != projectOld.Actual_NRR__c
                    || project.Asset_Allocated_Hours__c != projectOld.Asset_Allocated_Hours__c
                    || project.Asset_Logged_Hours__c != projectOld.Asset_Logged_Hours__c
                    || project.On_Hold_NRR__c != projectOld.On_Hold_NRR__c)
            {
                system.debug('**** rollupAssetFinancials(): one or more fields value have changed');
                phaseProjects.add(project);
            }

            mapPrhaseProjects.put(project.Id, project);

        }

        for(Project__c proj : projectCache.values()){
            if(!mapPrhaseProjects.containsKey(proj.Id)){
                if(proj.Contracted_NRR__c != 0
                    || proj.Actual_NRR__c != 0
                    || proj.Asset_Allocated_Hours__c != 0
                    || proj.Asset_Logged_Hours__c != 0
                    || proj.On_Hold_NRR__c != 0){
                    phaseProjects.add(new Project__c( Id = proj.Id, Contracted_NRR__c = 0,Actual_NRR__c = 0, Asset_Allocated_Hours__c = 0, Asset_Logged_Hours__c =0, On_Hold_NRR__c = 0));
                }
            }
        }

        return phaseProjects;

    }

    // summarize and rollup asset NRR's to related phase project
    public List<Project__c> rollupCancelledQuantity(set<id> parenIds){
        List<Project__c> parentProjects = new List<Project__c>();
        for( AggregateResult ar : [
                    Select sum(Cancelled_NRR__c) totalCancelledNRR,sum(Total_Contracted_NRR__c) totalContractedNRR, Parent_Project__c
                    from Asset
                    where Parent_Project__c in : parenIds
                    group by Parent_Project__c]){

            parentProjects.add(
                    new Project__c(Id = (Id)ar.get('Parent_Project__c'),
                                   Cancelled_NRR__c = ar.get('totalCancelledNRR') != null ? (Decimal) ar.get('totalCancelledNRR') : 0,
		                           Total_Contracted_NRR__c = ar.get('totalContractedNRR') != null ? (Decimal) ar.get('totalContractedNRR') : 0
                    )
            );
        }


        return parentProjects;

    }

	// summarize and rollup cancelled MRR's to related phase project
	public List<Project__c> rollupSubsCancelledQuantity(set<id> parenIds){
		List<Project__c> parentProjects = new List<Project__c>();

		for( AggregateResult ar : [
				Select sum(Cancelled_MRR__c) totalCancelledMRR,sum(Subscription__r.Total_Contracted_MRR__c) totalContractedMRR, ParentProject__c
				from SubscriptionReplica__c
				where ParentProject__c in : parenIds
				group by ParentProject__c]){

			parentProjects.add(
					new Project__c(Id = (Id)ar.get('ParentProject__c'),
							Cancelled_MRR__c = ar.get('totalCancelledMRR') != null ? (Decimal) ar.get('totalCancelledMRR') : 0,
							Total_Contracted_MRR__c = ar.get('totalContractedMRR') != null ? (Decimal) ar.get('totalContractedMRR') : 0
					)
			);
		}

		return parentProjects;
	}


}