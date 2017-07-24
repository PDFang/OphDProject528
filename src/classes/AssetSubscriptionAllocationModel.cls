public with sharing class AssetSubscriptionAllocationModel {

    public integer rowid{get;set;}
    public boolean isDelete{get;set;}
    public boolean isError{get;set;}
    public boolean isQuantityAllocation{get;set;}
    public string message{get;set;}
    public Project_Asset_Allocation__c assetAllocation{get; set;}
    public Project_Subscription_Allocation__c subscriptionAllocation{get;set;}

    public AssetSubscriptionAllocationModel(Asset currentAsset, Project__c currentProject, Integer row){

        this.assetAllocation = new Project_Asset_Allocation__c(
                Asset__c = currentAsset != null ? currentAsset.Id : null,
                Asset__r = currentAsset != null ? currentAsset : null,
                project__c = currentProject != null ? currentProject.id : null
        );
        this.isQuantityAllocation = (currentAsset != null && currentAsset.Quantity != 1);
        this.rowid = row;

    }

    public AssetSubscriptionAllocationModel(Project_Asset_Allocation__c allocation, Integer row){

        this.assetAllocation = allocation;
        this.isQuantityAllocation = (allocation.Asset__c != null && allocation.Asset__r.Quantity != 1);
        this.rowid = row;

    }

    public AssetSubscriptionAllocationModel(SubscriptionReplica__c currentSubscription, Project__c currentProject, Integer row){

        this.subscriptionAllocation = new Project_Subscription_Allocation__c(
                Subscription__c = currentSubscription != null ? currentSubscription.Id : null,
                Subscription__r = currentSubscription != null ? currentSubscription : null,
                project__c = currentProject != null ? currentProject.id : null
        );
        this.rowid = row;

    }

    public AssetSubscriptionAllocationModel(Project_Subscription_Allocation__c allocation, Integer row){

        this.subscriptionAllocation = allocation;
        this.rowid = row;

    }    

}