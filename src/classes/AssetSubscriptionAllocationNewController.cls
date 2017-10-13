/**
 * Created by ravish.chawla on 10/12/2017.
 */

public with sharing class AssetSubscriptionAllocationNewController {

    // current asset record
    public Asset Asset{
        get {
            return helper != null
                    ? helper.currentAsset : null;
        }
    }

    // current subscription record
    public SubscriptionReplica__c Subscription{
        get {
            return helper != null
                    ? helper.currentSubscription : null;
        }
    }

    // current project record
    public Project__c Project{
        get {
            return helper != null
                    ? helper.currentProject : null;
        }
    }

    // query string parameter
    public static String currentId;
    //Helper Object
    private AssetSubscriptionAllocationHelper helper;

    // constructor
    public AssetSubscriptionAllocationNewController(){

        currentId = ApexPages.currentPage().getParameters().get('id');

        system.debug('getAsset(): currentId - ' + currentId);

        if(String.isBlank(currentId)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid URL: Missing ID Parameter.'));
            return;
        }

        helper = new AssetSubscriptionAllocationHelper(currentId);

    }

    //Get object type from ID
    public static String getObjectType(String idParam){
        String objType;
        objType = AssetSubscriptionAllocationHelper.getSObjectType(idParam);

        return objType;
    }

    //Get Asset Allocations Data
    public static String getAssetAllocationData(String projectId, String idParam){

        String assetAllocationData = AssetSubscriptionAllocationHelper.getAssetAllocations(projectId, idParam);
        return assetAllocationData;
    }

    //Get Subscription Allocations Data
    public static String getSubscriptionAllocationData(String projectId, String idParam){

        String subscriptionAllocationData = AssetSubscriptionAllocationHelper.getSubscriptionAllocations(projectId, idParam);
        return subscriptionAllocationData;
    }

    public pagereference cancel(){

        return new PageReference('/'+currentId).setRedirect(true);
    }

}