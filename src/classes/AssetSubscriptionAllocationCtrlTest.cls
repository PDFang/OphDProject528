@IsTest
private class AssetSubscriptionAllocationCtrlTest {

    private static Id childRTId = [SELECT id from RecordType where Name = 'PS Project Phase SaaS'].Id;
    private static Id parentProjectRTId = [SELECT id from RecordType where Name = 'PS Project Phase SaaS'].Id;
    private static Id assetReordTypeId = [Select id from RecordType where Name = 'Premise Asset'].Id;

    private static Asset TestAsset;
    private static Asset TestAsset1;
    private static SBQQ__QuoteLine__c QuoteLine;
    private static Project__c parentProject1;
    private static SBQQ__Subscription__c subscription;
    private static SBQQ__Subscription__c subscription1;
    private static SubscriptionReplica__c subscriptionReplica;
    private static SubscriptionReplica__c subscriptionReplica1;
    private static AssetSubscriptionAllocationController asstSubsAlloCont;

    private static Project_Asset_Allocation__c projectAssetAllocation;
    private static Project_Asset_Allocation__c projectAssetAllocation1;
    private static Project_Subscription_Allocation__c projectSubscriptionAllocation;
    private static Project_Subscription_Allocation__c projectSubscriptionAllocation1;

    public static void createSimpleTestData(){

        //creates the required strcuture for the test
        Id strRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.RecordTypeInfosByName.get('SaaS').RecordTypeId;
        system.debug('starting test data creation');
        List<ImplementedProduct__c> implementedProducts = new List<ImplementedProduct__c>();
        //List<Asset> assets = new List<Asset>();
        // Create account
        Account accountRecord = InContactBaseClass.CreateAccount('Test Account');
        insert accountRecord;

        Opportunity opp = new Opportunity(
                Name = 'Test',
                AccountId = accountRecord.Id,
                StageName = 'Assigned',
                CloseDate = Date.today(),
                RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Education Request', 'Opportunity'),
                PM_Estimated_Go_Live__c = system.today(),
                PM_Go_Live_Date__c  = null
        );

        insert opp;

        // Parent Project
        parentProject1 = new Project__c(
                RecordTypeId = parentProjectRTId,
                Summary__c = 'This is the parent Project 1',
                ProjectType__c = 'PS Project Phase Premise WFO',
                Opportunity__c = opp.Id,
                Status__c = '0 - PreSale'
        );

        insert parentProject1;
        system.debug('parentProject1.Id =>' + parentProject1.Id);

        // Parent Project
        Project__c childProject1 = new Project__c(
                RecordTypeId = childRTId,
                Summary__c = 'This is the Child Project 1',
                ProjectType__c = 'PS Project Phase Premise WFO',
                ParentProject__c = parentProject1.Id,
                Opportunity__c = opp.Id,
                Status__c = '0 - PreSale'
        );

        insert childProject1;

        ImplementedProduct__c ip1 = new ImplementedProduct__c(
                Account__c = accountRecord.Id,
                Opportunity__c = opp.Id
        );

        implementedProducts.add(ip1);
        insert implementedProducts;


        Product2 p = new Product2();
        p.Name     = 'TEST';
        p.ProductCode ='1234520-000-000-XX';
        p.Family = 'SOFTWARE MRC PRODUCTS';
        p.Budgeted_Hours__c = 50;
        insert (p);

        SBQQ__Quote__c objQuote = createQuoteTestData(strRecordTypeId, accountRecord.Id);

        objQuote.SBQQ__Opportunity2__c = opp.id;
        update(objQuote);


        SBQQ__QuoteLine__c QuoteLine = new SBQQ__QuoteLine__c();
        QuoteLine.SBQQ__Product__c = p.Id;
        QuoteLine.SBQQ__Existing__c = true;
        QuoteLine.SBQQ__NetPrice__c  = 20.00;
        QuoteLine.SBQQ__Quantity__c = 5;
        QuoteLine.SBQQ__Quote__c = objQuote.Id;
        //q1.SBQQ__Assets__r = asset1.id;
        insert (QuoteLine);

        TestAsset = new Asset(
                Name = 'Asset asset1',
                Project_Phase__c = childProject1.Id,
                Product2 = [SELECT Id FROM Product2 WHERE Id = :p.Id limit 1],
                ImplementedProduct__c = ip1.Id,
                AccountId = accountRecord.Id,
                SBQQ__QuoteLine__c = QuoteLine.id,
                Quantity = 10,
                Budgeted_Hours__c = 50,
                RecordTypeId = assetReordTypeId

        );
        //assets.add(TestAsset);
        insert TestAsset;

        TestAsset1 = new Asset(
                Name = 'Asset asset2',
                Project_Phase__c = childProject1.Id,
                ImplementedProduct__c = ip1.Id,
                AccountId = accountRecord.Id,
                SBQQ__QuoteLine__c = QuoteLine.id,
                Quantity = 10,
                RecordTypeId = assetReordTypeId
                //Budgeted_Hours__c = 50
        );
        //assets.add(TestAsset);
        insert TestAsset1;


        system.debug('TestAsset =>' + TestAsset.Id);

        subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c =  accountRecord.id;
        subscription.SBQQ__QuoteLine__c = QuoteLine.id;
        subscription.SBQQ__Quantity__c = 10;
        subscription.SBQQ__Product__c = p.Id;
        subscription.Budgeted_Hours__c = 10;

        insert subscription;

        subscription1 = new SBQQ__Subscription__c();
        subscription1.SBQQ__Account__c =  accountRecord.id;
        subscription1.SBQQ__QuoteLine__c = QuoteLine.id;
        subscription1.SBQQ__Quantity__c = 0;
        subscription1.SBQQ__Product__c = p.Id;
        subscription1.Budgeted_Hours__c = 0;

        insert subscription1;

        subscriptionReplica = new SubscriptionReplica__c();
        subscriptionReplica = [SELECT Id, Account__c, Product__c, Quote_Line__c, Quantity__c, Subscription__c FROM SubscriptionReplica__c WHERE Subscription__c = :subscription.Id limit 1];
        //insert subscriptionReplica;

        subscriptionReplica1 = new SubscriptionReplica__c();
        subscriptionReplica1 = [SELECT Id, Account__c, Product__c, Quote_Line__c, Quantity__c, Subscription__c FROM SubscriptionReplica__c WHERE Subscription__c = :subscription1.Id limit 1];

        system.debug('subscriptionReplica.Subscription__c =>' + subscriptionReplica.Subscription__c);

        projectAssetAllocation = new Project_Asset_Allocation__c(
                Project__c = parentProject1.Id,
                Asset__c  = TestAsset.Id,
                Quantity_Allocation__c = 5
                //Percent_Allocation__c = 50
        );
        insert projectAssetAllocation;

        projectAssetAllocation1 = new Project_Asset_Allocation__c(
                Project__c = parentProject1.Id,
                Asset__c  = TestAsset.Id,
                Quantity_Allocation__c = 2
                //Percent_Allocation__c = 50
        );
        insert projectAssetAllocation1;

        projectSubscriptionAllocation = new Project_Subscription_Allocation__c(
                Project__c = parentProject1.Id,
                Subscription__c  = subscriptionReplica.Id,
                Quantity_Allocation__c = 5,
                Percent_Allocation__c = 50
        );
        insert projectSubscriptionAllocation;

    }

    public static SBQQ__Quote__c createQuoteTestData(Id strRecordtypeId, Id strAccId) {
        SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
        objQuote.SBQQ__Account__c = strAccId;
        objQuote.SBQQ__Type__c = 'Quote';
        objQuote.SBQQ__Status__c = 'Draft';
        objQuote.RecordTypeId = strRecordtypeId;
        objQuote.Usage_Rate_Type__c = 'Flat';
        objQuote.Flat_Usage_Rates__c = 'TestFlat';
        objQuote.Toll_Free_Inbound_Usage_Rate__c = 'TestInbound';
        objQuote.Outbound_Termination_Usage_Rate__c = 'TestOutbound';
        insert objQuote;
        return objQuote;
    }

    static testMethod void AssetAllocationControllerTest() {

        createSimpleTestData();
        Test.startTest();
        Test.setCurrentPage(Page.AssetSubscriptionAllocation);
        ApexPages.currentPage().getParameters().put('id', parentProject1.Id);
        asstSubsAlloCont = new AssetSubscriptionAllocationController();

        ApexPages.currentPage().getParameters().put('id', TestAsset.Id);

        asstSubsAlloCont = new AssetSubscriptionAllocationController();
        asstSubsAlloCont.getAssetAllocations();
        asstSubsAlloCont.createAssetAllocation();

        List<AssetSubscriptionAllocationModel> allocations = asstSubsAlloCont.getAssetAllocations();

//
        allocations[2].assetAllocation.Asset__c = TestAsset.Id;
        allocations[2].assetAllocation.Project__c = parentProject1.Id;
        //allocations[2].assetAllocation.Percent_Allocation__c = 10;
        allocations[2].assetAllocation.Quantity_Allocation__c = 2;
        //allocations[2].assetAllocation.Hours_Allocated__c = 1;
        asstSubsAlloCont.saveAssetAllocation();
        system.assert(ApexPages.hasMessages(ApexPages.Severity.CONFIRM),'Saved Successfully.');

        system.assertEquals(TestAsset.Id, asstSubsAlloCont.Asset.Id);
//        system.assert(ApexPages.hasMessages(ApexPages.Severity.CONFIRM), 'Saved Successfully.');
        ApexPages.currentPage().getParameters().put('newAssetRowId', '0');
        asstSubsAlloCont.changeAsset();
        ApexPages.currentPage().getParameters().put('delAssetRowId', TestAsset.Id);
        asstSubsAlloCont.deleteAssetAllocation();
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Error while deleting asset allocation. ');
        ApexPages.currentPage().getParameters().put('delAssetRowId', '0');
        asstSubsAlloCont.deleteAssetAllocation();
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), '');

        asstSubsAlloCont.cancel();
        Test.stopTest();

    }

    static testMethod void SubscriptionAllocationControllerTest(){
        createSimpleTestData();
        Test.startTest();
        Test.setCurrentPage(Page.AssetSubscriptionAllocation);

        ApexPages.currentPage().getParameters().put('id', parentProject1.Id);

        asstSubsAlloCont = new AssetSubscriptionAllocationController();
        system.assertEquals(parentProject1.Id, asstSubsAlloCont.Project.Id);

        ApexPages.currentPage().getParameters().put('id', subscriptionReplica.Id);

        asstSubsAlloCont = new AssetSubscriptionAllocationController();
        asstSubsAlloCont.getSubscriptionAllocations();
        asstSubsAlloCont.createSubscriptionAllocation();

        List<AssetSubscriptionAllocationModel> allocationsSub = asstSubsAlloCont.getSubscriptionAllocations();
        //system.assert(false, allocationsSub);

        allocationsSub[1].subscriptionAllocation.Subscription__c = subscriptionReplica.Id;
        allocationsSub[1].subscriptionAllocation.project__c = parentProject1.Id;
        allocationsSub[1].subscriptionAllocation.Quantity_Allocation__c = 2;
        allocationsSub[1].subscriptionAllocation.Percent_Allocation__c = 20;

        asstSubsAlloCont.saveSubscriptionAllocation();
        system.assertEquals(subscriptionReplica.Id, asstSubsAlloCont.Subscription.Id);
        system.assert(ApexPages.hasMessages(ApexPages.Severity.CONFIRM),'Saved Successfully.');

        //        system.assert(ApexPages.hasMessages(ApexPages.Severity.CONFIRM), 'Saved Successfully.');
        ApexPages.currentPage().getParameters().put('newSubscriptionRowId', '0');
        asstSubsAlloCont.changeSubscription();
        ApexPages.currentPage().getParameters().put('delSubscriptionRowId', subscriptionReplica.Id);
        asstSubsAlloCont.deleteSubscriptionAllocation();
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Error while deleting asset allocation. ');
        ApexPages.currentPage().getParameters().put('delSubscriptionRowId', '0');
        asstSubsAlloCont.deleteSubscriptionAllocation();
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), '');

        asstSubsAlloCont.cancel();
        Test.stopTest();
    }


    static testMethod void AssetAllocationFlaseQuantityControllerTest() {

        createSimpleTestData();
        Test.startTest();
        Test.setCurrentPage(Page.AssetSubscriptionAllocation);
        ApexPages.currentPage().getParameters().put('id', parentProject1.Id);
        asstSubsAlloCont = new AssetSubscriptionAllocationController();

        ApexPages.currentPage().getParameters().put('id', TestAsset1.Id);

        asstSubsAlloCont = new AssetSubscriptionAllocationController();
        asstSubsAlloCont.getAssetAllocations();
        asstSubsAlloCont.createAssetAllocation();
        asstSubsAlloCont.createAssetAllocation();
//        TestAsset.Quantity = 1;
//        update TestAsset;

        List<AssetSubscriptionAllocationModel> allocations = asstSubsAlloCont.getAssetAllocations();

//
        allocations[0].assetAllocation.Asset__c = TestAsset1.Id;
        allocations[0].assetAllocation.Project__c = parentProject1.Id;
        //allocations[0].assetAllocation.Percent_Allocation__c = 10;
        allocations[0].assetAllocation.Quantity_Allocation__c = 10;
        //allocations[0].assetAllocation.Hours_Allocated__c = 1;

        allocations[1].assetAllocation.Asset__c = TestAsset1.Id;
        allocations[1].assetAllocation.Project__c = parentProject1.Id;
        //allocations[1].assetAllocation.Percent_Allocation__c = 10;
        allocations[1].assetAllocation.Quantity_Allocation__c = 100;
        //allocations[1].assetAllocation.Hours_Allocated__c = 1;


        //system.assert(false, allocations);
        asstSubsAlloCont.saveAssetAllocation();

        system.assertEquals(TestAsset1.Id, asstSubsAlloCont.Asset.Id);
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),'One or more line item(s) has error.');
        asstSubsAlloCont.cancel();
        Test.stopTest();

    }



    static testMethod void AssetAllocationFlaseQuantity1ControllerTest() {

        createSimpleTestData();
        Test.startTest();
        Test.setCurrentPage(Page.AssetSubscriptionAllocation);
        ApexPages.currentPage().getParameters().put('id', parentProject1.Id);
        asstSubsAlloCont = new AssetSubscriptionAllocationController();

        ApexPages.currentPage().getParameters().put('id', TestAsset1.Id);

        asstSubsAlloCont = new AssetSubscriptionAllocationController();
        asstSubsAlloCont.getAssetAllocations();
        asstSubsAlloCont.createAssetAllocation();
//        TestAsset.Quantity = 1;
//        update TestAsset;

        List<AssetSubscriptionAllocationModel> allocations = asstSubsAlloCont.getAssetAllocations();

//
        allocations[0].assetAllocation.Asset__c = TestAsset1.Id;
        allocations[0].assetAllocation.Project__c = parentProject1.Id;
        allocations[0].assetAllocation.Percent_Allocation__c = 10;
        allocations[0].assetAllocation.Quantity_Allocation__c = 10;
        allocations[0].assetAllocation.Hours_Allocated__c = 1;


        //system.assert(false, allocations);
        asstSubsAlloCont.saveAssetAllocation();

        system.assertEquals(TestAsset1.Id, asstSubsAlloCont.Asset.Id);
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),'One or more line item(s) has error.');
        asstSubsAlloCont.cancel();
        Test.stopTest();

    }

    static testMethod void SubscriptionAllocationFalseQuantityControllerTest(){
        createSimpleTestData();
        Test.startTest();
        Test.setCurrentPage(Page.AssetSubscriptionAllocation);

        ApexPages.currentPage().getParameters().put('id', parentProject1.Id);

        asstSubsAlloCont = new AssetSubscriptionAllocationController();
        system.assertEquals(parentProject1.Id, asstSubsAlloCont.Project.Id);

        ApexPages.currentPage().getParameters().put('id', subscriptionReplica1.Id);

        asstSubsAlloCont = new AssetSubscriptionAllocationController();
        asstSubsAlloCont.getSubscriptionAllocations();
        asstSubsAlloCont.createSubscriptionAllocation();

        List<AssetSubscriptionAllocationModel> allocationsSub = asstSubsAlloCont.getSubscriptionAllocations();
        //system.assert(false, allocationsSub);

        allocationsSub[0].subscriptionAllocation.Subscription__c = subscriptionReplica1.Id;
        allocationsSub[0].subscriptionAllocation.project__c = parentProject1.Id;
        allocationsSub[0].subscriptionAllocation.Quantity_Allocation__c = 1;
        allocationsSub[0].subscriptionAllocation.Percent_Allocation__c = 10;

        asstSubsAlloCont.saveSubscriptionAllocation();
        system.assertEquals(subscriptionReplica1.Id, asstSubsAlloCont.Subscription.Id);
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),'One or more line item(s) has error.');

        Test.stopTest();
    }

}