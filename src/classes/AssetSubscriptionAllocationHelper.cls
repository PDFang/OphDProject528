/**
 * Created by ravish.chawla on 10/12/2017.
 */

public class AssetSubscriptionAllocationHelper {

    public Asset currentAsset;
    public SubscriptionReplica__c currentSubscription;
    public Project__c currentProject;
//    public Boolean isSuccesfullySaved;

    public List<AssetSubscriptionAllocationNewModel> assetAllocations{get; set;}
    public List<AssetSubscriptionAllocationNewModel> subscriptionAllocations{get; set;}
    Static Set<String> assetEditableFields = new Set<String>();
    Static Set<String> subscriptionEditableFields = new Set<String>();

    static Set<String> assetFields = new Set<String>{
            'Id',
            'Name',
            'RecordType.Name',
            'Quantity',
            'Budgeted_Hours__c',
            'Parent_Project__c'
    };

    static Set<String> subscriptionFields = new Set<String>{
            'Id',
            'Name',
            'Quantity__c',
            'Budgeted_Hours__c',
            'ParentProject__c'
    };

    static Set<String> projectFields = new Set<String>{
            'Id',
            'Name',
            'RecordType.Name',
            'ParentProject__c',
            'ParentProject__r.Name',
            'Project_Phase__c'
    };

    // constructor
    public AssetSubscriptionAllocationHelper(String idParam){

        // entry from an asset
        String sObjType = AssetSubscriptionAllocationHelper.getSObjectType(idParam);
        if(sObjType == 'Asset'){
            currentAsset = getAsset(idParam);
            system.debug('getAsset(): currentAsset - ' + currentAsset);

            if(currentAsset == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No asset record found.'));
                return;
            }

            //getAssetAllocations();

        }
        // entry from a subscription
        else if(sObjType == 'Subscription'){

            currentSubscription = getSubscription(idParam);
            system.debug('getAsset(): currentSubscription - ' + currentSubscription);

            if(currentSubscription == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No subscription record found.'));
                return;
            }

            //getSubscriptionAllocations();

        }
        // entry from project
        else if(sObjType == 'Project'){
            getProject(idParam);
            if(currentProject != null){
                system.debug('Initalizing allocation collections');
                //getAssetAllocations();
                //getSubscriptionAllocations();
            }
        }
        // invalid entry
        else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'URL: Invalid ID Parameter.'));
        }

    }


    // fetch project details
    private void getProject(String projectId){

        List<Schema.FieldSetMember> fsMembers = Schema.SobjectType.Project__c.fieldSets.PS_Project_Allocation.getFields();
        for(Schema.FieldSetMember member : fsMembers){
            projectFields.add(member.getFieldPath());
        }

        List<String> fieldList = new List<String>(projectFields);

        String columns = String.join(fieldList, ',');
        system.debug('getProject(): columns - ' + columns);

        String soql = 'Select ' + columns + ' From Project__c where Id = \'' + projectId + '\' and RecordType.Name like \'PS Project Phase%\'';
        system.debug('getProject(): soql - ' + soql);

        List<Project__c> projects = Database.query(soql);

        if(projects.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No project record found.'));
            return;
        }
        currentProject = projects[0];

        system.debug('getProject(): currentProject - ' + currentProject);

    }

    // fetch asset details
    private Asset getAsset(String assetId){


        List<Schema.FieldSetMember> fsMembers = Schema.SobjectType.Asset.fieldSets.PS_Asset_Allocation.getFields();
        for(Schema.FieldSetMember member : fsMembers){
            assetFields.add(member.getFieldPath());
        }

        List<Schema.FieldSetMember> fsMembersAssetEditable = Schema.SobjectType.Asset.fieldSets.PS_Asset_Allocation_Editable_Fields.getFields();
        for(Schema.FieldSetMember member : fsMembersAssetEditable){
            assetEditableFields.add(member.getFieldPath());
        }
        List<String> fieldList = new List<String>(assetFields);
        fieldList.addAll(assetEditableFields);

        String columns = String.join(fieldList, ',');
        system.debug('getAsset(): columns - ' + columns);

        String soql = 'Select ' + columns + ' From Asset where Id = \'' + assetId + '\'';
        system.debug('getAsset(): soql - ' + soql);

        List<Asset> assets = Database.query(soql);
        system.debug('getAsset(): assets - ' + assets);

        if(assets.isEmpty()){
            return null;
        }

        return assets[0];

    }

    // fetch subscription details
    private SubscriptionReplica__c getSubscription(String subscriptionId){

        List<Schema.FieldSetMember> fsMembers = Schema.SobjectType.SubscriptionReplica__c.fieldSets.PS_Subscription_Allocation.getFields();
        for(Schema.FieldSetMember member : fsMembers){
            subscriptionFields.add(member.getFieldPath());
        }

        List<Schema.FieldSetMember> fsMembersSubsEditable = Schema.SobjectType.Asset.fieldSets.PS_Asset_Allocation_Editable_Fields.getFields();
        for(Schema.FieldSetMember member : fsMembersSubsEditable){
            subscriptionEditableFields.add(member.getFieldPath());
        }

        List<String> fieldList = new List<String>(subscriptionFields);
        fieldList.addAll(subscriptionEditableFields);

        String columns = String.join(fieldList, ',');
        system.debug('getSubscription(): columns - ' + columns);

        String soql = 'Select ' + columns + ' From SubscriptionReplica__c where Id = \'' + subscriptionId + '\'';
        system.debug('getSubscription(): soql - ' + soql);

        List<SubscriptionReplica__c> subscriptions = Database.query(soql);

        system.debug('getSubscription(): subscriptions - ' + subscriptions);

        if(subscriptions.isEmpty()){
            return null;
        }

        return subscriptions[0];

    }

    public static String getSObjectType(String IdParam){
        if(idParam.left(3) == Schema.SObjectType.Asset.getKeyPrefix()){
            return 'Asset';
        }
        // entry from a subscription
        else if(idParam.left(3) == Schema.SObjectType.SubscriptionReplica__c.getKeyPrefix()){
            return 'Subscription';

            //getSubscriptionAllocations();

        }
        // entry from project
        else if(idParam.left(3) == Schema.SObjectType.Project__c.getKeyPrefix()){
            return 'Project';
                //getAssetAllocations();
                //getSubscriptionAllocations();
        }
        // invalid entry
        else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'URL: Invalid ID Parameter.'));
        }
        return null;
    }

    // fetch Project Asset Allocations
    public static String getAssetAllocations(String projectId, String assetId){

        List<AssetSubscriptionAllocationNewModel> assetAllocations = new List<AssetSubscriptionAllocationNewModel>();

        String soql = 'Select Project__c, Project__r.Name, Name, ProjectPhase__c, Percent_Allocation__c, Asset__r.Name, Asset__c, Asset__r.Quantity, Asset__r.Budgeted_Hours__c, '
                + 'Quantity_Allocation__c, Hours_Allocated__c, Asset__r.Total_Allocated_Quantity__c, Asset__r.Total_Allocated_Hours__c '
                + 'from Project_Asset_Allocation__c where ';

        if(projectId != null){
            soql += ' Project__c = \'' + projectId + '\'';
        } else{
            soql += ' Asset__c = \'' + assetId + '\'';
        }
        soql += ' order by createddate DESC ';

        List<Project_Asset_Allocation__c> allocations = Database.query(soql);
        for(Project_Asset_Allocation__c allocation : allocations){
            AssetSubscriptionAllocationNewModel newModel = new AssetSubscriptionAllocationNewModel(allocation);
            assetAllocations.add(newModel);
        }

        system.debug('getAssetAllocations(): assetAllocations - ' + assetAllocations);

        if(assetAllocations.size() > 0)
            return JSON.serialize(assetAllocations);

        return null;

    }


    // fetch Project Subscription Allocation
    public static String getSubscriptionAllocations(String projectId, String subscriptionId){

        List<AssetSubscriptionAllocationNewModel> subscriptionAllocations = new List<AssetSubscriptionAllocationNewModel>();

        String soql = 'Select Project__c, Project__r.Name, Subscription__r.Subscription__r.SBQQ__Product__r.Name, Subscription__r.Subscription__r.SBQQ__Product__c,' +
                ' Subscription__c, Subscription__r.Name, Name, ProjectPhase__c, Subscription__r.Quantity__c, Subscription__r.Budgeted_Hours__c, Percent_Allocation__c, Quantity_Allocation__c, Hours_Allocated__c, Subscription__r.Total_Allocated_Quantity__c, Subscription__r.Total_Allocated_Hours__c '
                + 'from Project_Subscription_Allocation__c where ';
        if(projectId != null){
            soql += ' Project__c = \'' + projectId + '\'';
        } else{
            soql += ' Subscription__c = \'' + subscriptionId + '\'';
        }
        soql += ' order by createddate DESC ';

        List<Project_Subscription_Allocation__c> allocations = Database.query(soql);
        for(Project_Subscription_Allocation__c allocation : allocations){
            AssetSubscriptionAllocationNewModel newModel = new AssetSubscriptionAllocationNewModel(allocation);
            subscriptionAllocations.add(newModel);
        }

        system.debug('getSubscriptionAllocations(): subscriptionAllocations - ' + subscriptionAllocations);

        if(subscriptionAllocations.size() > 0)
            return JSON.serialize(subscriptionAllocations);

        return null;

    }



    // fetch Project Subscription Allocation
    public static String getPhaseProjectDetails(String objId, string objType){
        Asset thisAsset;
        SubscriptionReplica__c thisSubscription;
        string ProjectId;
        List<Project__c> projects;

        if(objType == 'Asset'){
            thisAsset = [select Parent_Project__c from Asset WHere Id = :objId limit 1];
            ProjectId  = thisAsset.Parent_Project__c;
        }else if(objType == 'Subscription'){
            thisSubscription = [select ParentProject__c from SubscriptionReplica__c WHere Id = :objId limit 1];
            ProjectId = thisSubscription.ParentProject__c;
        }




        if(ProjectId != null){

            String soql = 'Select Id, Name, Summary__c, ProjectStatus__c, Phase__c ' +
                    + ' from Project__c where ';

            soql += ' ParentProject__c = \'' + ProjectId + '\'';

            soql += ' order by createddate ';

            projects = Database.query(soql);
        }


        if(projects.size() > 0)
            return JSON.serialize(projects);

        return null;

    }

    public static void SaveAssetSubscriptionAllocation(String objType, AssetSubscriptionAllocationNewModel assetSubscriptionAllocation){
        try{
            if(objType == 'Asset'){
                Project_Asset_Allocation__c projectAssetAllocation = new Project_Asset_Allocation__c(
                        Asset__c = assetSubscriptionAllocation.Asset,
                        Id = assetSubscriptionAllocation.AssetAllocationId == '' ? null : assetSubscriptionAllocation.AssetAllocationId,
                        Project__c = assetSubscriptionAllocation.ProjectNumber,
                        Quantity_Allocation__c = assetSubscriptionAllocation.AllocatedQuantity,
                        Percent_Allocation__c = assetSubscriptionAllocation.AllocatedPercentage,
                        Hours_Allocated__c = assetSubscriptionAllocation.AllocatedHours
                );

                upsert projectAssetAllocation;
            }
            else if(objType == 'Subscription'){
                Project_Subscription_Allocation__c projectSubscriptionAllocation = new Project_Subscription_Allocation__c(
                        Subscription__c = assetSubscriptionAllocation.Subscription,
                        Id = assetSubscriptionAllocation.SubscriptionAllocationId == '' ? null : assetSubscriptionAllocation.SubscriptionAllocationId,
                        Project__c = assetSubscriptionAllocation.ProjectNumber,
                        Quantity_Allocation__c = assetSubscriptionAllocation.AllocatedQuantity,
                        Percent_Allocation__c = assetSubscriptionAllocation.AllocatedPercentage,
                        Hours_Allocated__c = assetSubscriptionAllocation.AllocatedHours
                );

                upsert projectSubscriptionAllocation;
            }
        }catch (Exception ex){
            throw ex;
        }

    }

    // fetch Project Subscription Allocation
    public static String getAssetSubscriptionDetailsFromProjectPhase(String projId, String objType){

        Project__c thisProject = [select ParentProject__c from Project__c WHere Id = :projId limit 1];

        if(objType == 'Asset'){
            String soql = 'Select Id, Name, Remaning_Percentage__c, Quantity, Budgeted_Hours__c, RemainingQuantity__c, Remaining_Hours__c ' +
                    + ' from Asset where ';
            if(projId != null){
                soql += ' Parent_Project__c = \'' + thisProject.ParentProject__c + '\'';
            }

            soql += ' order by createddate ';

            List<Asset> assets = Database.query(soql);

            if(assets.size() > 0)
                return JSON.serialize(assets);
        }
        else if(objType == 'Subscription'){
            system.debug('objType - ' + objType);
            String soql = 'Select Id, Name,Budgeted_Hours__c, Quantity__c, Product_Name__c, Remaning_Percentage__c, RemainingQuantity__c, Remaining_Hours__c ' +
                    + ' from SubscriptionReplica__c where ';
            if(projId != null){
                soql += ' ParentProject__c = \'' + thisProject.ParentProject__c + '\'';
            }

            soql += ' order by createddate ';

            List<SubscriptionReplica__c> subscriptions = Database.query(soql);
            system.debug('subscriptions - ' + subscriptions);
            if(subscriptions.size() > 0)
                return JSON.serialize(subscriptions);


        }


        return null;

    }

    public static void DeleteAllocation(String allocationId, String objType){
        try{
            if(objType == 'Asset'){

                String soql = 'Select Id, Name' +
                        + ' from Project_Asset_Allocation__c where ';
                if(allocationId != null){
                    soql += ' Id = \'' + allocationId + '\'';
                }

                List<Project_Asset_Allocation__c> assetAllocation = Database.query(soql);

                if(assetAllocation.size() > 0)
                    delete assetAllocation;
            }
            else if(objType == 'Subscription'){
                String soql = 'Select Id, Name' +
                        + ' from Project_Subscription_Allocation__c where ';
                if(allocationId != null){
                    soql += ' Id = \'' + allocationId + '\'';
                }

                List<Project_Subscription_Allocation__c> subscriptionAllocation = Database.query(soql);

                if(subscriptionAllocation.size() > 0)
                    delete subscriptionAllocation;
            }
        }catch (Exception ex){

        }
    }

    public String SaveCancSuspQuantity(Asset asset){
        String result;
        Boolean manager = isManager();
        try{
            System.debug('asset.QuantityCancelled__c' + asset.QuantityCancelled__c);
            if(asset.QuantityCancelled__c > 0 && (asset.Department_Responsible__c == null
                    || asset.Root_Cause__c == null)){
                return 'Department Responsible or ' +
                        'Root Cause can not be empty if Quantity Cancelled is greater than 0.';


            }
            else if(asset.QuantityonHold__c > 0 && (asset.Department_Responsible__c == null
                    || asset.Root_Cause__c == null)){
                return 'Department Responsible or ' +
                        'Root Cause can not be empty if Quantity On Hold is greater than 0.';

            }
            else if((asset.QuantityCancelled__c >= asset.Quantity
                    || asset.QuantityonHold__c >= asset.Quantity) && !manager){
                return 'Only managers can suspend or cancel the entire quantity of an asset or subscription.';
            }
            else{
                update asset;
//                isSuccesfullySaved = true;
                return 'Saved Successfully.';

            }


        }catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }


    public String SaveCancSuspQuantitySubs(SubscriptionReplica__c subscription){
        String result;
        Boolean manager = isManager();
        try{
            System.debug('subscription.QuantityCancelled__c' + subscription.QuantityCancelled__c);
            if(subscription.QuantityCancelled__c > 0 && (subscription.Department_Responsible__c == null
                    || subscription.Root_Cause__c == null)){
                return 'Department Responsible or ' +
                        'Root Cause can not be empty if Quantity Cancelled is greater than 0.';


            }
            else if(subscription.QuantityonHold__c > 0 && (subscription.Department_Responsible__c == null
                    || subscription.Root_Cause__c == null)){
                return 'Department Responsible or ' +
                        'Root Cause can not be empty if Quantity On Hold is greater than 0.';

            }
            else if((subscription.QuantityCancelled__c >= subscription.Quantity__c
                    || subscription.QuantityonHold__c >= subscription.Quantity__c) && !manager){
                return 'Only managers can suspend or cancel the entire quantity of an asset or subscription.';
            }
            else{
                update subscription;
//                isSuccesfullySaved = true;
                return 'Saved Successfully.';

            }


        }catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }

    public Boolean isManager(){
        List<GroupMember> allGroupIDs = [SELECT Id, group.id, group.name FROM GroupMember
        where UserOrGroupId = :UserInfo.getUserId() AND group.DeveloperName ='Managers_Suspend_Cancel'];
        System.debug('allGroupIDs' + allGroupIDs);
        if(allGroupIDs.size() > 0)
            return true;

        return false;

    }
}