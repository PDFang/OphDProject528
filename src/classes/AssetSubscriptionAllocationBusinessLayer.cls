public class AssetSubscriptionAllocationBusinessLayer {

    public Asset currentAsset;
    public SubscriptionReplica__c currentSubscription;
    public Project__c currentProject;

    public List<AssetSubscriptionAllocationModel> assetAllocations{get; set;}
    public List<AssetSubscriptionAllocationModel> subscriptionAllocations{get; set;}

    Set<String> assetFields = new Set<String>{
            'Id',
            'Name',
            'RecordType.Name',
            'Quantity',
            'Budgeted_Hours__c',
            'Parent_Project__c'
    };

    Set<String> subscriptionFields = new Set<String>{
            'Id',
            'Name',
            'Quantity__c',
            'Budgeted_Hours__c',
            'ParentProject__c'
    };

    Set<String> projectFields = new Set<String>{
            'Id',
            'Name',
            'RecordType.Name',
            'ParentProject__c',
            'ParentProject__r.Name'
    };


    public AssetSubscriptionAllocationBusinessLayer(String idParam){

        if(idParam.left(3) == Schema.SObjectType.Asset.getKeyPrefix()){
            currentAsset = getAsset(idParam);
            system.debug('getAsset(): currentAsset - ' + currentAsset);

            if(currentAsset == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No asset record found.'));
                return;
            }

            getAssetAllocations();

        }else if(idParam.left(3) == Schema.SObjectType.SubscriptionReplica__c.getKeyPrefix()){

            currentSubscription = getSubscription(idParam);
            system.debug('getAsset(): currentSubscription - ' + currentSubscription);

            if(currentSubscription == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No subscription record found.'));
                return;
            }

            getSubscriptionAllocations();

        }else if(idParam.left(3) == Schema.SObjectType.Project__c.getKeyPrefix()){
            getProject(idParam);
            if(currentProject != null){
                system.debug('Initalizing allocation collections');
                getAssetAllocations();
                getSubscriptionAllocations();
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'URL: Invalid ID Parameter.'));
        }

    }


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

    private void getAssetAllocations(){

        assetAllocations = new List<AssetSubscriptionAllocationModel>();

        String soql = 'Select Project__c, Percent_Allocation__c, Asset__c, Asset__r.Quantity, Asset__r.Budgeted_Hours__c, '
                + 'Quantity_Allocation__c, Hours_Allocated__c '
                + 'from Project_Asset_Allocation__c where ';

        if(currentProject != null){
            soql += ' Project__c = \'' + currentProject.Id + '\'';
        } else{
            soql += ' Asset__c = \'' + currentAsset.Id + '\'';
        }

        for(Project_Asset_Allocation__c allocation : Database.query(soql)){
            AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(allocation, assetAllocations.size());
            assetAllocations.add(newModel);
        }

        system.debug('getAssetAllocations(): assetAllocations - ' + assetAllocations);

    }

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

    private void getSubscriptionAllocations(){

        subscriptionAllocations = new List<AssetSubscriptionAllocationModel>();

        String soql = 'Select Project__c, Subscription__c, Subscription__r.Quantity__c, Subscription__r.Budgeted_Hours__c, Percent_Allocation__c, Quantity_Allocation__c, Hours_Allocated__c '
                + 'from Project_Subscription_Allocation__c where ';
        if(currentProject != null){
            soql += ' Project__c = \'' + currentProject.Id + '\'';
        } else{
            soql += ' Subscription__c = \'' + currentSubscription.Id + '\'';
        }

        for(Project_Subscription_Allocation__c allocation : Database.query(soql)){
            AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(allocation, subscriptionAllocations.size());
            subscriptionAllocations.add(newModel);
        }

        system.debug('getSubscriptionAllocations(): subscriptionAllocations - ' + subscriptionAllocations);

    }

    public void changeAsset(Integer rowid){

        for(AssetSubscriptionAllocationModel model: assetAllocations){
            if(model.rowid == rowid){
                model.isError = false;
                model.message = null;

                system.debug('changeAsset(): currentAsset - ' + model.assetAllocation.Asset__c);

                Asset selAsset = getAsset(model.assetAllocation.Asset__c);
                if(selAsset != null){
                    model.isQuantityAllocation = (selAsset.Quantity != 1);
                    model.assetAllocation.Asset__r = selAsset;
                }else{
                    model.isError = true;
                    model.message = 'Asset not found';
                }
            }
        }

    }

    public void changeSubscription(Integer rowid){

        for(AssetSubscriptionAllocationModel model: subscriptionAllocations){
            if(model.rowid == rowid){
                model.isError = false;
                model.message = null;

                system.debug('changeSubscription(): subscription id - ' + model.subscriptionAllocation);

                SubscriptionReplica__c selSubscription = getSubscription(model.subscriptionAllocation.Subscription__c);

                if(selSubscription != null){
                    model.isQuantityAllocation = (selSubscription.Quantity__c != 1);
                    model.subscriptionAllocation.Subscription__r = selSubscription;
                }else{
                    model.isError = true;
                    model.message = 'Subscription not found';
                }
            }
        }

    }

    public void createAssetAllocation(){

        system.debug('createAssetAllocation(): currentAsset - ' + currentAsset);
        system.debug('createAssetAllocation(): currentProject - ' + currentProject);

        AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(currentAsset, currentProject, assetAllocations.size());
        assetAllocations.add(newModel);

    }

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
            /*if(model.assetAllocation.Asset__r.Quantity == 1 && model.assetAllocation.Quantity_Allocation__c != 1){
                model.isError = true;
                model.message = 'Quantity cannot be greater than one.';
                error = true;
                continue;
            }*/
            if(model.isQuantityAllocation == false){
                model.assetAllocation.Hours_Allocated__c = model.assetAllocation.Percent_Allocation__c * model.assetAllocation.Asset__r.Budgeted_Hours__c / 100;
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
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'One or more line items has errors.'));
                return false;
            }
        }

        if(newAllocations.size() > 0){

            Database.SaveResult[] results = Database.insert(newAllocations.values(), false);
            Integer failures = parseErrors(results, assetAllocations, new List<Integer>(newAllocations.keySet()));

            if(failures > 0){
                Database.rollback(beforeSave);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'One or more line items has errors.'));
                return false;
            }
        }

        return true;

    }

    public void createSubscriptionAllocation(){

        system.debug('createSubscriptionAllocation(): currentSubscription - ' + currentSubscription);
        system.debug('createSubscriptionAllocation(): currentProject - ' + currentProject);

        AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(currentSubscription, currentProject, subscriptionAllocations.size());
        subscriptionAllocations.add(newModel);

    }

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


    public boolean saveSubscriptionAllocation(){

        Map<Integer, Project_Subscription_Allocation__c> newAllocations = new Map<Integer, Project_Subscription_Allocation__c>();
        Map<Integer, Project_Subscription_Allocation__c> currentAllocations = new Map<Integer, Project_Subscription_Allocation__c>();
        Project_Subscription_Allocation__c[] delAllocations = new Project_Subscription_Allocation__c[]{};

        system.debug('saveSubscriptionAllocation(): subscriptionAllocations - ' + subscriptionAllocations);

        for(AssetSubscriptionAllocationModel model :subscriptionAllocations){

            system.debug('saveSubscriptionAllocation(): model - ' + model);

            if(model.isDelete){
                if(model.subscriptionAllocation.Id != null){
                    delAllocations.add(model.subscriptionAllocation);
                }
                continue;
            }

            if(model.isQuantityAllocation == false){
                model.subscriptionAllocation.Hours_Allocated__c = model.subscriptionAllocation.Percent_Allocation__c * model.subscriptionAllocation.Subscription__r.Budgeted_Hours__c / 100;
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

        System.Savepoint beforeSave = Database.setSavepoint();

        if(delAllocations.size() > 0){
            delete delAllocations;
        }

        if(currentAllocations.size() > 0){

            Database.SaveResult[] results = Database.update(currentAllocations.values(), false);
            Integer failures = parseErrors(results, subscriptionAllocations, new List<Integer>(currentAllocations.keySet()));

            if(failures > 0){
                Database.rollback(beforeSave);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'One or more line items has errors.'));
                return false;
            }
        }

        if(newAllocations.size() > 0){

            Database.SaveResult[] results = Database.insert(newAllocations.values(), false);
            Integer failures = parseErrors(results, subscriptionAllocations, new List<Integer>(newAllocations.keySet()));

            if(failures > 0){
                Database.rollback(beforeSave);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'One or more line items has errors.'));
                return false;
            }
        }

        return true;

    }


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