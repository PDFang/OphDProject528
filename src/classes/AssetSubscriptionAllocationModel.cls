public with sharing class AssetSubscriptionAllocationModel {

    public boolean isDelete{get;set;}
    public boolean isError{get;set;}
    public boolean isQuantityAllocation{get;set;}
    public string message{get;set;}
    public Project_Asset_Allocation__c assetAllocation{get; set;}
    public Project_Subscription_Allocation__c subscriptionAllocation{get;set;}

    public AssetSubscriptionAllocationModel(Asset currentAsset){


        this.assetAllocation = new Project_Asset_Allocation__c(
                Asset__c = (currentAsset !=null ? currentAsset.Id:null ) ,
                Asset__r = (currentAsset !=null ? currentAsset:null )
        );
        this.isQuantityAllocation = (currentAsset.Quantity != 1);

    }
    public AssetSubscriptionAllocationModel(Project_Asset_Allocation__c allocation){

        this.assetAllocation = allocation;
        this.isQuantityAllocation = (allocation.Asset__r.Quantity != 1);

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