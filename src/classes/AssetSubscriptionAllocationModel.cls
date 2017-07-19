public with sharing class AssetSubscriptionAllocationModal {

    public boolean isDelete{get;set;}
    public Project_Asset_Allocation__c assetAllocation{get; set;}

    public AssetSubscriptionAllocationModal(Asset currentAsset){

        this.assetAllocation = new Project_Asset_Allocation__c(
                Asset__c = currentAsset.Id
        );

    }
    public AssetSubscriptionAllocationModal(Project_Asset_Allocation__c allocation){

        this.assetAllocation = allocation;

    }

}