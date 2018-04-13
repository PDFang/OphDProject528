/**
 * Created by mohandaas.rangaswamy on 12/1/2017.
 */

// summarize and rollup subscription MRR's to related phase project
public class SubscriptionRollupQueueable implements Queueable{

    public Set<Id> projectIds;
    private final set<id> parentProjectIds;

    // constructor
    public SubscriptionRollupQueueable(Set<Id> subscriptionIds) {

        system.debug('**** SubscriptionRollupQueueable(): subscriptionIds - ' + subscriptionIds);

        projectIds = new Set<Id>();
        parentProjectIds = new set<Id>();
        Schema.DescribeSObjectResult projObjectResult = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> projRecordTypeInfosByName = projObjectResult.getRecordTypeInfosByName();

        Id psProjectPhaseSaasRecordTypeId = projRecordTypeInfosByName.get('PS Project Phase SaaS').getRecordTypeId();
        Id psProjectPhasePremiseRecordTypeId = projRecordTypeInfosByName.get('PS Project Phase Premise WFO').getRecordTypeId();

        Id psParentProjectSaaSId = projRecordTypeInfosByName.get('PS Parent Project - SaaS').getRecordTypeId();
        Id psParentProjectPremiseId = projRecordTypeInfosByName.get('PS Parent Project - Premise').getRecordTypeId();

        Set<Id> psProjectPhaseRecordTypeIds = new Set<Id>{
                psProjectPhaseSaasRecordTypeId,
                psProjectPhasePremiseRecordTypeId
        };

        Set<Id> parentProjectRecordTypeIds = new Set<Id>{
                psParentProjectSaaSId,
                psParentProjectPremiseId
        };

        for(Project_Subscription_Allocation__c allocation : [
                Select Project__c, Subscription__r.ParentProject__c from Project_Subscription_Allocation__c
                where Subscription__r.Subscription__c IN :subscriptionIds and Project__r.RecordTypeId IN :psProjectPhaseRecordTypeIds
        ]){
            projectIds.add(allocation.Project__c);
        }

        for(SubscriptionReplica__c subs :
                [select Id, ParentProject__c from SubscriptionReplica__c
                 where Subscription__c in :subscriptionIds and ParentProject__r.RecordTypeId in: parentProjectRecordTypeIds]){
            parentProjectIds.add(subs.ParentProject__c);
        }


    }

    public SubscriptionRollupQueueable(){}
    // interface method
    public void execute(QueueableContext context){

       /* if(projectIds.isEmpty()){
            return;
        }*/

        AssetSubscriptionRollupHelper helper = new AssetSubscriptionRollupHelper(projectIds);

        List<Project__c> projects = helper.rollupSubscriptionFinancials();
        projects.addAll(helper.rollupSubsCancelledQuantity(parentProjectIds));
        if(projects.size() > 0){

            Database.SaveResult[] srList = Database.update(projects, false);
            for(Integer i=0; i < srList.size(); i++){
                if(!srList[i].isSuccess()){
                    Database.Error[] errors = srList[i].getErrors();
                    if(errors.size() > 0){
                        system.debug('**** execute(): save error - ' + errors.get(0));
                        system.debug('**** execute(): record id - ' + projects[i].Id);
                    }
                }
            }

        }

    }

}