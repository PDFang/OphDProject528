// this job is enqueued from ProjectRollupQueueable class
public class OpportunityRollupQueueable implements Queueable{

    final Set<Id> opportunityIds;
    final Id psProjectParentSaaSRecordTypeId;

    // constructor
    public OpportunityRollupQueueable(Set<Id> opportunityIds){

        this.opportunityIds = opportunityIds;
        system.debug('**** OpportunityRollupQueueable(): opportunityIds - ' + opportunityIds);

        Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        psProjectParentSaaSRecordTypeId = rtMapByName.get('PS Parent Project - SaaS').getRecordTypeId();

    }

    // Queueable interface method
    // roll-up PS Parent SaaS project Go Live Date Changes to related Opportunity
    public void execute(QueueableContext context){

        try {

            List<Opportunity> opportunities = new List<Opportunity>();

            // aggregate PS Parent SaaS projects
            for (AggregateResult ar : [
                    Select min(Original_Forecasted_Initial_Go_Live_Date__c) minForecastedInitialGoLiveDate, sum(Times_All_Phases_Go_Live_Date_Changed__c) noOfTimesPhaseGoLiveDateChanged,
                            min(Estimated_Project_End__c) minEstimatedProjectEndDate, min(ActualProjectGoLiveDate__c) minActualGoLiveDate, min(Actual_Initial_Phase_Go_Live__c) minInitialGoLiveDate,
                            Opportunity__c
                    from Project__c
                    where Opportunity__c IN :opportunityIds and RecordTypeId = :psProjectParentSaaSRecordTypeId
                    group by Opportunity__c
            ]) {

                system.debug('**** execute(): ar - ' + ar);

                Opportunity opp = new Opportunity(
                        Id = (Id) ar.get('Opportunity__c'),
                        Original_Forecasted_Initial_Go_Live_Date__c = ar.get('minForecastedInitialGoLiveDate') != null ? (Date) ar.get('minForecastedInitialGoLiveDate') : null,
                        PM_Estimated_Go_Live__c = ar.get('minEstimatedProjectEndDate') != null ? (Date) ar.get('minEstimatedProjectEndDate') : null,
                        Times_Go_Live_Date_Changed__c = ar.get('noOfTimesPhaseGoLiveDateChanged') != null ? (Decimal) ar.get('noOfTimesPhaseGoLiveDateChanged') : null,
                        //PM_Go_Live_Date__c = ar.get('minActualGoLiveDate') != null ? (Date) ar.get('minActualGoLiveDate') : null
                        PM_Go_Live_Date__c = ar.get('minInitialGoLiveDate') != null ? (Date) ar.get('minInitialGoLiveDate') : null
                );

                system.debug('**** execute(): opp - ' + opp);

                opportunities.add(opp);

            }

            // update related opportunities
            if (opportunities.size() > 0) {
                update opportunities;
            }

        } catch (Exception ex){

            List<Id> oppIdList = new List<Id>(opportunityIds);
            inContactBaseClass.SendErrorEmail(ex, String.join(oppIdList, ', '));

        }

    }
}