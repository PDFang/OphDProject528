// this job is enqueued from ProjectTriggerHandler class
public class ProjectRollupQueueable implements Queueable{

    final Set<Id> parentProjectIds;
    final Id psProjectParentSaaSRecordTypeId;
    final Id psProjectPhaseSaasRecordTypeId;

    // constructor
    public ProjectRollupQueueable(Set<Id> parentProjectIds){

        this.parentProjectIds = parentProjectIds;
        system.debug('**** ProjectRollupQueueable(): parentProjectIds - ' + parentProjectIds);

        Schema.DescribeSObjectResult projObjectResult = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> projRecordTypeInfosByName = projObjectResult.getRecordTypeInfosByName();

        psProjectParentSaaSRecordTypeId = projRecordTypeInfosByName.get('PS Parent Project - SaaS').getRecordTypeId();
        psProjectPhaseSaasRecordTypeId = projRecordTypeInfosByName.get('PS Project Phase SaaS').getRecordTypeId();

    }

    // Queueable interface method
    // roll-up PS Phase SaaS project Go Live Date Changes to PS Parent SaaS project
    // enqueue OpportunityRollupQueueable job
    public void execute(QueueableContext context){

        try {

            // parent project record type must be 'PS Parent Project - SaaS'
            Map<Id, Project__c> projectMap = new Map<Id, Project__c>([
                    Select Id, Original_Forecasted_Initial_Go_Live_Date__c, Estimated_Project_Initial_Go_Live_Date__c,
                            Estimated_Project_End__c, Times_All_Phases_Go_Live_Date_Changed__c, Opportunity__c,
                            Actual_Initial_Phase_Go_Live__c, Actual_Latest_Go_Live_Date__c, Number_of_Open_Phases__c
                    from Project__c
                    where Id IN :parentProjectIds and RecordTypeId = :psProjectParentSaaSRecordTypeId
            ]);

            system.debug('**** execute(): projectMap - ' + projectMap);

            if (projectMap.isEmpty()) {
                return;
            }

            List<Project__c> parentProjects = new List<Project__c>();

            // aggregate PS Phase SaaS projects
            for (AggregateResult ar : [
                    Select min(Original_Phase_Forecasted_Go_Live_Date__c) minForecastedPhaseGoLiveDate, sum(Times_Go_Live_Date_Changed__c) noOfTimesPhaseGoLiveDateChanged,
                            min(EstimatedProjectGoLiveDate__c) minEstimatedPhaseGoLiveDate, max(EstimatedProjectGoLiveDate__c) maxEstimatedPhaseGoLiveDate,
                            min(ActualProjectGoLiveDate__c) minActualPhaseGoLiveDate, max(ActualProjectGoLiveDate__c) maxActualPhaseGoLiveDate, sum(Is_Phase_Open__c) noOfOpenPhases,
                            max(Opportunity__c) opportunityId, ParentProject__c
                    from Project__c
                    where ParentProject__c IN :projectMap.keySet() and RecordTypeId = :psProjectPhaseSaasRecordTypeId
                    group by ParentProject__c
            ]) {

                system.debug('**** execute(): ar - ' + ar);

                Project__c parentProject = new Project__c(
                        Id = (Id) ar.get('ParentProject__c'),
                        Original_Forecasted_Initial_Go_Live_Date__c = ar.get('minForecastedPhaseGoLiveDate') != null ? (Date) ar.get('minForecastedPhaseGoLiveDate') : null,
                        Estimated_Project_Initial_Go_Live_Date__c = ar.get('minEstimatedPhaseGoLiveDate') != null ? (Date) ar.get('minEstimatedPhaseGoLiveDate') : null,
                        Estimated_Project_End__c = ar.get('maxEstimatedPhaseGoLiveDate') != null ? (Date) ar.get('maxEstimatedPhaseGoLiveDate') : null,
                        Times_All_Phases_Go_Live_Date_Changed__c = ar.get('noOfTimesPhaseGoLiveDateChanged') != null ? (Decimal) ar.get('noOfTimesPhaseGoLiveDateChanged') : null,
                        Actual_Initial_Phase_Go_Live__c = ar.get('minActualPhaseGoLiveDate') != null ? (Date) ar.get('minActualPhaseGoLiveDate') : null,
                        Actual_Latest_Go_Live_Date__c = ar.get('maxActualPhaseGoLiveDate') != null ? (Date) ar.get('maxActualPhaseGoLiveDate') : null,
                        Number_of_Open_Phases__c = (Decimal)ar.get('noOfOpenPhases'),
                        Opportunity__c = (Id) ar.get('opportunityId')
                );

                system.debug('**** execute(): parentProject - ' + parentProject);

                Project__c parentProjectOld = projectMap.get(parentProject.Id);

                if(parentProject != parentProjectOld){
                    parentProjects.add(parentProject);
                }

            }

            Set<Id> opportunityIds = new Set<Id>();

            // update PS Parent SaaS projects
            if (parentProjects.size() > 0) {

                Set<Id> updatedIds = new Set<Id>();

                Database.SaveResult[] srList = Database.update(parentProjects, false);
                for(Integer i=0; i < srList.size(); i++){
                    if(srList[i].isSuccess()){
                        updatedIds.add(srList[i].getId());
                    } else{
                        Database.Error[] errors = srList[i].getErrors();
                        if(errors.size() > 0){
                            system.debug('**** execute(): save error - ' + errors.get(0));
                            system.debug('**** execute(): record id - ' + parentProjects[i].Id);
                        }
                    }
                }

                system.debug('**** execute(): updatedIds - ' + updatedIds);

                // retrieve related 'PM-Standard' or 'Qualified Opportunity' record type opportunities
                for(Id projectId : updatedIds){
                    Id opportunityId = projectMap.get('projectId').Opportunity__c;
                    if (opportunityId != null) {
                        opportunityIds.add(opportunityId);
                    }
                }

            }

            system.debug('**** execute(): opportunityIds - ' + opportunityIds);

            // enqueue OpportunityRollupQueueable job to roll-up PS Parent SaaS project Go Live Date Changes to related opportunity
            if (opportunityIds.size() > 0) {
                Id opportunityRollupQueueableJobID = System.enqueueJob(new OpportunityRollupQueueable(opportunityIds));
                system.debug('**** execute(): opportunityRollupQueueableJobID - ' + opportunityRollupQueueableJobID);
            }

        } catch (Exception ex){

            List<Id> projectIds = new List<Id>(parentProjectIds);
            inContactBaseClass.SendErrorEmail(ex, String.join(projectIds, ', '));

        }

    }

}