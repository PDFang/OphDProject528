public class AssetSubscriptionAllocationBusinessLayer {

    public Asset currentAsset;
    public SubscriptionReplica__c currentSubscription;
    public Project__c currentProject;

    public Asset selAsset;

    public Decimal remainingQuantity;
    public Decimal remainingPercentage;
    public Decimal remainingBudgetedHours;

    public Decimal remainingSubscriptionQuantity;
    public Decimal remainingSubscriptionPercentage;
    public Decimal remainingSubscriptionBudgetedHours;

    public String assetName;
    public String subscriptionName;

    public List<AssetSubscriptionAllocationModel> assetAllocations{get; set;}
    public List<AssetSubscriptionAllocationModel> subscriptionAllocations{get; set;}

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
            'ParentProject__r.Name'
    };

    // constructor
    public AssetSubscriptionAllocationBusinessLayer(String idParam){

        // entry from an asset
        if(idParam.left(3) == Schema.SObjectType.Asset.getKeyPrefix()){
            currentAsset = getAsset(idParam);
            system.debug('getAsset(): currentAsset - ' + currentAsset);

            if(currentAsset == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No asset record found.'));
                return;
            }

            getAssetAllocations();

        }
        // entry from a subscription
        else if(idParam.left(3) == Schema.SObjectType.SubscriptionReplica__c.getKeyPrefix()){

            currentSubscription = getSubscription(idParam);
            system.debug('getAsset(): currentSubscription - ' + currentSubscription);

            if(currentSubscription == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No subscription record found.'));
                return;
            }

            getSubscriptionAllocations();

        }
        // entry from project
        else if(idParam.left(3) == Schema.SObjectType.Project__c.getKeyPrefix()){
            getProject(idParam);
            if(currentProject != null){
                system.debug('Initalizing allocation collections');
                getAssetAllocations();
                getSubscriptionAllocations();
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

        List<String> fieldList = new List<String>(assetFields);

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

    // fetch Project Asset Allocations
    private void getAssetAllocations(){

        assetAllocations = new List<AssetSubscriptionAllocationModel>();

        String soql = 'Select Project__c, Name, ProjectPhase__c, Percent_Allocation__c, Asset__c, Asset__r.Quantity, Asset__r.Budgeted_Hours__c, '
                + 'Quantity_Allocation__c, Hours_Allocated__c, Asset__r.Total_Allocated_Quantity__c, Asset__r.Total_Allocated_Hours__c '
                + 'from Project_Asset_Allocation__c where ';

        if(currentProject != null){
            soql += ' Project__c = \'' + currentProject.Id + '\'';
        } else{
            soql += ' Asset__c = \'' + currentAsset.Id + '\'';
        }
        soql += ' order by createddate ';

        for(Project_Asset_Allocation__c allocation : Database.query(soql)){
            AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(allocation, assetAllocations.size());
            assetAllocations.add(newModel);
        }

        system.debug('getAssetAllocations(): assetAllocations - ' + assetAllocations);

    }

    // fetch subscription details
    private SubscriptionReplica__c getSubscription(String subscriptionId){

        List<Schema.FieldSetMember> fsMembers = Schema.SobjectType.SubscriptionReplica__c.fieldSets.PS_Subscription_Allocation.getFields();
        for(Schema.FieldSetMember member : fsMembers){
            subscriptionFields.add(member.getFieldPath());
        }

        List<String> fieldList = new List<String>(subscriptionFields);

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

    // fetch Project Subscription Allocation
    private void getSubscriptionAllocations(){

        subscriptionAllocations = new List<AssetSubscriptionAllocationModel>();

        String soql = 'Select Project__c, Subscription__c, Name, ProjectPhase__c, Subscription__r.Quantity__c, Subscription__r.Budgeted_Hours__c, Percent_Allocation__c, Quantity_Allocation__c, Hours_Allocated__c, Subscription__r.Total_Allocated_Quantity__c, Subscription__r.Total_Allocated_Hours__c '
                + 'from Project_Subscription_Allocation__c where ';
        if(currentProject != null){
            soql += ' Project__c = \'' + currentProject.Id + '\'';
        } else{
            soql += ' Subscription__c = \'' + currentSubscription.Id + '\'';
        }
        soql += ' order by createddate ';

        for(Project_Subscription_Allocation__c allocation : Database.query(soql)){
            AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(allocation, subscriptionAllocations.size());
            subscriptionAllocations.add(newModel);
        }

        system.debug('getSubscriptionAllocations(): subscriptionAllocations - ' + subscriptionAllocations);

    }

    // check if selected asset has a quantity or budgeted hours
    public void changeAsset(Integer rowid){

        for(AssetSubscriptionAllocationModel model: assetAllocations){
            if(model.rowid == rowid){
                model.isError = false;
                model.message = null;

                system.debug('changeAsset(): currentAsset - ' + model.assetAllocation.Asset__c);

                selAsset = getAsset(model.assetAllocation.Asset__c);
                if(selAsset != null){
                    model.isQuantityAllocation = (selAsset.Quantity > 1);
                    model.isPercentageAllocation = (selAsset.Budgeted_Hours__c > 0 && selAsset.Quantity <= 1);
                    model.isAllocatedHours = (selAsset.Quantity > 1 && selAsset.Budgeted_Hours__c > 0);
                    model.assetAllocation.Asset__r = selAsset;
                }else{
                    model.isError = true;
                    model.message = 'Asset not found';
                }
                remainingQuantity = null;
                remainingBudgetedHours = null;
                remainingPercentage = null;
                assetName = selAsset.Name;
                getAssetRemainingQuantityNPercentage(selAsset);

                system.debug('changeAsset(): model - ' + model);
            }
        }

    }

    // check if selected subscription has a quantity or budgeted hours
    public void changeSubscription(Integer rowid){

        for(AssetSubscriptionAllocationModel model: subscriptionAllocations){
            if(model.rowid == rowid){
                model.isError = false;
                model.message = null;

                system.debug('changeSubscription(): subscription id - ' + model.subscriptionAllocation);

                SubscriptionReplica__c selSubscription = getSubscription(model.subscriptionAllocation.Subscription__c);

                if(selSubscription != null){
                    model.isQuantityAllocation = (selSubscription.Quantity__c > 1);
                    model.isPercentageAllocation = (selSubscription.Budgeted_Hours__c > 0 && selSubscription.Quantity__c <= 1);
                    model.isAllocatedHours = (selSubscription.Quantity__c > 1 && selSubscription.Budgeted_Hours__c > 0);
                    model.subscriptionAllocation.Subscription__r = selSubscription;
                }else{
                    model.isError = true;
                    model.message = 'Subscription not found';
                }

                remainingSubscriptionQuantity = null;
                remainingSubscriptionPercentage = null;
                remainingSubscriptionBudgetedHours = null;
                subscriptionName = selSubscription.Name;
                getSubscriptionRemainingQuantityNPercentage(selSubscription);
                system.debug('changeSubscription(): model - ' + model);

            }
        }

    }

    // create and insert a new row for asset allocation
    public void createAssetAllocation(){

        system.debug('createAssetAllocation(): currentAsset - ' + currentAsset);
        system.debug('createAssetAllocation(): currentProject - ' + currentProject);

        system.debug('Passed');

        AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(currentAsset, currentProject, assetAllocations.size());
        assetAllocations.add(newModel);

    }

    // delete asset allocation row from the list
    public void deleteAssetAllocation(Integer rowid){

        system.debug('deleteAssetAllocation(): rowid - ' + rowid);

        AssetSubscriptionAllocationModel[] assetAllocationsCopy = new AssetSubscriptionAllocationModel[]{};

        for(AssetSubscriptionAllocationModel model: assetAllocations){
            if(model.rowid != rowid){
                AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(model.assetAllocation, assetAllocationsCopy.size());
                assetAllocationsCopy.add(newModel);
            }
        }

        this.assetAllocations = assetAllocationsCopy;

    }

    // perform validations and save the asset allocations
    public boolean saveAssetAllocation(){

        Map<Integer, Project_Asset_Allocation__c> newAllocations = new Map<Integer,Project_Asset_Allocation__c>();
        Map<Integer, Project_Asset_Allocation__c> currentAllocations = new Map<Integer, Project_Asset_Allocation__c>();
        Project_Asset_Allocation__c[] delAllocations = new Project_Asset_Allocation__c[]{};

        Boolean error = false;

        for(AssetSubscriptionAllocationModel model :assetAllocations){

            model.isError = false;
            model.message = null;

            system.debug('saveAssetAllocation(): model - ' + model);

            if(model.isDelete){
                if(model.assetAllocation.Id != null){
                    delAllocations.add(model.assetAllocation);
                }
                continue;
            }

            if(!model.isPercentageAllocation && !model.isQuantityAllocation){
                model.isError = true;
                model.message = 'Asset has no quantity and budgeted hours. Please delete this row and try again.';
                error = true;
                continue;
            }

            if(model.assetAllocation.Quantity_Allocation__c > 0 && !(model.assetAllocation.Asset__r.Quantity > 1)){
                model.isError = true;
                model.message = 'Asset has no quantity available for allocation.';
                error = true;
                continue;
            }
            if(model.assetAllocation.Percent_Allocation__c > 0 && !(model.assetAllocation.Asset__r.Budgeted_Hours__c > 0)){
                model.isError = true;
                model.message = 'Asset has no budgeted hours available for allocation.';
                error = true;
                continue;
            }
            if(model.isPercentageAllocation && model.assetAllocation.Percent_Allocation__c > 0){
                model.assetAllocation.Hours_Allocated__c = model.assetAllocation.Percent_Allocation__c * model.assetAllocation.Asset__r.Budgeted_Hours__c / 100;
            }

            if(model.isAllocatedHours && model.assetAllocation.Hours_Allocated__c > 0){
                model.assetAllocation.Percent_Allocation__c = 100 * model.assetAllocation.Hours_Allocated__c/model.assetAllocation.Asset__r.Budgeted_Hours__c;
            }
            else if(model.isAllocatedHours && (model.assetAllocation.Hours_Allocated__c <= 0 || model.assetAllocation.Hours_Allocated__c == null))
                model.assetAllocation.Percent_Allocation__c = null;

            if(!(model.assetAllocation.Hours_Allocated__c > 0) && !(model.assetAllocation.Quantity_Allocation__c > 0)){
                model.isError = true;
                model.message = 'Either allocated quantity or allocated hours must be greater than or equal to one.';
                error = true;
                continue;
            }

            if(model.assetAllocation.Id == null){
                newAllocations.put(model.rowid, model.assetAllocation);
            } else{
                currentAllocations.put(model.rowid, model.assetAllocation);
            }

        }

        system.debug('saveAssetAllocation(): newAllocations - ' + newAllocations);
        system.debug('saveAssetAllocation(): currentAllocations - ' + currentAllocations);
        system.debug('saveAssetAllocation(): delAllocations - ' + delAllocations);

        if(error){
            return false;
        }

        if(delAllocations.size() > 0){
            delete delAllocations;
        }

        System.Savepoint beforeSave = Database.setSavepoint();

        if(currentAllocations.size() > 0){

            Database.SaveResult[] results = Database.update(currentAllocations.values(), false);
            Integer failures = parseErrors(results, assetAllocations, new List<Integer>(currentAllocations.keySet()));

            if(failures > 0){
                Database.rollback(beforeSave);
                return false;
            }
        }

        if(newAllocations.size() > 0){

            Database.SaveResult[] results = Database.insert(newAllocations.values(), false);
            Integer failures = parseErrors(results, assetAllocations, new List<Integer>(newAllocations.keySet()));

            if(failures > 0){
                Database.rollback(beforeSave);
                return false;
            }
        }

        return true;

    }

    // create and insert a new row for subscription allocation
    public void createSubscriptionAllocation(){

        system.debug('createSubscriptionAllocation(): currentSubscription - ' + currentSubscription);
        system.debug('createSubscriptionAllocation(): currentProject - ' + currentProject);

        AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(currentSubscription, currentProject, subscriptionAllocations.size());
        subscriptionAllocations.add(newModel);

    }

    // delete subscription allocation row from the list
    public void deleteSubscriptionAllocation(Integer rowid){

        system.debug('deleteSubscriptionAllocation(): rowid - ' + rowid);

        AssetSubscriptionAllocationModel[] subscriptionAllocationCopy = new AssetSubscriptionAllocationModel[]{};

        for(AssetSubscriptionAllocationModel model: subscriptionAllocations){
            if(model.rowid != rowid){
                AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(model.subscriptionAllocation, subscriptionAllocationCopy.size());
                subscriptionAllocationCopy.add(newModel);
            }
        }

        this.subscriptionAllocations = subscriptionAllocationCopy;

    }

    // perform validations and save the subscription allocations
    public boolean saveSubscriptionAllocation(){

        Map<Integer, Project_Subscription_Allocation__c> newAllocations = new Map<Integer, Project_Subscription_Allocation__c>();
        Map<Integer, Project_Subscription_Allocation__c> currentAllocations = new Map<Integer, Project_Subscription_Allocation__c>();
        Project_Subscription_Allocation__c[] delAllocations = new Project_Subscription_Allocation__c[]{};

        system.debug('saveSubscriptionAllocation(): subscriptionAllocations - ' + subscriptionAllocations);

        Boolean error = false;

        for(AssetSubscriptionAllocationModel model :subscriptionAllocations){

            model.isError = false;
            model.message = null;

            system.debug('saveSubscriptionAllocation(): model - ' + model);

            if(model.isDelete){
                if(model.subscriptionAllocation.Id != null){
                    delAllocations.add(model.subscriptionAllocation);
                }
                continue;
            }

            if(!model.isPercentageAllocation && !model.isQuantityAllocation){
                model.isError = true;
                model.message = 'Subscription has no quantity and budgeted hours. Please delete this row and try again..';
                error = true;
                continue;
            }

            if(model.subscriptionAllocation.Quantity_Allocation__c > 0 && !(model.subscriptionAllocation.Subscription__r.Quantity__c > 1)){
                model.isError = true;
                model.message = 'Subscription has no quantity available for allocation.';
                error = true;
                continue;
            }

            if(model.subscriptionAllocation.Percent_Allocation__c > 0 && !(model.subscriptionAllocation.Subscription__r.Budgeted_Hours__c > 0)){
                model.isError = true;
                model.message = 'Subscription has no budgeted hours available for allocation.';
                error = true;
                continue;
            }

            if(model.isPercentageAllocation && model.subscriptionAllocation.Percent_Allocation__c > 0){
                model.subscriptionAllocation.Hours_Allocated__c = model.subscriptionAllocation.Percent_Allocation__c * model.subscriptionAllocation.Subscription__r.Budgeted_Hours__c / 100;
            }

            System.debug('model.subscriptionAllocation.Hours_Allocated__c' + model.subscriptionAllocation.Hours_Allocated__c);

            if(model.isAllocatedHours && model.subscriptionAllocation.Hours_Allocated__c > 0){
                model.subscriptionAllocation.Percent_Allocation__c = 100 * model.subscriptionAllocation.Hours_Allocated__c/model.subscriptionAllocation.Subscription__r.Budgeted_Hours__c;
            }
            else if(model.isAllocatedHours && (model.subscriptionAllocation.Hours_Allocated__c <= 0 || model.subscriptionAllocation.Hours_Allocated__c == null))
                model.subscriptionAllocation.Percent_Allocation__c = null;

            if(!(model.subscriptionAllocation.Hours_Allocated__c > 0) && !(model.subscriptionAllocation.Quantity_Allocation__c > 0)){
                model.isError = true;
                model.message = 'Either allocated quantity or allocated hours must be greater than or equal to one.';
                error = true;
                continue;
            }

            if(model.subscriptionAllocation.Id == null){
                newAllocations.put(model.rowid, model.subscriptionAllocation);
            } else{
                currentAllocations.put(model.rowid, model.subscriptionAllocation);
            }

        }

        system.debug('saveSubscriptionAllocation(): newAllocations - ' + newAllocations);
        system.debug('saveSubscriptionAllocation(): currentAllocations - ' + currentAllocations);
        system.debug('saveSubscriptionAllocation(): delAllocations - ' + delAllocations);

        if(error){
            return false;
        }

        System.Savepoint beforeSave = Database.setSavepoint();

        if(delAllocations.size() > 0){
            delete delAllocations;
        }

        if(currentAllocations.size() > 0){

            Database.SaveResult[] results = Database.update(currentAllocations.values(), false);
            Integer failures = parseErrors(results, subscriptionAllocations, new List<Integer>(currentAllocations.keySet()));

            if(failures > 0){
                Database.rollback(beforeSave);
                return false;
            }
        }

        if(newAllocations.size() > 0){

            Database.SaveResult[] results = Database.insert(newAllocations.values(), false);
            Integer failures = parseErrors(results, subscriptionAllocations, new List<Integer>(newAllocations.keySet()));

            if(failures > 0){
                Database.rollback(beforeSave);
                return false;
            }
        }

        return true;

    }
//
//    public Decimal getRemainingQuantity(){
//        if(currentAsset != null)
//            return currentAsset.RemainingQuantity__c;
//        else if (selAsset != null)
//            return selAsset.RemainingQuantity__c;
//
//        return null;
//    }

    public void getAssetRemainingQuantityNPercentage(Asset Asset){
        system.debug('Asset' + Asset);
        if(Asset != null){
            system.debug('Asset.Quantity' + Asset.Quantity);
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

    public void getSubscriptionRemainingQuantityNPercentage(SubscriptionReplica__c Subscription){
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
                        remainingSubscriptionBudgetedHours = Subscription.Budgeted_Hours__c;
                else
                    if(Subscription.Quantity__c <= 1)
                        remainingSubscriptionPercentage = 100 -  (Subscription.Total_Allocated_Hours__c/Subscription.Budgeted_Hours__c) * 100;
                    else
                        remainingSubscriptionBudgetedHours = Subscription.Budgeted_Hours__c - Subscription.Total_Allocated_Hours__c;
            }

            else{
                if(Subscription.Quantity__c <= 1)
                    remainingSubscriptionPercentage = 0;
                else
                    remainingSubscriptionBudgetedHours = 0;
            }
        }
    }

    // parse database errors
    private Integer  parseErrors(Database.SaveResult[] results, AssetSubscriptionAllocationModel[] allocations, List<Integer> rowIds){

        Integer failures = 0;

        for(Integer i=0; i < results.size(); i++){
            Database.SaveResult res = results[i];
            if(!res.isSuccess()){
                failures++;
                Database.Error[] errors = res.getErrors();
                Integer rowid = rowIds[i];
                for(Integer id=0; id < allocations.size(); id++){
                    if(allocations[id].rowid == rowid){
                        allocations[id].isError = true;
                        allocations[id].message = errors[0].getMessage();
                    }
                }

            }
        }

        return failures;
    }

}