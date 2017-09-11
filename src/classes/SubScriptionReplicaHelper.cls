/**
 * Created by william.nelson on 9/6/2017.
 */

public with sharing class SubScriptionReplicaHelper {

    public List<SubscriptionData> GetSubscriptionReplicas(Account acc){
        List<SubscriptionReplica__c> replicas = [SELECT AccountLookup__c, Bundled__c, Account__c,Active__c,Existing__c,Id,ImplementedProduct__c,IsDeleted,ListUnitPrice__c,Name,ParentProject__c,ProductCode__c,ProductFamily__c,Product__c,Quantity__c,SalesTotal__c,SalesUnitPrice__c,
        Status__c,Subscription__c FROM SubscriptionReplica__c where AccountLookup__c =: acc.id and Active__c = 'Active'];

        List<SubscriptionData> replicaResults = new List<SubscriptionData>();
        for (SubscriptionReplica__c replica : replicas ) {
            SubscriptionData repData = new SubscriptionData();
            repdata.id = replica.id;

            repData.Name = replica.Name;
            repdata.AccountId = replica.AccountLookup__c;
            repdata.ProductName = replica.ImplementedProduct__c;
            repdata.ProductId = replica.Product__c;
            repdata.Active = replica.Active__c;
            repdata.Existing = replica.Existing__c;
            repdata.Bundled = replica.Bundled__c;
            repdata.Quantity = replica.Quantity__c;
            repdata.ListUnitPrice = replica.ListUnitPrice__c;
            repdata.SalesUnitPrice = replica.SalesUnitPrice__c;
            repdata.SalesTotal = replica.SalesTotal__c;
            replicaResults.add(repData);

        }
        system.debug(replicaResults);
        system.debug(replicas);
        return replicaResults;

    }


}