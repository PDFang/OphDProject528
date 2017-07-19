public with sharing class AssetSubscriptionAllocationModal {

    public boolean isDelete{get;set;}
    public Project_Asset_Allocation__c assetAllocation{get; set;}
    public Project_Subscription_Allocation__c subscriptionAllocation{get;set;}

    public AssetSubscriptionAllocationModal(Asset currentAsset){

        this.assetAllocation = new Project_Asset_Allocation__c(
                Asset__c = currentAsset.Id
        );

    }
    public AssetSubscriptionAllocationModal(Project_Asset_Allocation__c allocation){

        this.assetAllocation = allocation;

    }

    public AssetSubscriptionAllocationModal(SubscriptionReplica__c currentSubscription){

        this.subscriptionAllocation = new Project_Subscription_Allocation__c(
                Subscription__c = currentSubscription.Id
        );

    }
    public AssetSubscriptionAllocationModal(Project_Subscription_Allocation__c allocation){

        this.subscriptionAllocation = allocation;

    }


}