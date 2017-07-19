public with sharing class AssetSubscriptionAllocationBusinessLayer {

    public Asset currentAsset;

    public List<AssetSubscriptionAllocationModal> assetAllocations{get; set;}

    public AssetSubscriptionAllocationBusinessLayer(String idParam){

        if(idParam.left(3) == Schema.SObjectType.Asset.getKeyPrefix()){
            getAsset(idParam);
            getAssetAllocations();
        }

    }

    private void getAsset(String assetId){

        List<Asset> assets = [
                Select Id, Name, Description, RecordType.Name, Account.Name, Product2.Name, Quantity, Budgeted_Hours__c, Parent_Project__c,
                        Parent_Project__r.Name, Type__c
                from Asset where Id = :assetId
        ];

        if(assets.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No asset record found.'));
            return;
        }

        currentAsset = assets[0];

        system.debug('getAsset(): currentAsset - ' + currentAsset);

    }

    private void getAssetAllocations(){

        assetAllocations = new List<AssetSubscriptionAllocationModal>();

        for(Project_Asset_Allocation__c allocation : [
                Select Project__c, Percent_Allocation__c, Asset__c, Quantity_Allocation__c
                from Project_Asset_Allocation__c
                where Asset__c = :currentAsset.Id
        ]){
            AssetSubscriptionAllocationModal newModal = new AssetSubscriptionAllocationModal(allocation);
            assetAllocations.add(newModal);
        }

        system.debug('getAssetAllocations(): assetAllocations - ' + assetAllocations);

    }

    public void createAssetAllocation(){

        AssetSubscriptionAllocationModal newModal = new AssetSubscriptionAllocationModal(currentAsset);
        assetAllocations.add(newModal);

    }

    public void saveAssetAllocation(){

        Project_Asset_Allocation__c[] allocations = new Project_Asset_Allocation__c[]{};
        Project_Asset_Allocation__c[] delAllocations = new Project_Asset_Allocation__c[]{};

        for(AssetSubscriptionAllocationModal modal :assetAllocations){
            if(modal.isDelete){
                if(modal.assetAllocation.Id != null){
                    delAllocations.add(modal.assetAllocation);
                }
                continue;
            }
            allocations.add(modal.assetAllocation);
        }

        system.debug('getAssetAllocations(): allocations - ' + allocations);

        system.debug('getAssetAllocations(): delAllocations - ' + delAllocations);

        if(allocations.size() > 0){
            upsert allocations;
        }

        if(delAllocations.size() > 0){
            delete delAllocations;
        }

    }

}