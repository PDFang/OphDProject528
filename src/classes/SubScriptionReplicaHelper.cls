/**
 * Created by william.nelson on 9/6/2017.
 */

public with sharing class SubScriptionReplicaHelper {

    public List<SubscriptionReplica__c> GetSubscriptionReplicas(Account acc){
        List<SubscriptionReplica__c> replicas = [SELECT AccountLookup__c,Account__c,Active__c,AdditionalDisc__c,Budgeted_Hours__c,ConnectionReceivedId,ConnectionSentId,Contract__c,CreatedById,CreatedDate,EndDate__c,Existing__c,Id,ImplementedProduct__c,IsDeleted,LastActivityDate,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,ListUnitPrice__c,Name,ParentProject__c,ProductCode__c,ProductFamily__c,Product__c,ProjectPhase__c,ProrateMultiplier__c,Quantity__c,QuoteLineLookup__c,QuoteType__c,Quote_Line__c,RenewalPrice__c,RenewalQuantity__c,RenewalUplift__c,Renewed_Date__c,SalesTotal__c,SalesUnitPrice__c,
            StartDate__c,Status__c,Subscription__c,SystemModstamp,Total_Allocated_Hours__c,Total_Allocated_Quantity__c FROM SubscriptionReplica__c where AccountLookup__c =: acc.id and Active__c = 'Active'];
        return replicas;
    }


}