public with sharing class AssetSubscriptionAllocationModel {

    public boolean isDelete{get;set;}
    public Project_Asset_Allocation__c assetAllocation{get; set;}
    public Project_Subscription_Allocation__c subscriptionAllocation{get;set;}

    public AssetSubscriptionAllocationModel(Asset currentAsset){

        this.assetAllocation = new Project_Asset_Allocation__c(
                Asset__c = currentAsset.Id
        );

    }
    public AssetSubscriptionAllocationModel(Project_Asset_Allocation__c allocation){

        this.assetAllocation = allocation;

    }

    public AssetSubscriptionAllocationModel(SubscriptionReplica__c currentSubscription){

        this.subscriptionAllocation = new Project_Subscription_Allocation__c(
                Subscription__c = currentSubscription.Id
        );

    }
    public AssetSubscriptionAllocationModel(Project_Subscription_Allocation__c allocation){

        this.subscriptionAllocation = allocation;

    }    

}