public with sharing class AssetSubscriptionAllocationModal {

    public Project_Asset_Allocation__c assetAllocation{get; set;}

    public AssetSubscriptionAllocationModal(Asset currentAsset){

        this.assetAllocation = new Project_Asset_Allocation__c(
                Asset__c = assetAllocation.Id
        );

    }
    public AssetSubscriptionAllocationModal(Project_Asset_Allocation__c allocation){

        this.assetAllocation = allocation;

    }

}