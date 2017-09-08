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

    public Decimal remainingQuantity {get; set;}
    public Decimal remainingPercentage {get; set;}
    public Decimal remainingBudgetedHours {get; set;}

    public Decimal remainingSubscriptionQuantity {get; set;}
    public Decimal remainingSubscriptionPercentage {get; set;}

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
            getAssetRemainingQuantityNPercentage();

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
                getAssetRemainingQuantityNPercentage();
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
            getSubscriptionRemainingQuantityNPercentage();
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
                getSubscriptionRemainingQuantityNPercentage();
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

    public void getAssetRemainingQuantityNPercentage(){
        if(Asset != null){
            if(Asset.Quantity != null && Asset.Quantity > 1)
                if(Asset.Total_Allocated_Quantity__c == null || Asset.Total_Allocated_Quantity__c == 0)
                    remainingQuantity = Asset.Quantity;
                else
                    remainingQuantity = Asset.Quantity - Asset.Total_Allocated_Quantity__c;

            if(Asset.Budgeted_Hours__c != null && Asset.Budgeted_Hours__c > 0){
                if(Asset.Total_Allocated_Hours__c == null || Asset.Total_Allocated_Hours__c == 0)
                    if(Asset.Quantity <= 1)
                        remainingPercentage = 100 - ((0/Asset.Budgeted_Hours__c) * 100);
                    else
                        remainingBudgetedHours = Asset.Budgeted_Hours__c;
                else
                    if(Asset.Quantity <= 1)
                        remainingPercentage = 100 -  (Asset.Total_Allocated_Hours__c/Asset.Budgeted_Hours__c) * 100;
                    else
                        remainingBudgetedHours = Asset.Budgeted_Hours__c - Asset.Total_Allocated_Hours__c;
            }

            else{
                if(Asset.Quantity <= 1)
                    remainingPercentage = 0;
                else
                    remainingBudgetedHours = 0;
            }

        }
    }

    public void getSubscriptionRemainingQuantityNPercentage(){
        if(Subscription != null){
            if(Subscription.Quantity__c != null && Subscription.Quantity__c > 1)
                if(Subscription.Total_Allocated_Quantity__c == null || Subscription.Total_Allocated_Quantity__c == 0)
                    remainingSubscriptionQuantity = Subscription.Quantity__c;
                else
                    remainingSubscriptionQuantity = Subscription.Quantity__c - Subscription.Total_Allocated_Quantity__c;

            if(Subscription.Budgeted_Hours__c != null && Subscription.Budgeted_Hours__c > 0){
                if(Subscription.Total_Allocated_Hours__c == null || Subscription.Total_Allocated_Hours__c == 0)
                    if(Subscription.Quantity__c <= 1)
                        remainingSubscriptionPercentage = 100 - ((0/Subscription.Budgeted_Hours__c) * 100);
                    else
                        remainingBudgetedHours = Subscription.Budgeted_Hours__c;
                else
                    if(Subscription.Quantity__c <= 1)
                        remainingSubscriptionPercentage = 100 -  (Subscription.Total_Allocated_Hours__c/Subscription.Budgeted_Hours__c) * 100;
                    else
                        remainingBudgetedHours = Subscription.Budgeted_Hours__c - Subscription.Total_Allocated_Hours__c;
            }

            else{
                if(Subscription.Quantity__c <= 1)
                    remainingSubscriptionPercentage = 0;
                else
                    remainingBudgetedHours = 0;
            }
        }
    }

}