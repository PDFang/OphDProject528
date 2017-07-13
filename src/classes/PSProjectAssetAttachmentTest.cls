/**
 * Created by william.nelson on 6/22/2017.
 */
@IsTest
public with sharing class PSProjectAssetAttachmentTest {

    private static Id childRTId = [SELECT id from RecordType where Name = 'PS Project Phase SaaS'].Id;
    private static Id parentProjectRTId = [SELECT id from RecordType where Name = 'PS Parent Project - SaaS'].Id;

    private static Asset TestAsset;
    private static SBQQ__QuoteLine__c QuoteLine;
    private static SBQQ__Subscription__c subscription;
     /**** Following methods create test data ******/

    public static void createSimpleTestData(){

        //creates the required strcuture for the test
        Id strRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.RecordTypeInfosByName.get('SaaS').RecordTypeId;
        system.debug('starting test data creation');
        List<ImplementedProduct__c> implementedProducts = new List<ImplementedProduct__c>();
        List<Asset> assets = new List<Asset>();
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
        Project__c parentProject1 = new Project__c(
                RecordTypeId = parentProjectRTId,
                Summary__c = 'This is the parent Project 1',
                ProjectType__c = 'CEM',
                Opportunity__c = opp.Id,
                Status__c = '0 - PreSale'
        );

        insert parentProject1;

        // Parent Project
        Project__c childProject1 = new Project__c(
                RecordTypeId = childRTId,
                Summary__c = 'This is the Child Project 1',
                ProjectType__c = 'CEM',
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
        assets.add(TestAsset);
        insert assets;

        subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c =  accountRecord.id;
        subscription.SBQQ__QuoteLine__c = QuoteLine.id;
        subscription.SBQQ__Quantity__c = 1;
        insert subscription;

    }


    public static SBQQ__Quote__c createQuoteTestData(Id strRecordtypeId, Id strAccId) {
        SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
        objQuote.SBQQ__Account__c = strAccId;
        objQuote.SBQQ__Type__c = 'Quote';
        objQuote.SBQQ__Status__c = 'Draft';
        objQuote.RecordTypeId = strRecordtypeId;
        insert objQuote;
        return objQuote;
    }

    //begin unit tests

    @IsTest
    public static void TestAssetAttachment(){
        //Arrange

        createSimpleTestData();
        test.startTest();
        system.debug('*** starting Test Run ***');
        //Act
        set<SBQQ__QuoteLine__c> QouteLines = new set<SBQQ__QuoteLine__c>();
        QouteLines.Add(QuoteLine);

        system.debug('*** Qoute Lines ==>' + QouteLines);
        set<Asset> Assets =  new set<Asset> ();
        Assets.Add(TestAsset);


        system.debug(' *** Assets ==>' + Assets);
        set<id>Assetids = new set<id>();
        for(Asset a : Assets){
            Assetids.add(a.Id);
        }
        system.debug(' ***Assets ==>' + AssetIds);
        set <id>QouteLineids = new set <id>();
        for (SBQQ__QuoteLine__c line :QouteLines)
        {
            QouteLineids.add(line.Id);
        }

        set<Id> subsciptions = new set<Id>();
        subsciptions.add(subscription.Id);


        system.debug('*** Qoute Lines ==>' + QouteLineids);
        PSProjectAssetAttachment.AttachAssetsByIdToParentProject(QouteLineids, Assetids, null);
        PSProjectAssetAttachment.AttachAssetsByIdToParentProject(QouteLineids, null, subsciptions);

        //PSProjectAssetAttachment.AttachAssetsByIdToParentProject(null, null, null);
        //Assert
        //nothing to assert
        test.stopTest();
    }

}