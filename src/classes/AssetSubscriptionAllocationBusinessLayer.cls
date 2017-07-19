public with sharing class AssetSubscriptionAllocationBusinessLayer {

    public Asset currentAsset;
    public SubscriptionReplica__c currentSubscription;

    public List<AssetSubscriptionAllocationModel> assetAllocations{get; set;}
    public List<AssetSubscriptionAllocationModel> subscriptionAllocations{get; set;}

    public AssetSubscriptionAllocationBusinessLayer(String idParam){

        if(idParam.left(3) == Schema.SObjectType.Asset.getKeyPrefix()){
            getAsset(idParam);
            getAssetAllocations();
        }else if(idParam.left(3) == Schema.SObjectType.SubscriptionReplica__c.getKeyPrefix()){
            getSubscription(idParam);
            getSubscriptionAllocations();
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

        assetAllocations = new List<AssetSubscriptionAllocationModel>();

        for(Project_Asset_Allocation__c allocation : [
                Select Project__c, Percent_Allocation__c, Asset__c, Quantity_Allocation__c
                from Project_Asset_Allocation__c
                where Asset__c = :currentAsset.Id
        ]){
            AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(allocation);
            assetAllocations.add(newModel);
        }

        system.debug('getAssetAllocations(): assetAllocations - ' + assetAllocations);

    }

    private void getSubscription(String subscriptionId){

        List<SubscriptionReplica__c> subscriptions = [
                Select Id, Name, Account__c, Product__c, Quantity__c, ParentProject__c,
                        ParentProject__r.Name
                from SubscriptionReplica__c where Id = :subscriptionId
        ];

        if(subscriptions.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Subscription record found.'));
            return;
        }

        currentSubscription = subscriptions[0];

        system.debug('getSubscription(): currentSubscription - ' + currentSubscription);

    }

    private void getSubscriptionAllocations(){

        subscriptionAllocations = new List<AssetSubscriptionAllocationModel>();

        for(Project_Subscription_Allocation__c allocation : [
                Select Project__c, Subscription__c, Percent_Allocation__c, Quantity_Allocation__c
                from Project_Subscription_Allocation__c
                where Subscription__c = :currentSubscription.Id
        ]){
            AssetSubscriptionAllocationModel newModal = new AssetSubscriptionAllocationModel(allocation);
            subscriptionAllocations.add(newModal);
        }

        system.debug('getSubscriptionAllocations(): subscriptionAllocations - ' + subscriptionAllocations);

    }

    public void createAssetAllocation(){

        AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(currentAsset);
        assetAllocations.add(newModel);

    }

    public void saveAssetAllocation(){

        Project_Asset_Allocation__c[] allocations = new Project_Asset_Allocation__c[]{};
        Project_Asset_Allocation__c[] delAllocations = new Project_Asset_Allocation__c[]{};

        for(AssetSubscriptionAllocationModel modal :assetAllocations){
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