public class OpportunityRollupQueueable implements Queueable{

    final Set<Id> opportunityIds;
    final Set<Id> validOpportunityRecordTypeIds;
    final Id psProjectParentSaaSRecordTypeId;

    // constructor
    public OpportunityRollupQueueable(Set<Id> opportunityIds){

        this.opportunityIds = opportunityIds;
        system.debug('**** OpportunityRollupQueueable(): opportunityIds - ' + opportunityIds);

        Schema.DescribeSObjectResult d = Schema.SObjectType.Opportunity;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        validOpportunityRecordTypeIds.add(rtMapByName.get('PM-Standard').getRecordTypeId());
        validOpportunityRecordTypeIds.add(rtMapByName.get('Qualified Opportunity').getRecordTypeId());

        d = Schema.SObjectType.Project__c;
        rtMapByName = d.getRecordTypeInfosByName();

        psProjectParentSaaSRecordTypeId = rtMapByName.get('PS Parent Project - SaaS').getRecordTypeId();

    }

    // Queueable interface method
    public void execute(QueueableContext context){

        try {

            Set<Id> qualifiedOpportunityIds = new Set<Id>();

            for (Opportunity opp : [Select Id from Opportunity where Id IN :opportunityIds and RecordTypeId IN :validOpportunityRecordTypeIds]) {
                qualifiedOpportunityIds.add(opp.Id);
            }

            system.debug('**** execute(): qualifiedOpportunityIds - ' + qualifiedOpportunityIds);

            if (qualifiedOpportunityIds.isEmpty()) {
                return;
            }

            List<Opportunity> opportunities = new List<Opportunity>();

            for (AggregateResult ar : [
                    Select min(Original_Forecasted_Initial_Go_Live_Date__c) minForecastedInitialGoLiveDate, sum(Times_All_Phases_Go_Live_Date_Changed__c) noOfTimesPhaseGoLiveDateChanged,
                            min(Estimated_Project_End__c) minEstimatedProjectEndDate, Opportunity__c
                    from Project__c
                    where Opportunity__c IN :qualifiedOpportunityIds and RecordTypeId = :psProjectParentSaaSRecordTypeId
                    group by Opportunity__c
            ]) {

                system.debug('**** execute(): ar - ' + ar);
                
                Opportunity opp = new Opportunity(
                        Id = (Id) ar.get('Opportunity__c'),
                        Original_Forecasted_Initial_Go_Live_Date__c = ar.get('minForecastedInitialGoLiveDate') != null ? (Date) ar.get('minForecastedInitialGoLiveDate') : null,
                        PM_Estimated_Go_Live__c = ar.get('minEstimatedProjectEndDate') != null ? (Date) ar.get('minEstimatedProjectEndDate') : null,
                        Times_Go_Live_Date_Changed__c = (Decimal) ar.get('noOfTimesPhaseGoLiveDateChanged')
                );

                system.debug('**** execute(): opp - ' + opp);

                opportunities.add(opp);

            }

            if (opportunities.size() > 0) {
                update opportunities;
            }

        } catch (Exception ex){

            List<Id> oppIdList = new List<Id>(opportunityIds);
            inContactBaseClass.SendErrorEmail(ex, String.join(oppIdList, ', '));

        }

    }
}