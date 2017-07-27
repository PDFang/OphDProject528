/**
 * Created by mohandaas.rangaswamy on 7/19/2017.
 */

@IsTest
private class AssetSubscriptionAllocationCtrlTest {

    private static Id childRTId = [SELECT id from RecordType where Name = 'PS Project Phase SaaS'].Id;
    private static Id parentProjectRTId = [SELECT id from RecordType where Name = 'PS Project Phase SaaS'].Id;

    private static Asset TestAsset;
    private static SBQQ__QuoteLine__c QuoteLine;
    private static Project__c parentProject1;
    private static SBQQ__Subscription__c subscription;
    private static SubscriptionReplica__c subscriptionReplica;

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
                ImplementedProduct__c = ip1.Id,
                AccountId = accountRecord.Id,
                SBQQ__QuoteLine__c = QuoteLine.id
        );
        //assets.add(TestAsset);
        insert TestAsset;

        system.debug('TestAsset =>' + TestAsset.Id);

        subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c =  accountRecord.id;
        subscription.SBQQ__QuoteLine__c = QuoteLine.id;
        subscription.SBQQ__Quantity__c = 1;
        insert subscription;

        subscriptionReplica = new SubscriptionReplica__c();
        subscriptionReplica = [SELECT Id, Account__c, Quote_Line__c, Quantity__c, Subscription__c FROM SubscriptionReplica__c WHERE Subscription__c = :subscription.Id limit 1];
        //insert subscriptionReplica;
        system.debug('subscriptionReplica.Subscription__c =>' + subscriptionReplica.Subscription__c);

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

    static testMethod void AssetSubscriptionAllocationControllerTest() {

        createSimpleTestData();
        //string id;
        //ApexPages.StandardController stdCtrl = new ApexPages.StandardController(changeRequest);
        Test.startTest();
        Test.setCurrentPage(Page.AssetSubscriptionAllocation);
        ApexPages.currentPage().getParameters().put('id', TestAsset.Id);
        //id= ApexPages.currentPage().getParameters().get('id');

        AssetSubscriptionAllocationController asstSubsAlloCont = new AssetSubscriptionAllocationController();
        system.assertEquals(TestAsset.Id, asstSubsAlloCont.Asset.Id);
        //        AssetSubscriptionAllocationBusinessLayer asstSubsAlloBusLayer = new AssetSubscriptionAllocationBusinessLayer(id);
//        asstSubsAlloBusLayer.currentAsset = TestAsset;
//        asstSubsAlloBusLayer.currentSubscription = subscriptionReplica;
//        asstSubsAlloBusLayer.currentProject = parentProject1;
        Test.stopTest();

    }

    static testMethod void AssetSubscriptionAllocationControllerTest1() {

        createSimpleTestData();
        //string id;
        //ApexPages.StandardController stdCtrl = new ApexPages.StandardController(changeRequest);
        Test.startTest();
        Test.setCurrentPage(Page.AssetSubscriptionAllocation);
        ApexPages.currentPage().getParameters().put('id', subscriptionReplica.Id);
        //id= ApexPages.currentPage().getParameters().get('id');

        AssetSubscriptionAllocationController asstSubsAlloCont = new AssetSubscriptionAllocationController();
//        system.debug('subscriptionReplica.Subscription__c =>' + subscriptionReplica.Subscription__c);
        system.assertEquals(subscriptionReplica.Id, asstSubsAlloCont.Subscription.Id);
        //        AssetSubscriptionAllocationBusinessLayer asstSubsAlloBusLayer = new AssetSubscriptionAllocationBusinessLayer(id);
//        asstSubsAlloBusLayer.currentAsset = TestAsset;
//        asstSubsAlloBusLayer.currentSubscription = subscriptionReplica;
//        asstSubsAlloBusLayer.currentProject = parentProject1;
        Test.stopTest();

    }

    static testMethod void AssetSubscriptionAllocationControllerTest2() {

        createSimpleTestData();
        system.debug('parentProject1.Id =>' + parentProject1.Id);
        //string id;
        //ApexPages.StandardController stdCtrl = new ApexPages.StandardController(changeRequest);
        Test.startTest();
        Test.setCurrentPage(Page.AssetSubscriptionAllocation);
        ApexPages.currentPage().getParameters().put('id', parentProject1.Id);
        //id= ApexPages.currentPage().getParameters().get('id');

        AssetSubscriptionAllocationController asstSubsAlloCont = new AssetSubscriptionAllocationController();

        system.assertEquals(parentProject1.Id, asstSubsAlloCont.Project.Id);
        //        AssetSubscriptionAllocationBusinessLayer asstSubsAlloBusLayer = new AssetSubscriptionAllocationBusinessLayer(id);
//        asstSubsAlloBusLayer.currentAsset = TestAsset;
//        asstSubsAlloBusLayer.currentSubscription = subscriptionReplica;
//        asstSubsAlloBusLayer.currentProject = parentProject1;
        Test.stopTest();

    }




}