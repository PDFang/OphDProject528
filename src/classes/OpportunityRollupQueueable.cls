// this job is enqueued from ProjectRollupQueueable class
public class OpportunityRollupQueueable implements Queueable{

    final Set<Id> opportunityIds;
    final Id psProjectParentSaaSRecordTypeId, psProjectParentPremiseRecordTypeId;
    final Set<Id> validOpportunityRecordTypeIds;
    final Set<Id> psProjectParentRecordTypeIds;

    // constructor
    public OpportunityRollupQueueable(Set<Id> opportunityIds){

        this.opportunityIds = opportunityIds;
        system.debug('**** OpportunityRollupQueueable(): opportunityIds - ' + opportunityIds);

        Schema.DescribeSObjectResult projObjectResult = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> projRecordTypeInfosByName = projObjectResult.getRecordTypeInfosByName();

        psProjectParentSaaSRecordTypeId = projRecordTypeInfosByName.get('PS Parent Project - SaaS').getRecordTypeId();
        psProjectParentPremiseRecordTypeId = projRecordTypeInfosByName.get('PS Parent Project - Premise').getRecordTypeId();

        psProjectParentRecordTypeIds = new Set<Id>{
                psProjectParentSaaSRecordTypeId,
                psProjectParentPremiseRecordTypeId
        };

        Schema.DescribeSObjectResult oppObjectResult = Schema.SObjectType.Opportunity;
        Map<String, Schema.RecordTypeInfo> oppRecordTypeInfosByName = oppObjectResult.getRecordTypeInfosByName();

        validOpportunityRecordTypeIds = new Set<Id>();
        validOpportunityRecordTypeIds.add(oppRecordTypeInfosByName.get('PM-Standard').getRecordTypeId());
        validOpportunityRecordTypeIds.add(oppRecordTypeInfosByName.get('Qualified Opportunity').getRecordTypeId());

    }

    // Queueable interface method
    // roll-up PS Parent SaaS project Go Live Date Changes to related Opportunity
    // roll-up PS Parent SaaS and Premise project financials to related Opportunity
    public void execute(QueueableContext context){

        try {

            // Opportunity record type must be 'PM-Standard' or 'Qualified Opportunity'
            Map<Id, Opportunity> opportunityCache = new Map<Id, Opportunity>([
                    Select Id, Original_Forecasted_Initial_Go_Live_Date__c, PM_Estimated_Go_Live__c,
                            Times_Go_Live_Date_Changed__c, PM_Go_Live_Date__c,
                            Contracted_NRR__c, Actual_NRR__c, Contracted_MRR__c, Actual_MRR__c,
                            Logged_Hours__c
                    from Opportunity
                    where Id IN :opportunityIds and RecordTypeId IN :validOpportunityRecordTypeIds
            ]);

            system.debug('**** execute(): opportunityCache - ' + opportunityCache);

            if(opportunityCache.isEmpty()){
                return;
            }

            Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>();

            rollupGoLiveDates(opportunityCache, opportunities);
            rollupFinancials(opportunityCache, opportunities);

            // update related opportunities
            if (opportunities.size() > 0) {

                List<Opportunity> updateOpportunities = opportunities.values();

                Database.SaveResult[] srList = Database.update(updateOpportunities, false);
                for(Integer i=0; i < srList.size(); i++){
                    if(srList[i].isSuccess()){
                        Database.Error[] errors = srList[i].getErrors();
                        if(errors.size() > 0){
                            system.debug('**** execute(): save error - ' + errors.get(0));
                            system.debug('**** execute(): record id - ' + updateOpportunities[i].Id);
                        }
                    }
                }
            }

        } catch (Exception ex){

            List<Id> oppIdList = new List<Id>(opportunityIds);
            inContactBaseClass.SendErrorEmail(ex, String.join(oppIdList, ', '));

        }

    }


    private void rollupGoLiveDates(Map<Id, Opportunity> opportunityCache, Map<Id, Opportunity> opportunities){

        // aggregate PS Parent SaaS projects
        for (AggregateResult ar : [
                Select min(Original_Forecasted_Initial_Go_Live_Date__c) minForecastedInitialGoLiveDate, sum(Times_All_Phases_Go_Live_Date_Changed__c) noOfTimesPhaseGoLiveDateChanged,
                        min(Estimated_Project_End__c) minEstimatedProjectEndDate, min(ActualProjectGoLiveDate__c) minActualGoLiveDate, min(Actual_Initial_Phase_Go_Live__c) minInitialGoLiveDate,
                        Opportunity__c
                from Project__c
                where Opportunity__c IN :opportunityCache.keySet() and RecordTypeId = :psProjectParentSaaSRecordTypeId
                group by Opportunity__c
        ]) {

            system.debug('**** rollupGoLiveDates(): ar - ' + ar);

            Id opportunityId = (Id) ar.get('Opportunity__c');

            Opportunity opp = opportunities.get(opportunityId);

            if(opp == null){
                opp = new Opportunity(
                    Id = opportunityId
                );
            }

            opp.Original_Forecasted_Initial_Go_Live_Date__c = ar.get('minForecastedInitialGoLiveDate') != null ? (Date) ar.get('minForecastedInitialGoLiveDate') : null;
            opp.PM_Estimated_Go_Live__c = ar.get('minEstimatedProjectEndDate') != null ? (Date) ar.get('minEstimatedProjectEndDate') : null;
            opp.Times_Go_Live_Date_Changed__c = ar.get('noOfTimesPhaseGoLiveDateChanged') != null ? (Decimal) ar.get('noOfTimesPhaseGoLiveDateChanged') : null;
            //opp.PM_Go_Live_Date__c = ar.get('minActualGoLiveDate') != null ? (Date) ar.get('minActualGoLiveDate') : null;
            opp.PM_Go_Live_Date__c = ar.get('minInitialGoLiveDate') != null ? (Date) ar.get('minInitialGoLiveDate') : null;

            system.debug('**** rollupGoLiveDates(): opp - ' + opp);

            Opportunity oppOld = opportunityCache.get(opp.Id);
            system.debug('**** rollupGoLiveDates(): opp - ' + oppOld);

            if(opp.Original_Forecasted_Initial_Go_Live_Date__c != oppOld.Original_Forecasted_Initial_Go_Live_Date__c
                    || opp.PM_Estimated_Go_Live__c != oppOld.PM_Estimated_Go_Live__c
                    || opp.Times_Go_Live_Date_Changed__c != oppOld.Times_Go_Live_Date_Changed__c
                    || opp.PM_Go_Live_Date__c != oppOld.PM_Go_Live_Date__c)
            {
                system.debug('**** rollupGoLiveDates(): one or more fields value have changed');
                opportunities.put(opp.Id, opp);
            }

        }

    }

    private void rollupFinancials(Map<Id, Opportunity> opportunityCache, Map<Id, Opportunity> opportunities){

        // aggregate PS Parent SaaS and Premise projects
        for (AggregateResult ar : [
                Select sum(Contracted_NRR__c) totalContractedNRR, sum(Actual_NRR__c) totalActualNRR,
                        sum(Contracted_MRR__c) totalContractedMRR, sum(Actual_MRR__c) totalActualMRR,
                        sum(Logged_Hours__c) totalHours, Opportunity__c
                from Project__c
                where Opportunity__c IN :opportunityCache.keySet() and RecordTypeId IN :psProjectParentRecordTypeIds
                group by Opportunity__c
        ]) {

            system.debug('**** rollupFinancials(): ar - ' + ar);

            Id opportunityId = (Id) ar.get('Opportunity__c');

            Opportunity opp = opportunities.get(opportunityId);

            if(opp == null){
                opp = new Opportunity(
                        Id = opportunityId
                );
            }

            opp.Actual_NRR__c = ar.get('totalActualNRR') != null ? (Decimal)ar.get('totalActualNRR') : 0;
            opp.Contracted_NRR__c = ar.get('totalContractedNRR') != null ? (Decimal)ar.get('totalContractedNRR') : 0;
            opp.Logged_Hours__c = ar.get('totalHours') != null ? (Decimal)ar.get('totalHours') : 0;
            opp.Actual_MRR__c = ar.get('totalActualMRR') != null ? (Decimal)ar.get('totalActualMRR') : 0;
            opp.Contracted_MRR__c = ar.get('totalContractedMRR') != null ? (Decimal)ar.get('totalContractedMRR') : 0;

            system.debug('**** rollupFinancials(): opp - ' + opp);

            Opportunity oppOld = opportunityCache.get(opp.Id);
            system.debug('**** rollupFinancials(): opp - ' + oppOld);

            if(opp.Contracted_NRR__c != oppOld.Contracted_NRR__c || opp.Actual_NRR__c != oppOld.Actual_NRR__c
                    || opp.Contracted_MRR__c != oppOld.Contracted_MRR__c || opp.Actual_MRR__c != oppOld.Actual_MRR__c
                    || opp.Logged_Hours__c != oppOld.Logged_Hours__c)
            {
                system.debug('**** rollupFinancials(): one or more fields value have changed');
                opportunities.put(opp.Id, opp);
            }

        }

    }


}