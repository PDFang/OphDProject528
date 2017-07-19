public with sharing class AssetSubscriptionAllocationBusinessLayer {

    public Asset currentAsset;

    public AssetSubscriptionAllocationBusinessLayer(String idParam){

        if(idParam.left(3) == Schema.SObjectType.Asset.getKeyPrefix()){
            getAsset(idParam);
        }

    }

    private void getAsset(String assetId){

        List<Asset> assets = [
                Select Id, Name, Description, RecordType.Name, Account.Name, Product2.Name, Quantity, Budgeted_Hours__c, Parent_Project__c,
                        Parent_Project__r.Name, Type__c
                from Asset where Id = :assetId
        ];

        currentAsset = assets[0];

    }
}