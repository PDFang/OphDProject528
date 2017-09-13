// AssetSubscriptionAllocation VF page custom controller
public with sharing class AssetSubscriptionAllocationController {

    // current asset record
    public Asset Asset{
        get {
        return businessLayer != null
                ? businessLayer.currentAsset : null;
        }
    }

    // current subscription record
    public SubscriptionReplica__c Subscription{
        get {
            return businessLayer != null
                    ? businessLayer.currentSubscription : null;
        }
    }

    // current project record
    public Project__c Project{
        get {
            return businessLayer != null
                    ? businessLayer.currentProject : null;
        }
    }

    public List<AssetSubscriptionAllocationModel> getAssetAllocations(){
        return businessLayer != null
                ? businessLayer.assetAllocations : null;
    }

    public List<AssetSubscriptionAllocationModel> getSubscriptionAllocations(){
        return businessLayer != null
                ? businessLayer.subscriptionAllocations : null;
    }

    // query string parameter
    private String currentId;

    private AssetSubscriptionAllocationBusinessLayer businessLayer;

    public Decimal remainingQuantity {
        get {
            return businessLayer != null
                    ? businessLayer.remainingQuantity : null;
        }
    }

    public Decimal remainingPercentage {
        get {
            return businessLayer != null
                    ? businessLayer.remainingPercentage : null;
        }
    }
    public Decimal remainingBudgetedHours {
        get {
            return businessLayer != null
                    ? businessLayer.remainingBudgetedHours : null;
        }
    }

    public Decimal remainingSubscriptionQuantity {
        get {
            return businessLayer != null
                    ? businessLayer.remainingSubscriptionQuantity : null;
        }
    }
    public Decimal remainingSubscriptionPercentage {
        get {
            return businessLayer != null
                    ? businessLayer.remainingSubscriptionPercentage : null;
        }
    }

    public String AssetName {
        get {
            return businessLayer != null
                    ? businessLayer.assetName : null;
        }
    }

    public String SubscriptionName {
        get {
            return businessLayer != null
                    ? businessLayer.subscriptionName : null;
        }
    }

    // constructor
    public AssetSubscriptionAllocationController(){

        currentId = ApexPages.currentPage().getParameters().get('id');

        system.debug('getAsset(): currentId - ' + currentId);

        if(String.isBlank(currentId)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid URL: Missing ID Parameter.'));
            return;
        }

        businessLayer = new AssetSubscriptionAllocationBusinessLayer(currentId);

    }

    public pagereference createAssetAllocation(){

        try{
            businessLayer.createAssetAllocation();
            businessLayer.getAssetRemainingQuantityNPercentage(Asset);
        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while creating a new asset allocation. ' + ex.getMessage()));
            system.debug('createAssetAllocation(): Exception - ' + ex);
        }
        return null;

    }

    public pagereference deleteAssetAllocation(){

        try{
            String rowId = ApexPages.currentPage().getParameters().get('delAssetRowId');
            system.debug('deleteAssetAllocation(): rowId - ' + rowId);

            businessLayer.deleteAssetAllocation(Integer.valueOf(rowid));
        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while deleting asset allocation. ' + ex.getMessage()));
            system.debug('deleteAssetAllocation(): Exception - ' + ex);
        }
        return null;

    }

    public pagereference saveAssetAllocation(){

        try{

            Boolean success = businessLayer.saveAssetAllocation();
            if(success){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Saved Successfully.'));
                businessLayer = new AssetSubscriptionAllocationBusinessLayer(currentId);
                businessLayer.getAssetRemainingQuantityNPercentage(Asset);
            } else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'One or more line item(s) has error.'));
            }

        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while saving asset allocations. ' + ex.getMessage()));
            system.debug('saveAssetAllocation(): Exception - ' + ex);
            system.debug('saveAssetAllocation(): ' + ex.getStackTraceString());
        }
        return null;

    }

    public pagereference createSubscriptionAllocation(){

        try{
            businessLayer.createSubscriptionAllocation();
            businessLayer.getSubscriptionRemainingQuantityNPercentage(Subscription);
        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while creating a new subscription allocation. ' + ex.getMessage()));
            system.debug('createSubscriptionAllocation(): Exception - ' + ex);
        }
        return null;

    }

    public pagereference deleteSubscriptionAllocation(){

        try{
            String rowId = ApexPages.currentPage().getParameters().get('delSubscriptionRowId');
            system.debug('deleteSubscriptionAllocation(): rowId - ' + rowId);

            businessLayer.deleteSubscriptionAllocation(Integer.valueOf(rowid));
        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while deleting subscription allocation. ' + ex.getMessage()));
            system.debug('deleteSubscriptionAllocation(): Exception - ' + ex);
        }
        return null;

    }

    public pagereference saveSubscriptionAllocation(){

        try{

            Boolean success =  businessLayer.saveSubscriptionAllocation();
            if (success){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Saved Successfully.'));
                businessLayer = new AssetSubscriptionAllocationBusinessLayer(currentId);
                businessLayer.getSubscriptionRemainingQuantityNPercentage(Subscription);
            } else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'One or more line item(s) has error.'));
            }

        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while saving subscription allocations. ' + ex.getMessage()));
            system.debug('saveSubscriptionAllocation(): Exception - ' + ex);
            system.debug('saveSubscriptionAllocation(): ' + ex.getStackTraceString());
        }
        return null;

    }

    public pagereference changeAsset(){

        try{
            String rowId = ApexPages.currentPage().getParameters().get('newAssetRowId');
            system.debug('changeAsset(): rowId - ' + rowId);

            businessLayer.changeAsset(Integer.valueOf(rowid));
//            if(SelAsset != null)
//                remainingQuantity = SelAsset.RemainingQuantity__c;

        } catch (Exception ex){
            system.debug('changeAsset(): Exception - ' + ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while retrieving the asset.'));
        }
        return null;

    }

    public pagereference changeSubscription(){

        try{
            String rowId = ApexPages.currentPage().getParameters().get('newSubscriptionRowId');
            system.debug('changeSubscription(): rowId - ' + rowId);

            businessLayer.changeSubscription(Integer.valueOf(rowid));

        } catch (Exception ex){
            system.debug('changeSubscription(): Exception - ' + ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while retrieving the Subscription.'));
        }
        return null;

    }

    public pagereference cancel(){

        return new PageReference('/'+currentId).setRedirect(true);
    }

}