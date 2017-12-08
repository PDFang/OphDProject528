// this job is enqueued from ProjectTriggerHandler class
public class ProjectRollupQueueable implements Queueable{

    final Set<Id> parentProjectIds;
    final Id psProjectParentSaaSRecordTypeId, psProjectParentPremiseRecordTypeId;
    final Id psProjectPhaseSaasRecordTypeId, psProjectPhasePremiseRecordTypeId;

    final Set<Id> psProjectPhaseRecordTypeIds;
    final Set<Id> psProjectParentRecordTypeIds;

    @testVisible
    private static Boolean doChainJob = true;

    // constructor
    public ProjectRollupQueueable(Set<Id> parentProjectIds){

        this.parentProjectIds = parentProjectIds;
        system.debug('**** ProjectRollupQueueable(): parentProjectIds - ' + parentProjectIds);

        Schema.DescribeSObjectResult projObjectResult = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> projRecordTypeInfosByName = projObjectResult.getRecordTypeInfosByName();

        psProjectParentSaaSRecordTypeId = projRecordTypeInfosByName.get('PS Parent Project - SaaS').getRecordTypeId();
        psProjectParentPremiseRecordTypeId = projRecordTypeInfosByName.get('PS Parent Project - Premise').getRecordTypeId();

        psProjectPhaseSaasRecordTypeId = projRecordTypeInfosByName.get('PS Project Phase SaaS').getRecordTypeId();
        psProjectPhasePremiseRecordTypeId = projRecordTypeInfosByName.get('PS Project Phase Premise WFO').getRecordTypeId();

        psProjectParentRecordTypeIds = new Set<Id>{
                psProjectParentSaaSRecordTypeId,
                psProjectParentPremiseRecordTypeId
        };

        psProjectPhaseRecordTypeIds = new Set<Id>{
                psProjectPhaseSaasRecordTypeId,
                psProjectPhasePremiseRecordTypeId
        };

    }

    // Queueable interface method
    // enqueue OpportunityRollupQueueable job
    public void execute(QueueableContext context){

        try {

            // parent project record type must be 'PS Parent Project - SaaS' or 'PS Project Phase Premise WFO'
            Map<Id, Project__c> projectCache = new Map<Id, Project__c>([
                    Select Id, RecordTypeId, Original_Forecasted_Initial_Go_Live_Date__c, Estimated_Project_Initial_Go_Live_Date__c,
                            Estimated_Project_End__c, Times_All_Phases_Go_Live_Date_Changed__c, Opportunity__c,
                            Actual_Initial_Phase_Go_Live__c, Actual_Latest_Go_Live_Date__c, Number_of_Open_Phases__c,
                            Contracted_NRR__c, Actual_NRR__c, Contracted_MRR__c, Actual_MRR__c
                    from Project__c
                    where Id IN :parentProjectIds and RecordTypeId = :psProjectParentRecordTypeIds
            ]);

            system.debug('**** execute(): projectCache - ' + projectCache);

            if (projectCache.isEmpty()) {
                return;
            }

            Map<Id, Project__c> parentProjects = new Map<Id, Project__c>();

            // roll-up MRR's and NRR's
            rollupFinancials(projectCache, parentProjects);
            // roll-up Go Live dates
            rollupGoLiveDates(projectCache, parentProjects);

            Set<Id> opportunityIds = new Set<Id>();

            // update PS Parent projects
            if (parentProjects.size() > 0) {

                List<Project__c> updateProjects = parentProjects.values();

                Set<Id> updatedIds = new Set<Id>();

                Database.SaveResult[] srList = Database.update(updateProjects, false);
                for(Integer i=0; i < srList.size(); i++){
                    if(srList[i].isSuccess()){
                        updatedIds.add(srList[i].getId());
                    } else{
                        Database.Error[] errors = srList[i].getErrors();
                        if(errors.size() > 0){
                            system.debug('**** execute(): save error - ' + errors.get(0));
                            system.debug('**** execute(): record id - ' + updateProjects[i].Id);
                        }
                    }
                }

                system.debug('**** execute(): updatedIds - ' + updatedIds);

                // retrieve related 'PM-Standard' or 'Qualified Opportunity' record type opportunities
                for(Id projectId : updatedIds){
                    Id opportunityId = projectCache.get(projectId).Opportunity__c;
                    if (opportunityId != null) {
                        opportunityIds.add(opportunityId);
                    }
                }

            }

            system.debug('**** execute(): opportunityIds - ' + opportunityIds);

            // enqueue OpportunityRollupQueueable job to roll-up PS Parent SaaS and Premise project values to related opportunity
            if (opportunityIds.size() > 0 && doChainJob) {
                Id opportunityRollupQueueableJobID = System.enqueueJob(new OpportunityRollupQueueable(opportunityIds));
                system.debug('**** execute(): opportunityRollupQueueableJobID - ' + opportunityRollupQueueableJobID);
            }

        } catch (Exception ex){

            List<Id> projectIds = new List<Id>(parentProjectIds);
            inContactBaseClass.SendErrorEmail(ex, String.join(projectIds, ', '));

        }

    }

    // roll-up PS Phase SaaS project Go Live Date Changes to related Parent project
    private void rollupGoLiveDates(Map<Id, Project__c> projectCache, Map<Id, Project__c> parentProjects){

        Set<Id> saasProjectIds = new Set<Id>();
        for(Project__c project : projectCache.values()){
            if(project.RecordTypeId == psProjectParentSaaSRecordTypeId)
                saasProjectIds.add(project.Id);
        }

        system.debug('**** rollupGoLiveDates(): saasProjectIds - ' + saasProjectIds);

        if(saasProjectIds.isEmpty()){
            return;
        }

        // aggregate PS Phase SaaS projects
        for (AggregateResult ar : [
                Select min(Original_Phase_Forecasted_Go_Live_Date__c) minForecastedPhaseGoLiveDate, sum(Times_Go_Live_Date_Changed__c) noOfTimesPhaseGoLiveDateChanged,
                        min(EstimatedProjectGoLiveDate__c) minEstimatedPhaseGoLiveDate, max(EstimatedProjectGoLiveDate__c) maxEstimatedPhaseGoLiveDate,
                        min(ActualProjectGoLiveDate__c) minActualPhaseGoLiveDate, max(ActualProjectGoLiveDate__c) maxActualPhaseGoLiveDate, sum(Is_Phase_Open__c) noOfOpenPhases,
                        ParentProject__c
                from Project__c
                where ParentProject__c IN :saasProjectIds and RecordTypeId = :psProjectPhaseSaasRecordTypeId
                group by ParentProject__c
        ]) {

            system.debug('**** rollupGoLiveDates(): ar - ' + ar);

            Id projectId = (Id) ar.get('ParentProject__c');

            Project__c parentProject = parentProjects.get(projectId);

            if(parentProject == null){
                parentProject = new Project__c(
                        Id = projectId
                );
            }

            parentProject.Original_Forecasted_Initial_Go_Live_Date__c = ar.get('minForecastedPhaseGoLiveDate') != null ? (Date) ar.get('minForecastedPhaseGoLiveDate') : null;
            parentProject.Estimated_Project_Initial_Go_Live_Date__c = ar.get('minEstimatedPhaseGoLiveDate') != null ? (Date) ar.get('minEstimatedPhaseGoLiveDate') : null;
            parentProject.Estimated_Project_End__c = ar.get('maxEstimatedPhaseGoLiveDate') != null ? (Date) ar.get('maxEstimatedPhaseGoLiveDate') : null;
            parentProject.Times_All_Phases_Go_Live_Date_Changed__c = ar.get('noOfTimesPhaseGoLiveDateChanged') != null ? (Decimal) ar.get('noOfTimesPhaseGoLiveDateChanged') : null;
            parentProject.Actual_Initial_Phase_Go_Live__c = ar.get('minActualPhaseGoLiveDate') != null ? (Date) ar.get('minActualPhaseGoLiveDate') : null;
            parentProject.Actual_Latest_Go_Live_Date__c = ar.get('maxActualPhaseGoLiveDate') != null ? (Date) ar.get('maxActualPhaseGoLiveDate') : null;
            parentProject.Number_of_Open_Phases__c = (Decimal)ar.get('noOfOpenPhases');

            system.debug('**** rollupGoLiveDates(): parentProject - ' + parentProject);

            Project__c parentProjectOld = projectCache.get(parentProject.Id);
            system.debug('**** rollupGoLiveDates(): parentProjectOld - ' + parentProjectOld);

            if(parentProject.Original_Forecasted_Initial_Go_Live_Date__c != parentProjectOld.Original_Forecasted_Initial_Go_Live_Date__c
                    || parentProject.Estimated_Project_Initial_Go_Live_Date__c != parentProjectOld.Estimated_Project_Initial_Go_Live_Date__c
                    || parentProject.Estimated_Project_End__c != parentProjectOld.Estimated_Project_End__c
                    || parentProject.Times_All_Phases_Go_Live_Date_Changed__c != parentProjectOld.Times_All_Phases_Go_Live_Date_Changed__c
                    || parentProject.Actual_Initial_Phase_Go_Live__c != parentProjectOld.Actual_Initial_Phase_Go_Live__c
                    || parentProject.Actual_Latest_Go_Live_Date__c != parentProjectOld.Actual_Latest_Go_Live_Date__c
                    || parentProject.Number_of_Open_Phases__c != parentProjectOld.Number_of_Open_Phases__c)
            {
                system.debug('**** rollupGoLiveDates(): one or more fields value have changed');
                parentProjects.put(parentProject.Id, parentProject);
            }

        }

    }


    // roll-up PS Parent SaaS and Premise project MRR's and NRR's to related Parent project
    private void rollupFinancials(Map<Id, Project__c> projectCache, Map<Id, Project__c> parentProjects){


        for (AggregateResult ar : [
                Select sum(Actual_NRR__c) totalActualNRR, sum(Contracted_NRR__c) totalContractedNRR,
                        sum(Actual_MRR__c) totalActualMRR, sum(Contracted_MRR__c) totalContractedMRR, ParentProject__c
                from Project__c
                where ParentProject__c IN :projectCache.keySet() and RecordTypeId = :psProjectPhaseRecordTypeIds
                group by ParentProject__c
        ]) {

            system.debug('**** rollupFinancials(): ar - ' + ar);

            Id projectId = (Id) ar.get('ParentProject__c');

            Project__c parentProject = parentProjects.get(projectId);

            if(parentProject == null){
                parentProject = new Project__c(
                        Id = projectId
                );
            }

            parentProject.Actual_NRR__c = ar.get('totalActualNRR') != null ? (Decimal)ar.get('totalActualNRR') : 0;
            parentProject.Contracted_NRR__c = ar.get('totalContractedNRR') != null ? (Decimal)ar.get('totalContractedNRR') : 0;
            parentProject.Actual_MRR__c = ar.get('totalActualMRR') != null ? (Decimal)ar.get('totalActualMRR') : 0;
            parentProject.Contracted_MRR__c = ar.get('totalContractedMRR') != null ? (Decimal)ar.get('totalContractedMRR') : 0;

            system.debug('**** rollupFinancials(): parentProject - ' + parentProject);

            Project__c parentProjectOld = projectCache.get(parentProject.Id);
            system.debug('**** rollupFinancials(): parentProjectOld - ' + parentProjectOld);

            if(parentProject.Actual_NRR__c != parentProjectOld.Actual_NRR__c
                    || parentProject.Contracted_NRR__c != parentProjectOld.Contracted_NRR__c
                    || parentProject.Actual_MRR__c != parentProjectOld.Actual_MRR__c
                    || parentProject.Contracted_MRR__c != parentProjectOld.Contracted_MRR__c)
            {
                system.debug('**** rollupFinancials(): one or more fields value have changed');
                parentProjects.put(parentProject.Id, parentProject);
            }

        }

    }

}