@IsTest
private class PSProjectAssetAttachmentTest {

    private static Account accountRecord;
    private static Project__c parentProject1;
    private static Project__c childProject1;
    private static ImplementedProduct__c ip1;
    private static SBQQ__QuoteLine__c QuoteLine;
    private static SBQQ__Subscription__c subscription;
     /**** Following methods create test data ******/

    public static void createSimpleTestData(){

        //creates the required strcuture for the test
        system.debug('starting test data creation');

        // Create account
        accountRecord = InContactBaseClass.CreateAccount('Test Account');
        insert accountRecord;

        Map<String, RecordTypeInfo> oppRecordTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Id oppRTId = oppRecordTypeMap.get('Education Request').getRecordTypeId();

        Opportunity opp = new Opportunity(
                Name = 'Test',
                AccountId = accountRecord.Id,
                StageName = 'Assigned',
                CloseDate = Date.today(),
                RecordTypeId = oppRTId,
                PM_Estimated_Go_Live__c = system.today(),
                PM_Go_Live_Date__c  = null
        );

        insert opp;

        Map<String, RecordTypeInfo> projectRecordTypeMap = Schema.SObjectType.Project__c.getRecordTypeInfosByName();
        Id childRTId = projectRecordTypeMap.get('PS Project Phase SaaS').getRecordTypeId();
        Id parentProjectRTId = projectRecordTypeMap.get('PS Parent Project - SaaS').getRecordTypeId();

        // Parent Project
        parentProject1 = new Project__c(
                RecordTypeId = parentProjectRTId,
                Summary__c = 'This is the parent Project 1',
                ProjectType__c = 'CEM',
                Opportunity__c = opp.Id,
                Status__c = '0 - PreSale'
        );

        insert parentProject1;

        // Parent Project
        childProject1 = new Project__c(
                RecordTypeId = childRTId,
                Summary__c = 'This is the Child Project 1',
                ProjectType__c = 'CEM',
                ParentProject__c = parentProject1.Id,
                Opportunity__c = opp.Id,
                Status__c = '0 - PreSale'
        );

        insert childProject1;

        List<ImplementedProduct__c> implementedProducts = new List<ImplementedProduct__c>();
        ip1 = new ImplementedProduct__c(
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


        SBQQ__Quote__c objQuote = createQuoteTestData(opp);

        QuoteLine = new SBQQ__QuoteLine__c();
        QuoteLine.SBQQ__Product__c = p.Id;
        QuoteLine.SBQQ__Existing__c = true;
        QuoteLine.SBQQ__NetPrice__c  = 20.00;
        QuoteLine.SBQQ__Quantity__c = 5;
        QuoteLine.SBQQ__Quote__c = objQuote.Id;
        //q1.SBQQ__Assets__r = asset1.id;
        insert (QuoteLine);

    }


    public static SBQQ__Quote__c createQuoteTestData(Opportunity opp) {

        Id strRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.RecordTypeInfosByName.get('SaaS').RecordTypeId;

        SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
        objQuote.SBQQ__Account__c = opp.AccountId;
        objQuote.SBQQ__Opportunity2__c = opp.Id;
        objQuote.SBQQ__Type__c = 'Quote';
        objQuote.SBQQ__Status__c = 'Draft';
        objQuote.RecordTypeId = strRecordtypeId;
        objQuote.Usage_Rate_Type__c = 'Flat Usage Rates';
        objQuote.Flat_Usage_Rates__c ='0.0140';
        insert objQuote;
        return objQuote;
    }

    //begin unit tests

    // verify asset is attached to the parent project related to opportunity
    static testmethod void TestAssetAttachment(){

        // create test data
        createSimpleTestData();

        Profile orderManagementProfile = [SELECT Id from Profile where Name = 'Order Management'];
        User orderManagementUser = new User(
                FirstName = 'Order Management',
                LastName = 'User',
                Email = 'OrderManagement@incontact.com',
                Username = 'OrderManagementuser@incontact.com',
                Alias = 'test',
                profileId = orderManagementProfile.Id,
                EmailEncodingKey = 'UTF-8',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                UserRoleId = userinfo.getUserRoleId()
        );
        system.runAs(new User(Id = userInfo.getUserId())){
            insert orderManagementUser;
        }


        test.startTest();

        List<Asset> assets = new List<Asset>();

        // inserting asset will execute the trigger
        Asset testAsset = new Asset(
                Name = 'Asset asset1',
                Project_Phase__c = childProject1.Id,
                ImplementedProduct__c = ip1.Id,
                AccountId = accountRecord.Id,
                SBQQ__QuoteLine__c = QuoteLine.id
        );
        assets.add(testAsset);
        system.runAs(orderManagementUser){
            insert assets;
        }

        test.stopTest();

        Asset assertAsset = [Select Id, Parent_Project__c from Asset where Id = :testAsset.Id];

        system.assertEquals(parentProject1.Id, assertAsset.Parent_Project__c);
    }

    // verify custom subscription is attached to the parent project related to opportunity
    static testmethod void TestCustomSubscriptionAttachment(){

        // create test data
        createSimpleTestData();
        test.startTest();

        // inserting SBQQ subscription will create custom subscription and execute the trigger

        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c =  accountRecord.id;
        subscription.SBQQ__QuoteLine__c = QuoteLine.id;
        subscription.SBQQ__Quantity__c = 1;
        insert subscription;

        test.stopTest();

        List<SubscriptionReplica__c> customSubscriptions = [
                Select Id, ParentProject__c from SubscriptionReplica__c
                where Subscription__c = :subscription.Id
        ];
        system.assertEquals(1, customSubscriptions.size(), 'Custom subscription should be created.');

        system.assertEquals(parentProject1.Id, customSubscriptions[0].ParentProject__c);

    }

}