public with sharing class AssetSubscriptionAllocationController {

    public Asset getCurrentAsset(){
        return businessLayer != null
                ? businessLayer.currentAsset : null;
    }

    public List<AssetSubscriptionAllocationModal> getAssetAllocations(){
        return businessLayer != null
                ? businessLayer.assetAllocations : null;
    }


    private AssetSubscriptionAllocationBusinessLayer businessLayer;

    public AssetSubscriptionAllocationController(){

        String idParam = ApexPages.currentPage().getParameters().get('id');

        system.debug('getAsset(): idParam - ' + idParam);

        if(String.isBlank(idParam)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid URL: Missing ID Parameter.'));
            return;
        }

        businessLayer = new AssetSubscriptionAllocationBusinessLayer(idParam);

    }

    public pagereference createAssetAllocation(){

        try{
            businessLayer.createAssetAllocation();
        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while creating a new asset allocation. ' + ex.getMessage()));
            system.debug('createAssetAllocation(): Exception - ' + ex);
        }
        return null;

    }

    public pagereference saveAssetAllocation(){

        try{
            businessLayer.saveAssetAllocation();
        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while saving asset allocations. ' + ex.getMessage()));
            system.debug('saveAssetAllocation(): Exception - ' + ex);
        }
        return null;
    }

    //need a method to return the availble phase projects
    //need a method to return current allocations for Asset
    //need a method to return current allocations for subscription
    //need a method to save a list of  Asset allocations
    //need a method to save a list of  Subscription Allocations

}