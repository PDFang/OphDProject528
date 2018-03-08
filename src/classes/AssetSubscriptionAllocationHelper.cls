/**
 * Created by ravish.chawla on 10/12/2017.
 */

public class AssetSubscriptionAllocationHelper {

    public Asset currentAsset;
    public SubscriptionReplica__c currentSubscription;
    public Project__c currentProject;
    public list<ImplementedProduct__c> currentImplementedProducts;
//    public Boolean isSuccesfullySaved;

    public List<AssetSubscriptionAllocationNewModel> assetAllocations{get; set;}
    public List<AssetSubscriptionAllocationNewModel> subscriptionAllocations{get; set;}
    Static Set<String> assetEditableFields = new Set<String>();
    Static Set<String> subscriptionEditableFields = new Set<String>();

    static Set<String> assetFields = new Set<String>{
            'Id',
            'Name',
            'AccountId',
            'RecordType.Name',
            'Quantity',
            'Budgeted_Hours__c',
            'Parent_Project__c',
            'ImplementedProduct__c',
            'Total_Implemented_Quantity__c',
            'RemainingQuantity__c',
            'Remaning_Percentage__c'

    };

    static Set<String> subscriptionFields = new Set<String>{
            'Id',
            'Name',
            'Subscription__r.SBQQ__Account__c',
            'Quantity__c',
            'Budgeted_Hours__c',
            'ParentProject__c',
            'Implemented_Product__c',
            'Total_Implemented_Quantity__c',
            'RemainingQuantity__c',
            'Remaning_Percentage__c'
    };

    static Set<String> projectFields = new Set<String>{
            'Id',
            'Name',
            'RecordType.Name',
            'ParentProject__c',
            'ParentProject__r.Name',
            'Project_Phase__c',
            'Phase_Status__c',
            'ActualProjectGoLiveDate__c',
            'Project_Phase_Allocation__c'
    };

    static Set<String> IPFields = new Set<String>{
            'Id',
            'Name',
            'Account__c',
            'Product__c',
            'GoLiveDate__c',
            'EstimatedGoLiveDate__c',
            'Status__c'
    };

    // constructor
    public AssetSubscriptionAllocationHelper(String idParam){

        // entry from an asset
        currentImplementedProducts = new list<ImplementedProduct__c>();
        String sObjType = AssetSubscriptionAllocationHelper.getSObjectType(idParam);
        if(sObjType == 'Asset'){
            currentAsset = getAsset(idParam);
            system.debug('getAsset(): currentAsset - ' + currentAsset);

            if(currentAsset == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No asset record found.'));
                return;
            }
            getImplementedProductList(currentAsset.AccountId);

        }
        // entry from a subscription
        else if(sObjType == 'Subscription'){

            currentSubscription = getSubscription(idParam);
            system.debug('getAsset(): currentSubscription - ' + currentSubscription);

            if(currentSubscription == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No subscription record found.'));
                return;
            }
            getImplementedProductList(currentSubscription.Subscription__r.SBQQ__Account__c);

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

    private void getImplementedProductList(string acctId){
        List<String> fieldList = new List<String>(IPFields);
        String columns = String.join(fieldList, ',');
        String queryString = 'Select ' + columns + ' From ImplementedProduct__c where Account__c = \'' + acctId + '\'';
        system.debug('getImplementedProductList(): soql - ' + queryString);
        currentImplementedProducts = Database.query(queryString);
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

        List<Schema.FieldSetMember> fsMembersSubsEditable = Schema.SobjectType.SubscriptionReplica__c.fieldSets.PS_Subscription_Alloc_Editable_Fields.getFields();
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
                + 'Quantity_Allocation__c, Hours_Allocated__c, Asset__r.Total_Allocated_Quantity__c, Asset__r.Total_Allocated_Hours__c, Implemented__c,  '
                + 'Asset__r.QuantityonHold__c, Asset__r.QuantityCancelled__c, Asset__r.RemainingQuantity__c, Asset__r.Remaning_Percentage__c,On_Hold__c '
                + ' from Project_Asset_Allocation__c where ';

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
                ' Subscription__c, Subscription_Name__c, Subscription__r.Name, Name, ProjectPhase__c, Subscription__r.Quantity__c, Subscription__r.Budgeted_Hours__c, Percent_Allocation__c,'+
                ' Quantity_Allocation__c, Hours_Allocated__c, Subscription__r.Total_Allocated_Quantity__c, Subscription__r.Total_Allocated_Hours__c,Implemented__c, ' +
                ' Subscription__r.QuantityonHold__c, Subscription__r.QuantityCancelled__c, Subscription__r.RemainingQuantity__c, Subscription__r.Remaning_Percentage__c,On_Hold__c ' +
                ' from Project_Subscription_Allocation__c where ';
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
        List<Project__c> projects = new list<Project__c>();

        if(objType == 'Asset'){
            thisAsset = [select Parent_Project__c from Asset WHere Id = :objId limit 1];
            ProjectId  = thisAsset.Parent_Project__c == null ? '' : thisAsset.Parent_Project__c;
        }else if(objType == 'Subscription'){
            thisSubscription = [select ParentProject__c from SubscriptionReplica__c WHere Id = :objId limit 1];
            ProjectId = thisSubscription.ParentProject__c == null ? '' : thisSubscription.ParentProject__c;
        }


        if(ProjectId != null && ProjectId != ''){
            String soql = 'Select Id, Name, Summary__c, ProjectStatus__c, Phase__c , Phase_Status__c ' +
                    + ' from Project__c where ';
            soql += ' ParentProject__c = \'' + ProjectId + '\'';
            soql += ' AND Id NOT IN(SELECT Project__c FROM Project_' + objType + '_Allocation__c WHERE ' + objType + '__c = \'' + objId + '\')';
            soql += ' And Phase_Status__c NOT IN (\'Cancelled\', \'Closed\', \'Suspended\')';
            soql += ' and ActualProjectGoLiveDate__c = null order by createddate ';

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
                        Hours_Allocated__c = assetSubscriptionAllocation.AllocatedHours,
                        On_Hold__c = assetSubscriptionAllocation.OnHold
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
                        Hours_Allocated__c = assetSubscriptionAllocation.AllocatedHours,
                        On_Hold__c = assetSubscriptionAllocation.OnHold
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
            String soql = 'Select Id, Name, Remaning_Percentage__c, Quantity, Budgeted_Hours__c, RemainingQuantity__c, Remaining_Hours__c, QuantityCancelled__c, QuantityonHold__c ' +
                    + ' from Asset where Id NOT IN(SELECT Asset__c FROM Project_Asset_Allocation__c WHERE Project__c = \'' + projId + '\')';
            if(projId != null){
                soql += ' AND Parent_Project__c = \'' + thisProject.ParentProject__c + '\'';
            }

            soql += ' and FullyImplemented__c = false and RemainingQuantity__c > 0 order by createddate ';

            List<Asset> assets = new List<Asset>();

            for(Asset ast : Database.query(soql)){
                if(ast.Quantity == 1 && ast.RemainingQuantity__c <= 0){
                    continue;
                }
                assets.add(ast);
            }

            if(assets.size() > 0)
                return JSON.serialize(assets);
        }
        else if(objType == 'Subscription'){
            system.debug('objType - ' + objType);
            String soql = 'Select Id, Name,Budgeted_Hours__c, Quantity__c, Subscription_Name__c, Remaning_Percentage__c, RemainingQuantity__c, Remaining_Hours__c, QuantityCancelled__c, QuantityonHold__c ' +
                    + ' from SubscriptionReplica__c where Id NOT IN(SELECT Subscription__c FROM Project_Subscription_Allocation__c WHERE Project__c = \'' + projId + '\')';
            if(projId != null){
                soql += ' AND ParentProject__c = \'' + thisProject.ParentProject__c + '\'';
            }

            soql += ' and FullyImplemented__c = false and RemainingQuantity__c > 0  order by createddate ';

            List<SubscriptionReplica__c> subscriptions = new List<SubscriptionReplica__c>();

            for(SubscriptionReplica__c sub :Database.query(soql)){
                if(sub.Quantity__c == 1 && sub.Remaning_Percentage__c <= 0){
                    continue;
                }
                subscriptions.add(sub);
            }

            system.debug('subscriptions - ' + subscriptions);
            if(subscriptions.size() > 0)
                return JSON.serialize(subscriptions);


        }


        return null;

    }

    public static string DeleteAllocation(String allocationId, String objType){
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

            return 'success';

        }catch (Exception ex){
            return ex.getMessage();
        }
    }

    public String SaveCancSuspQuantity(Asset asset){
        String result;
        Boolean manager = isManager();
        try{

            Asset queryAsset = [select QuantityCancelled__c, Department_Responsible__c,Additional_Detail__c,Root_Cause__c from Asset where id =: asset.Id ];

            if(asset.get('QuantityCancelled__c') == null){
                return 'Required fields are missing. Quantity Cancelled cannot be blank';
            }
            if(asset.get('QuantityCancelled__c') == null){
                asset.QuantityCancelled__c = 0;
            }

            decimal quantityCancelled = Decimal.valueOf(string.valueOf(asset.get('QuantityCancelled__c'))) ;

            if(quantityCancelled == queryAsset.QuantityCancelled__c){
                if(asset.get('Department_Responsible__c') != queryAsset.Department_Responsible__c
                        || asset.get('Root_Cause__c') != queryAsset.Root_Cause__c
                        || asset.get('Additional_Detail__c') != queryAsset.Additional_Detail__c){
                    callSaveAsset(asset);
                    return 'Saved successfully.';
                }
                else
                        return 'No changes were made';
            }
            if(quantityCancelled != null && Math.floor(quantityCancelled) != quantityCancelled){
                return 'Decimal value is not allowed for Cancelled Quantity';

            }
            if(quantityCancelled > 0 && (asset.get('Department_Responsible__c') == null
                    || asset.get('Root_Cause__c') == null)){
                return 'Department Responsible and Root Cause must be populated if the Quantity on Hold is greater than 0';

            }

            else if(quantityCancelled > 0 && asset.get('Additional_Detail__c') == null){
                return 'Additional Detail must be populated if the Quantity Cancelled is greater than 0';

            }

            else if(quantityCancelled > asset.Quantity){
                return '"Cancelled Quantity" cannot exceed the contract quantity';
            }
            else if(quantityCancelled > asset.RemainingQuantity__c){
                if((asset.Total_Implemented_Quantity__c  > 0 && (asset.Total_Allocated_Quantity__c - asset.Total_Implemented_Quantity__c) > 0)
                        || asset.Total_Implemented_Quantity__c == 0){
                    return '“Cancelled Quantity” cannot exceed remaining quantity. Please modify or delete existing allocations if the remaining quantity needs to be increased.';
                }
                if(quantityCancelled > (asset.Quantity - asset.Total_Implemented_Quantity__c) && asset.Total_Implemented_Quantity__c  > 0){
                    return '"Cancelled Quantity" cannot exceed the remaining quantity';
                }
                else{
                    callSaveAsset(asset);
                    return 'Saved successfully.';
                }

            }
            else{
                callSaveAsset(asset);
                return 'Saved successfully.';
            }


        }catch (Exception ex){
            return ex.getMessage();
        }
        return null;
    }

    public void callSaveAsset(Asset asset){
        update asset;
    }


    public String SaveCancSuspQuantitySubs(SubscriptionReplica__c subscription){
        String result;
        Boolean manager = isManager();
        try{
            System.debug('subscription.QuantityCancelled__c' + subscription.QuantityCancelled__c);
            if(subscription.get('QuantityCancelled__c') == null ){
                return 'Required fields are missing. Quantity Cancelled and/or Quantity on Hold cannot be blank';
            }

            if(subscription.get('QuantityCancelled__c') == null){
                subscription.QuantityCancelled__c = 0;
            }

            SubscriptionReplica__c querySubscription = [select QuantityCancelled__c, Department_Responsible__c,Additional_Detail__c,Root_Cause__c from SubscriptionReplica__c where id =: subscription.Id ];

            decimal quantityCancelled = Decimal.valueOf(string.valueOf(subscription.get('QuantityCancelled__c'))) ;

            if(quantityCancelled == querySubscription.QuantityCancelled__c){
                if(subscription.get('Department_Responsible__c') != querySubscription.Department_Responsible__c
                        || subscription.get('Root_Cause__c') != querySubscription.Root_Cause__c
                        || subscription.get('Additional_Detail__c') != querySubscription.Additional_Detail__c){
                    callSavesubscription(subscription);
                    return 'Saved successfully.';
                }
                else
                        return 'No changes were made';
            }

            if(quantityCancelled != null && Math.floor(quantityCancelled) != quantityCancelled){
                return 'Decimal value is not allowed for Cancelled Quantity';

            }
            else if(quantityCancelled > 0 && (subscription.get('Department_Responsible__c') == null
                    || subscription.get('Root_Cause__c') == null)){
                return 'Department Responsible and Root Cause must be populated if the Quantity Cancelled is greater than 0';
            }
            else if(quantityCancelled > 0 && subscription.get('Additional_Detail__c') == null){
                return 'Additional Detail must be populated if the Quantity Cancelled is greater than 0';

            }
            else if(quantityCancelled > subscription.Quantity__c){
                return '"Cancelled Quantity" cannot exceed the contract quantity';
            }
            else if(quantityCancelled > subscription.RemainingQuantity__c){

                if((subscription.Total_Implemented_Quantity__c  > 0 && (subscription.Total_Allocated_Quantity__c - subscription.Total_Implemented_Quantity__c) > 0)
                        || subscription.Total_Implemented_Quantity__c == 0){
                    return '“Cancelled Quantity” cannot exceed remaining quantity. Please modify or delete existing allocations if the remaining quantity needs to be increased.';
                }
                if(quantityCancelled > (subscription.Quantity__c - subscription.Total_Implemented_Quantity__c) && subscription.Total_Implemented_Quantity__c  > 0){
                    return '"Cancelled Quantity" cannot exceed the remaining quantity';
                }
                else{
                    callSaveSubscription(subscription);
                    return 'Saved successfully.';
                }
            }
            else{
                callSaveSubscription(subscription);
                return 'Saved successfully.';
            }


        }catch (Exception ex){
            return ex.getMessage();
        }
        return null;
    }

    public void callSaveSubscription(SubscriptionReplica__c subscription){
        update subscription;
    }

    public string deleteNonImplementedAssetAllocations(id assetId){
	    try{
		    delete [select Id from Project_Asset_Allocation__c where Implemented__c = false and Asset__c =: assetId];
		    return 'success';
	    }catch (Exception ex){
		    return ex.getMessage();
	    }


    }

    public string deleteNonImplementedSubsAllocations(id subscId){
        try{
	        delete [select Id from Project_Subscription_Allocation__c where Implemented__c = false and Subscription__c =: subscId];
	        return 'success';
        }catch (Exception ex){
			return ex.getMessage();
		}

    }

    public Boolean isManager(){
        List<GroupMember> allGroupIDs = [SELECT Id, group.id, group.name FROM GroupMember
        where UserOrGroupId = :UserInfo.getUserId() AND group.DeveloperName ='PS_Projects_Assets_Management'];
        System.debug('allGroupIDs' + allGroupIDs);
        if(allGroupIDs.size() > 0)
            return true;

        return false;

    }

    public void SaveImmplementedProductAsset(Id assetId, string IPProduct){
        Asset saveAsset = new Asset(Id = assetId,
                ImplementedProduct__c = IPProduct);
        update saveAsset;
    }

    public void SaveImmplementedProductSubscription(Id subscriptionId, string IPProduct){
        SubscriptionReplica__c saveReplica = new SubscriptionReplica__c(Id = subscriptionId,
                Implemented_Product__c = IPProduct);
        update saveReplica;
    }

	public static string SaveAllAllocations(List<string> assetIds, list<string> subscriptionIds, string projectId){
		if(projectId == null)
			return 'No Project Id found. Allocations were not saved.';
		try{
			if(assetIds != null && assetIds.size() > 0){
				set<string> stAssetIds = new Set<string>();
				stAssetIds.addAll(assetIds);
				List<Project_Asset_Allocation__c> allocationLists = new List<Project_Asset_Allocation__c>();
				for(Asset a : [select Id, RemainingQuantity__c,Remaning_Percentage__c, Remaining_Hours__c from Asset where Id in: stAssetIds]) {
					allocationLists.add(
							new Project_Asset_Allocation__c(
									Asset__c = a.Id,
									Project__c = projectId,
									Quantity_Allocation__c = a.RemainingQuantity__c,
									Percent_Allocation__c = a.Remaning_Percentage__c,
									Hours_Allocated__c = a.Remaining_Hours__c
							)
					);
				}

				insert allocationLists;

			}
			if(subscriptionIds != null && subscriptionIds.size() > 0){
				set<string> stSubscriptionIds = new Set<string>();
				stSubscriptionIds.addAll(subscriptionIds);
				List<Project_Subscription_Allocation__c> allocationLists = new List<Project_Subscription_Allocation__c>();
				for(SubscriptionReplica__c subs : [select Id, RemainingQuantity__c, Remaning_Percentage__c , Remaining_Hours__c from SubscriptionReplica__c where Id in: stSubscriptionIds]) {
					allocationLists.add(
							new Project_Subscription_Allocation__c(
									Subscription__c = subs.Id,
									Project__c = projectId,
									Quantity_Allocation__c = subs.RemainingQuantity__c,
									Percent_Allocation__c = subs.Remaning_Percentage__c,
									Hours_Allocated__c = subs.Remaining_Hours__c
							)
					);
				}

				insert allocationLists;

			}

			return 'Success';
		}catch (Exception ex){
			return ex.getMessage();
		}

	}

    public static string CancelAllAllocations(string phaseId){

        Map<Id, String> timingMap = new Map<Id, String>();
        Set<Id> allocationIds = new Set<Id>();
        string returnMessage = '';
        try{
            List<Project_Asset_Allocation__c> listProjectAssetAllocations = new List<Project_Asset_Allocation__c>(
            [Select Id, Asset__c,Allocated_NRR__c, Percent_Allocation__c, Implemented__c, Phase_Implemented__c, PhaseImplemented__c, Phase_Implemented_Quantity__c,
                    Logged_Hours__c, Quantity_Allocation__c from  Project_Asset_Allocation__c where Project__c = :phaseId]);

            List<Project_Subscription_Allocation__c> listProjectSubscriptionAllocations = new List<Project_Subscription_Allocation__c>(
            [Select Id, Subscription__c,Allocated_MRR__c, Phase_Implemented_Quantity__c, Phase_Implemented__c, Subscription__r.Subscription__c,
                    Logged_Hours__c, Percent_Allocation__c, PhaseImplemented__c, Quantity_Allocation__c from  Project_Subscription_Allocation__c where Project__c = :phaseId]);

            List<Project_Asset_Allocation__c> updateProjectAssetAllocationsList = new List<Project_Asset_Allocation__c>();
            List<Project_Asset_Allocation__c> deleteProjectAssetAllocationsList = new List<Project_Asset_Allocation__c>();
            decimal totalCanceledNRR = 0.0;

            if(!listProjectAssetAllocations.isEmpty()){
                for(Project_Asset_Allocation__c projectAssetAllocation: listProjectAssetAllocations){
                    if (projectAssetAllocation.Logged_Hours__c > 0) {
                        updateProjectAssetAllocationsList.add(new Project_Asset_Allocation__c(Id = projectAssetAllocation.Id,
                                Quantity_Allocation__c = 0,
                                Percent_Allocation__c = 0,
                                Hours_Allocated__c = 0,
                                Implemented__c = false));
                    } else {
                        deleteProjectAssetAllocationsList.add(projectAssetAllocation);
                    }
                    totalCanceledNRR += projectAssetAllocation.Allocated_NRR__c;

                }
            }


            if(updateProjectAssetAllocationsList.size() > 0){
                update updateProjectAssetAllocationsList;
                returnMessage += 'Successfully updated - ' + updateProjectAssetAllocationsList.size() + ' asset(s). ';
            }


            if(deleteProjectAssetAllocationsList.size() > 0){
                delete deleteProjectAssetAllocationsList;
                returnMessage += 'Successfully deleted - ' + deleteProjectAssetAllocationsList.size() + ' asset(s). ';
            }


            List<Project_Subscription_Allocation__c> upProjectSubscriptionAllocationsList = new List<Project_Subscription_Allocation__c>();
            List<Project_Subscription_Allocation__c> delProjectSubscriptionAllocationsList = new List<Project_Subscription_Allocation__c>();
            decimal totalCanceledMRR = 0.0;
            if(!listProjectAssetAllocations.isEmpty()) {
                for (Project_Subscription_Allocation__c projectSubscriptionAllocation: listProjectSubscriptionAllocations) {
                    if (projectSubscriptionAllocation.Logged_Hours__c > 0) {
                        upProjectSubscriptionAllocationsList.add(new Project_Subscription_Allocation__c(Id = projectSubscriptionAllocation.Id,
                                Quantity_Allocation__c = 0,
                                Percent_Allocation__c = 0,
                                Hours_Allocated__c = 0,
                                Implemented__c = false));
                    }else {
                        delProjectSubscriptionAllocationsList.add(projectSubscriptionAllocation);
                    }

                    totalCanceledMRR += projectSubscriptionAllocation.Allocated_MRR__c;
                }
            }

            if(totalCanceledMRR > 0 || totalCanceledNRR > 0){
                update new Project__c(Id = phaseId,Cancelled_Phase_NRR__c=totalCanceledNRR,Cancelled_Phase_MRR__c=totalCanceledMRR);
            }

            if(upProjectSubscriptionAllocationsList.size() > 0){
                update upProjectSubscriptionAllocationsList;
                returnMessage += 'Successfully updated - ' + upProjectSubscriptionAllocationsList.size() + ' subscription(s). ';
            }


            if(delProjectSubscriptionAllocationsList.size() > 0){
                delete delProjectSubscriptionAllocationsList;
                returnMessage += 'Successfully deleted - ' + delProjectSubscriptionAllocationsList.size() + ' subscription(s). ';
            }

            return returnMessage;

        }catch(Exception ex){
            returnMessage = 'Error occured while cancelling - ' + ex.getMessage();
            return returnMessage;
        }

    }

    public static string updateOnHoldAllocations(string projectId, boolean onHold){
        Set<Id> allocationIds = new Set<Id>();
        string returnMessage = '';
        try{
            List<Project_Asset_Allocation__c> updateProjectAssetAllocationsList = new List<Project_Asset_Allocation__c>();
            List<Project_Subscription_Allocation__c> upProjectSubscriptionAllocationsList = new List<Project_Subscription_Allocation__c>();

            for(Project_Asset_Allocation__c projectAssetAllocation:  [Select Id, On_Hold__c from  Project_Asset_Allocation__c where Project__c = :projectId]){
                    updateProjectAssetAllocationsList.add(new Project_Asset_Allocation__c(Id = projectAssetAllocation.Id,
                            On_Hold__c = onHold));
                }


            if(updateProjectAssetAllocationsList.size() > 0){
                update updateProjectAssetAllocationsList;
                returnMessage += 'Successfully updated - ' + updateProjectAssetAllocationsList.size() + ' asset(s). ';
            }

            for (Project_Subscription_Allocation__c projectSubscriptionAllocation: [Select Id,On_Hold__c from  Project_Subscription_Allocation__c where Project__c = :projectId]) {
                    upProjectSubscriptionAllocationsList.add(
                            new Project_Subscription_Allocation__c(Id = projectSubscriptionAllocation.Id,
                            On_Hold__c = onHold)
                    );
            }

            if(upProjectSubscriptionAllocationsList.size() > 0){
                update upProjectSubscriptionAllocationsList;
                returnMessage += 'Successfully updated - ' + upProjectSubscriptionAllocationsList.size() + ' subscription(s). ';
            }

            return returnMessage;
        }catch(Exception ex){
            returnMessage = 'Error occured while putting allocations on hold - ' + ex.getMessage();
            return returnMessage;
        }
    }

}