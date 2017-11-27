// this job is enqueued from ProjectTriggerHandler class
public class ProjectRollupQueueable implements Queueable{

    final Set<Id> parentProjectIds;
    final Id psProjectParentSaaSRecordTypeId;
    final Id psProjectPhaseSaasRecordTypeId;
    final Set<Id> validOpportunityRecordTypeIds;

    // constructor
    public ProjectRollupQueueable(Set<Id> parentProjectIds){

        this.parentProjectIds = parentProjectIds;
        system.debug('**** ProjectRollupQueueable(): parentProjectIds - ' + parentProjectIds);

        Schema.DescribeSObjectResult projObjectResult = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> projRecordTypeInfosByName = projObjectResult.getRecordTypeInfosByName();

        psProjectParentSaaSRecordTypeId = projRecordTypeInfosByName.get('PS Parent Project - SaaS').getRecordTypeId();
        psProjectPhaseSaasRecordTypeId = projRecordTypeInfosByName.get('PS Project Phase SaaS').getRecordTypeId();

        Schema.DescribeSObjectResult oppObjectResult = Schema.SObjectType.Opportunity;
        Map<String, Schema.RecordTypeInfo> oppRecordTypeInfosByName = oppObjectResult.getRecordTypeInfosByName();

        validOpportunityRecordTypeIds = new Set<Id>();
        validOpportunityRecordTypeIds.add(oppRecordTypeInfosByName.get('PM-Standard').getRecordTypeId());
        validOpportunityRecordTypeIds.add(oppRecordTypeInfosByName.get('Qualified Opportunity').getRecordTypeId());

    }

    // Queueable interface method
    // roll-up PS Phase SaaS project Go Live Date Changes to PS Parent SaaS project
    // enqueue OpportunityRollupQueueable job
    public void execute(QueueableContext context){

        try {

            // validate parent project record type is 'PS Parent Project - SaaS'
            Set<Id> qualifiedProjectIds = new Set<Id>();

            for (Project__c project : [Select Id from Project__c where Id IN :parentProjectIds and RecordTypeId = :psProjectParentSaaSRecordTypeId]) {
                qualifiedProjectIds.add(project.Id);
            }

            system.debug('**** execute(): qualifiedProjectIds - ' + qualifiedProjectIds);

            if (qualifiedProjectIds.isEmpty()) {
                return;
            }

            List<Project__c> parentProjects = new List<Project__c>();

            // aggregate PS Phase SaaS projects
            for (AggregateResult ar : [
                    Select min(Original_Phase_Forecasted_Go_Live_Date__c) minForecastedPhaseGoLiveDate, sum(Times_Go_Live_Date_Changed__c) noOfTimesPhaseGoLiveDateChanged,
                            min(EstimatedProjectGoLiveDate__c) minEstimatedPhaseGoLiveDate, max(EstimatedProjectGoLiveDate__c) maxEstimatedPhaseGoLiveDate, ParentProject__c
                    from Project__c
                    where ParentProject__c IN :parentProjectIds and RecordTypeId = :psProjectPhaseSaasRecordTypeId
                    group by ParentProject__c
            ]) {

                system.debug('**** execute(): ar - ' + ar);

                Project__c parentProject = new Project__c(
                        Id = (Id) ar.get('ParentProject__c'),
                        Original_Forecasted_Initial_Go_Live_Date__c = ar.get('minForecastedPhaseGoLiveDate') != null ? (Date) ar.get('minForecastedPhaseGoLiveDate') : null,
                        Estimated_Project_Initial_Go_Live_Date__c = ar.get('minEstimatedPhaseGoLiveDate') != null ? (Date) ar.get('minEstimatedPhaseGoLiveDate') : null,
                        Estimated_Project_End__c = ar.get('maxEstimatedPhaseGoLiveDate') != null ? (Date) ar.get('maxEstimatedPhaseGoLiveDate') : null,
                        Times_All_Phases_Go_Live_Date_Changed__c = (Decimal) ar.get('noOfTimesPhaseGoLiveDateChanged')
                );

                system.debug('**** execute(): parentProject - ' + parentProject);
                parentProjects.add(parentProject);

            }

            Set<Id> opportunityIds = new Set<Id>();

            // update PS Parent SaaS projects
            if (parentProjects.size() > 0) {
                update parentProjects;

                // retrieve related 'PM-Standard' or 'Qualified Opportunity' record type opportunities
                for(Project__c project : [Select Opportunity__c from Project__c where Id IN :parentProjects and Opportunity__r.RecordTypeId IN :validOpportunityRecordTypeIds]){
                    if (project.Opportunity__c != null) {
                        opportunityIds.add(project.Opportunity__c);
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