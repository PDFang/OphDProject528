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
    public static String currentId{get;set;}
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
    @RemoteAction
    public static String getObjectType(String idParam){
        String objType;
        objType = AssetSubscriptionAllocationHelper.getSObjectType(idParam);

        return objType;
    }

    //Get Asset Allocations Data
    @RemoteAction
    public static String getAssetAllocationData(String projectId, String idParam){

        String assetAllocationData = AssetSubscriptionAllocationHelper.getAssetAllocations(projectId, idParam);
        return assetAllocationData;
    }

    //Get Subscription Allocations Data
    @RemoteAction
    public static String getSubscriptionAllocationData(String projectId, String idParam){
        system.debug('getSubscriptionAllocationData(): currentId - ' + currentId);
        system.debug('getSubscriptionAllocationData(): idParam - ' + idParam);
        String subscriptionAllocationData = AssetSubscriptionAllocationHelper.getSubscriptionAllocations(projectId, idParam);
        system.debug('getSubscriptionAllocationData(): subscriptionAllocationData - ' + subscriptionAllocationData);
        return subscriptionAllocationData;
    }

    @RemoteAction
    public static String PhaseProjectDetails(String assetId){
        String ProjectData = AssetSubscriptionAllocationHelper.getPhaseProjectDetails(assetId);
        return ProjectData;
    }

    @RemoteAction
    public static String UpsertAssetSubscriptionAllocation(String objType, String allocationJson){
        String result;
        String message = '';
        try{
            system.debug('UpsertAssetSubscriptionAllocation(): allocationJson - '+allocationJson);
            AssetSubscriptionAllocationNewModel assetSubscriptionAllocation = (AssetSubscriptionAllocationNewModel)JSON.deserialize(allocationJson, AssetSubscriptionAllocationNewModel.class);
            AssetSubscriptionAllocationHelper.SaveAssetSubscriptionAllocation(objType, assetSubscriptionAllocation);
            result = 'Success';
        }
        catch (Exception ex){
            result = 'Failed';
            message = ex.getMessage();
        }
        return sendResponse(result, message);

    }

    @RemoteAction
    public static String AssetSubscriptionDetailsFromProjectPhase(String projId, String objType){
        String assetSubscriptionData = AssetSubscriptionAllocationHelper.getAssetSubscriptionDetailsFromProjectPhase(projId, objType);
        return assetSubscriptionData;
    }


    public pagereference cancel(){

        return new PageReference('/'+currentId).setRedirect(true);
    }

    private static string sendResponse(String result, string message){

        System.JSONGenerator generator = Json.createGenerator(true);
        generator.writeStartObject();
        generator.writeStringField('result', result);
        generator.writeStringField('message', message);
        return generator.getAsString();

    }

}