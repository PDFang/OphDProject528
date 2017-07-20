public with sharing class AssetSubscriptionAllocationModel {

    public boolean isDelete{get;set;}
    public boolean isError{get;set;}
    public string message{get;set;}
    public Project_Asset_Allocation__c assetAllocation{get; set;}
    public Project_Subscription_Allocation__c subscriptionAllocation{get;set;}

    public AssetSubscriptionAllocationModel(Asset currentAsset){

        this.assetAllocation = new Project_Asset_Allocation__c(
                Asset__c = currentAsset.Id,
                Asset__r = currentAsset,
                Quantity_Allocation__c = (currentAsset.Quantity == 1) ? 1 : null
        );

    }
    public AssetSubscriptionAllocationModel(Project_Asset_Allocation__c allocation){

        this.assetAllocation = allocation;

    }

    public AssetSubscriptionAllocationModel(SubscriptionReplica__c currentSubscription){

        this.subscriptionAllocation = new Project_Subscription_Allocation__c(
                Subscription__c = currentSubscription.Id,
                Subscription__r = currentSubscription
        );

    }
    public AssetSubscriptionAllocationModel(Project_Subscription_Allocation__c allocation){

        this.subscriptionAllocation = allocation;

    }    

}