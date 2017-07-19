public with sharing class AssetSubscriptionAllocationController {

    public Asset getCurrentAsset(){
        return businessLayer != null
                ? businessLayer.currentAsset : null;
    }

    private AssetSubscriptionAllocationBusinessLayer businessLayer;

    public AssetSubscriptionAllocationController(){

        String idParam = ApexPages.currentPage().getParameters().get('id');

        businessLayer = new AssetSubscriptionAllocationBusinessLayer(idParam);




    }

    //need a method to return the availble phase projects
    //need a method to return current allocations for Asset
    //need a method to return current allocations for subscription
    //need a method to save a list of  Asset allocations
    //need a method to save a list of  Subscription Allocations

}