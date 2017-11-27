public class ProjectRollupQueueable implements Queueable{

    final Set<Id> parentProjectIds;
    final Id psProjectParentSaaSRecordTypeId;
    final Id psProjectPhaseSaasRecordTypeId;

    public ProjectRollupQueueable(Set<Id> parentProjectIds){

        this.parentProjectIds = parentProjectIds;
        system.debug('**** ProjectRollupQueueable(): parentProjectIds - ' + parentProjectIds);

        Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        psProjectParentSaaSRecordTypeId = rtMapByName.get('PS Parent Project - SaaS').getRecordTypeId();
        psProjectPhaseSaasRecordTypeId = rtMapByName.get('PS Project Phase SaaS').getRecordTypeId();

    }

    public void execute(QueueableContext context){

        try {

            Set<Id> qualifiedProjectIds = new Set<Id>();

            for(Project__c project : [Select Id from Project__c where Id IN :parentProjectIds and RecordTypeId = :psProjectParentSaaSRecordTypeId]){
                qualifiedProjectIds.add(project.Id);
            }

            system.debug('**** execute(): qualifiedProjectIds - ' + qualifiedProjectIds);

            if(qualifiedProjectIds.isEmpty()){
                return;
            }

            Set<Id> opportunityIds = new Set<Id>();
            List<Project__c> parentProjects = new List<Project__c>();

            for(AggregateResult ar : [
                    Select min(Original_Phase_Forecasted_Go_Live_Date__c) minForecastedPhaseGoLiveDate, sum(Times_Go_Live_Date_Changed__c) noOfTimesPhaseGoLiveDateChanged,
                    min(EstimatedProjectGoLiveDate__c) minEstimatedPhaseGoLiveDate, max(EstimatedProjectGoLiveDate__c) maxEstimatedPhaseGoLiveDate, max(Opportunity__c) opportunityId,
                    ParentProject__c
                    from Project__c
                    where ParentProject__c IN :parentProjectIds and RecordTypeId = :psProjectPhaseSaasRecordTypeId
                    group by ParentProject__c
            ]){

                system.debug('**** execute(): ar - ' + ar);

                Project__c parentProject = new Project__c(
                        Id = (Id)ar.get('ParentProject__c'),
                        Original_Forecasted_Initial_Go_Live_Date__c = ar.get('minForecastedPhaseGoLiveDate') != null ? (Date)ar.get('minForecastedPhaseGoLiveDate') : null,
                        Estimated_Project_Initial_Go_Live_Date__c = ar.get('minEstimatedPhaseGoLiveDate') != null ? (Date)ar.get('minEstimatedPhaseGoLiveDate') : null,
                        Estimated_Project_End__c = ar.get('maxEstimatedPhaseGoLiveDate') != null ? (Date)ar.get('maxEstimatedPhaseGoLiveDate') : null,
                        Times_All_Phases_Go_Live_Date_Changed__c = (Decimal)ar.get('noOfTimesPhaseGoLiveDateChanged')
                );

                system.debug('**** execute(): parentProject - ' + parentProject);
                parentProjects.add(parentProject);

                if(ar.get('opportunityId') != null){
                    opportunityIds.add((Id)ar.get('opportunityId'));
                }
            }


            if (parentProjects.size() > 0) {
                update parentProjects;
            }

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