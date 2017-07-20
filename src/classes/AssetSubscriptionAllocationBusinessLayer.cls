public with sharing class AssetSubscriptionAllocationBusinessLayer {

    public Asset currentAsset;
    public SubscriptionReplica__c currentSubscription;
    public Project__c currentProject;

    public List<AssetSubscriptionAllocationModel> assetAllocations{get; set;}
    public List<AssetSubscriptionAllocationModel> subscriptionAllocations{get; set;}

    public AssetSubscriptionAllocationBusinessLayer(String idParam){

        if(idParam.left(3) == Schema.SObjectType.Asset.getKeyPrefix()){
            getAsset(idParam);
            getAssetAllocations();
        }else if(idParam.left(3) == Schema.SObjectType.SubscriptionReplica__c.getKeyPrefix()){
            getSubscription(idParam);
            getSubscriptionAllocations();
        }else if(idParam.left(3) == Schema.SObjectType.Project__c.getKeyPrefix()){
            getProject(idParam);
            if(currentProject != null){
                getAssetAllocations();
                getSubscriptionAllocations();
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'URL: Invalid ID Parameter.'));
        }

    }


    private void getProject(String projectId){

        List<Project__c> projects = [
                Select Id, Name, RecordType.Name, Account__r.Name, ParentProject__c, ParentProject__r.Name
                from Project__c where Id = :projectId and RecordType.Name like 'PS Project Phase%'
        ];

        if(projects.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No project record found.'));
            return;
        }

        currentProject = projects[0];

        system.debug('getProject(): currentProject - ' + currentProject);

    }

    private void getAsset(String assetId){

        List<Asset> assets = [
                Select Id, Name, Description, RecordType.Name, Account.Name, Product2.Name, Quantity, Budgeted_Hours__c, Parent_Project__c,
                        Parent_Project__r.Name, Type__c
                from Asset where Id = :assetId
        ];

        if(assets.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No asset record found.'));
            return;
        }

        currentAsset = assets[0];

        system.debug('getAsset(): currentAsset - ' + currentAsset);

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
            AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(allocation);
            assetAllocations.add(newModel);
        }

        system.debug('getAssetAllocations(): assetAllocations - ' + assetAllocations);

    }

    private void getSubscription(String subscriptionId){

        List<SubscriptionReplica__c> subscriptions = [
                Select Id, Name, Account__c, Product__c, Quantity__c, ParentProject__c,
                        ParentProject__r.Name
                from SubscriptionReplica__c where Id = :subscriptionId
        ];

        if(subscriptions.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Subscription record found.'));
            return;
        }

        currentSubscription = subscriptions[0];

        system.debug('getSubscription(): currentSubscription - ' + currentSubscription);

    }

    private void getSubscriptionAllocations(){

        subscriptionAllocations = new List<AssetSubscriptionAllocationModel>();

        String soql = 'Select Project__c, Subscription__c, Percent_Allocation__c, Quantity_Allocation__c '
                + 'from Project_Subscription_Allocation__c where ';
        if(currentProject != null){
            soql += ' Project__c = \'' + currentProject.Id + '\'';
        } else{
            soql += ' Subscription__c = \'' + currentSubscription.Id + '\'';
        }

        for(Project_Subscription_Allocation__c allocation : Database.query(soql)){
            AssetSubscriptionAllocationModel newModal = new AssetSubscriptionAllocationModel(allocation);
            subscriptionAllocations.add(newModal);
        }

        system.debug('getSubscriptionAllocations(): subscriptionAllocations - ' + subscriptionAllocations);

    }

    public void createAssetAllocation(){

        AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(currentAsset);
        system.debug('Current Asset =>' + currentAsset);
        assetAllocations.add(newModel);

    }

    public boolean saveAssetAllocation(){

        Project_Asset_Allocation__c[] allocations = new Project_Asset_Allocation__c[]{};
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
            if(model.assetAllocation.Asset__r.Quantity == 1 && model.assetAllocation.Quantity_Allocation__c != 1){
                model.isError = true;
                model.message = 'Quantity cannot be greater than one.';
                error = true;
                continue;
            }
            allocations.add(model.assetAllocation);
        }

        system.debug('saveAssetAllocation(): allocations - ' + allocations);
        system.debug('saveAssetAllocation(): delAllocations - ' + delAllocations);

        if(error){
            return false;
        }

        System.Savepoint beforeUpdate = Database.setSavepoint();
        
        if(delAllocations.size() > 0){
            delete delAllocations;
        }

        if(allocations.size() > 0){

            Integer failures = 0;
            Database.UpsertResult[] results = Database.upsert(allocations, false);
            for(Integer i=0; i < results.size(); i++){
                Database.UpsertResult res = results[i];
                if(!res.isSuccess()){
                    failures++;
                    Database.Error[] errors = res.getErrors();
                    assetAllocations[i].isError = true;
                    assetAllocations[i].message = errors[0].getMessage();
                }
            }
            if(failures > 0){
                Database.rollback(beforeUpdate);
                return false;
            }
        }



        return true;

    }

    public void createSubscriptionAllocation(){

        AssetSubscriptionAllocationModel newModel = new AssetSubscriptionAllocationModel(currentSubscription);
        assetAllocations.add(newModel);

    }

    public void saveSubscriptionAllocation(){

        Project_Subscription_Allocation__c[] allocations = new Project_Subscription_Allocation__c[]{};
        Project_Subscription_Allocation__c[] delAllocations = new Project_Subscription_Allocation__c[]{};

        for(AssetSubscriptionAllocationModel model :subscriptionAllocations){
            if(model.isDelete){
                if(model.subscriptionAllocation.Id != null){
                    delAllocations.add(model.subscriptionAllocation);
                }
                continue;
            }
            allocations.add(model.subscriptionAllocation);
        }

        system.debug('saveSubscriptionAllocation(): allocations - ' + allocations);

        system.debug('saveSubscriptionAllocation(): delAllocations - ' + delAllocations);

        if(allocations.size() > 0){
            upsert allocations;
        }

        if(delAllocations.size() > 0){
            delete delAllocations;
        }

    }

}