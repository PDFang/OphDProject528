/**
 * Created by ravish.chawla on 10/12/2017.
 */

public with sharing class AssetSubscriptionAllocationNewController {

    // current asset record
    public Asset Asset{
        get {
            return helper != null
                    ? helper.currentAsset : null;
        }set{}
    }

    // current subscription record
    public SubscriptionReplica__c Subscription{
        get {
            return helper != null
                    ? helper.currentSubscription : null;
        }set{}
    }

    // current project record
    public Project__c Project{
        get {
            return helper != null
                    ? helper.currentProject : null;
        }set{}
    }

    Public boolean Manager{
        get{
            return helper != null
                    ? helper.isManager() : null;
        }set{}
    }

    // query string parameter
    public String currentId{get;set;}

    public boolean saveSuccess{get; set;}

    public list<ImplementedProduct__c> ImplementedProducts{get;private set;}
    // query string parameter
//    public Boolen isSuccesfullySaved{get;set;}
    //Helper Object
    private AssetSubscriptionAllocationHelper helper;


    // constructor
    public AssetSubscriptionAllocationNewController(){

        ImplementedProducts = new list<ImplementedProduct__c>();
        currentId = ApexPages.currentPage().getParameters().get('id');
        saveSuccess = true;
        system.debug('getAsset(): currentId - ' + currentId);

        if(String.isBlank(currentId)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid URL: Missing ID Parameter.'));
            return;
        }

        helper = new AssetSubscriptionAllocationHelper(currentId);
        ImplementedProducts = helper.currentImplementedProducts;
    }

    public void reloadDetails(){
        helper = new AssetSubscriptionAllocationHelper(currentId);
        this.Asset = helper.currentAsset != null ? helper.currentAsset : null;
        this.Subscription = helper.currentSubscription != null ? helper.currentSubscription : null;
        this.Project = helper.currentProject != null ? helper.currentProject : null;

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
        String subscriptionAllocationData = AssetSubscriptionAllocationHelper.getSubscriptionAllocations(projectId, idParam);
        return subscriptionAllocationData;
    }


    @RemoteAction
    public static String PhaseProjectDetails(String objId, string objType){
        String ProjectData = AssetSubscriptionAllocationHelper.getPhaseProjectDetails(objId, objType);
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
        catch (DmlException ex){
            result = 'Failed';
            message = ex.getMessage();
            Integer occurence;
            if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                occurence = message.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
                message = message.mid(occurence, message.length());
                occurence = message.lastIndexOf(':');
                message = message.mid(0, occurence);
            }
            else {
                message = ex.getMessage();
            }

        }
        return sendResponse(result, message);

    }

    @RemoteAction
    public static String AssetSubscriptionDetailsFromProjectPhase(String projId, String objType){
        String assetSubscriptionData = AssetSubscriptionAllocationHelper.getAssetSubscriptionDetailsFromProjectPhase(projId, objType);
        return assetSubscriptionData;
    }

    @RemoteAction
    public static String DeleteAllocation(String allocationId, String objType){
        String result;
        try{
            AssetSubscriptionAllocationHelper.DeleteAllocation(allocationId, objType);
            result = 'Success';
        }catch (Exception ex){
            result = 'Failed';
        }

        return result;
    }

    public void SaveCancSuspQuantity(){
        try{
            String message =  helper.SaveCancSuspQuantity(Asset);
            saveSuccess = true;
            if(message.contains('Saved')){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, message));
                saveSuccess = true;
            }
            else {
               // getUpdatedCancSuspValues();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
                saveSuccess = false;
            }

        }catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }

    }

    public void SaveCancSuspQuantitySubs(){
        System.debug('Subscription.QuantityCancelled__c' + Subscription.QuantityCancelled__c);
        try{
            saveSuccess = true;
            String message =  helper.SaveCancSuspQuantitySubs(Subscription);
            if(message.contains('Saved')){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, message));
                saveSuccess = true;
            }
            else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
                saveSuccess = false;
            }
        }catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            saveSuccess = false;
        }

    }


    public void saveImplementedProduct(){
        if(Asset != null){
            String SelectedRowId = ApexPages.CurrentPage().getParameters().get('rowid');
            helper.SaveImmplementedProductAsset(Asset.Id, SelectedRowId);
        }
        if(Subscription != null){
            String SelectedRowId = ApexPages.CurrentPage().getParameters().get('rowid');
            helper.SaveImmplementedProductSubscription(Subscription.Id, SelectedRowId);
        }
        reloadDetails();
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