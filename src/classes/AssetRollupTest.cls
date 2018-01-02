@IsTest
private class AssetRollupTest {
    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String OPPORTUNITY_TYPE_PM_STANDARD = 'PM-Standard';
    static final String PROJECT_TYPE_PARENT_SAAS = 'PS Parent Project - SaaS';
    static final String PROJECT_TYPE_PHASE_SAAS = 'PS Project Phase SaaS';
    static final String ASSET_TYPE_PREMISE = 'Premise Asset';
    static final String ASSET_TYPE_SAAS = 'SaaS Asset';

    static final Set<String> recordTypeSet = new Set<String>
    {
            ACCOUNT_TYPE_CUSTOMERS,
            OPPORTUNITY_TYPE_PM_STANDARD,
            PROJECT_TYPE_PARENT_SAAS,
            PROJECT_TYPE_PHASE_SAAS,
            ASSET_TYPE_PREMISE,
            ASSET_TYPE_SAAS
    };

    private static Map<String, Id> recordTypeMap;
    private static Account acct;
    static Opportunity testOpportunity = null;
    private static List<Product2> productList;
    private static List<Project__c> projectList;
    private static List<Asset> assetList;
    private static List<Project_Asset_Allocation__c> assetAllocations;

    static testMethod void testProjectPhaseFieldRollup() {
        createTestData();

        test.startTest();

        /*
        Asset Contracted NRR (Quantity * Sales_Price__c)
            5 * 10 = 50
            1 * 100 = 100
            1 * 500 = 500
            2 * 1000 = 2000
            ---------------
            2650

         Asset Actual NRR (Total_Implemented_Quantity__c * Sales_Price__c)
            3 * 10 = 30
            1 * 100 = 100
            0 * 500 = 0
            1 * 1000 = 1000
            ---------------
            1130
         */


        //the rollup queue process may have already run, but we need it to run again as AssetAllocations are inserted
        //so, reset the flag
        AssetTriggerHandler.assetRollupQueueableJobID = null;
        createAssetAllocations();

        test.stopTest();

        Project__c testProject = [select Contracted_NRR__c, Actual_NRR__c from Project__c where Id = :projectList[1].Id];

        system.assertEquals(2650, testProject.Contracted_NRR__c, 'Sum of Contracted_NRR__c was incorrect');
        system.assertEquals(1130, testProject.Actual_NRR__c, 'Sum of Actual_NRR__C was incorrect');
    }

    static testMethod void assetRollupSchedulableTest() {

        createTestData();

        Datetime nextRun = system.now().addSeconds(5);
        String dateTimeFormat = '{0} {1} {2} {3} {4} ? {5}';
        String scheduledTime = string.format(
                dateTimeFormat,
                new String[]{
                        nextRun.second().format(),
                        nextRun.minute().format(),
                        nextRun.hour().format(),
                        nextRun.day().format(),
                        nextRun.month().format(),
                        nextRun.year().format().remove(',')
                }
        );
        system.debug('scheduleJob(): scheduledTime - ' + scheduledTime);

        test.startTest();

        AssetRollupSchedulable schedulable = new AssetRollupSchedulable(1);
        schedulable = new AssetRollupSchedulable('Select Id from Asset', 10);

        String scheduledJobId = system.schedule('assetRollupSchedulableTest1', scheduledTime, schedulable);

        test.stopTest();

        CronTrigger job = [Select Id, State, NextFireTime, CronExpression From CronTrigger where Id = :scheduledJobId];

        system.assertEquals(scheduledTime, job.CronExpression);

    }

    static void createTestData()
    {
        recordTypeMap = new Map<String, Id>();
        for(RecordType record : [Select Id, Name from RecordType
        where Name IN :recordTypeSet])
        {
            recordTypeMap.put(record.Name, record.Id);
        }

        createAccount();

        createOpportunity();

        createProducts();

        createProjects();

        createAssets();
    }

    private static void createAccount()
    {
        acct = new Account(
                Name = 'AssetTriggerHandlerTest Account',
                RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS)
        );
        insert acct;
    }

    static void createOpportunity(){

        testOpportunity = new Opportunity(
                Name = 'AssetTriggerHandlerTest Opp 1',
                AccountId = acct.Id,
                RecordTypeId = recordTypeMap.get(OPPORTUNITY_TYPE_PM_STANDARD),
                StageName = 'Prospecting',
                CloseDate = Date.today(),
                Probability = 25,
                Partner_Deal__c = 'NO',
                Contract_Type__c = 'New Customer'
        );

        insert testOpportunity;

    }

    private static void createProducts()
    {
        productList = new List<Product2>();

        Product2 p1 = new Product2();
        p1.Name     = 'AssetTriggerHandlerTest 1';
        p1.ProductCode ='1111';
        p1.Category__c = 'Maintenance';
        productList.add(p1);

        Product2 p2 = new Product2();
        p2.Name     = 'AssetTriggerHandlerTest 2';
        p2.ProductCode ='1097';
        p2.Category__c ='Integration';
        productList.add(p2);

        insert productList;

    }

    private static void createProjects()
    {
        projectList = new List<Project__c>();

        Project__c project1 = new Project__c();
        project1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_SAAS);
        project1.Projected_Deadline__c = system.today() + 30;
        project1.Opportunity__c = testOpportunity.Id;
        projectList.add(project1);

        insert project1;

        Project__c phase1 = new Project__c();
        phase1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_SAAS);
        phase1.Projected_Deadline__c = system.today() + 30;
        phase1.ParentProject__c = project1.Id;
        projectList.add(phase1);

        insert phase1;

//        phase1.ParentProject__c = project1.Id;
//        phase1.Phase_Status__c = 'Closed';
//        update phase1;

    }

    private static void createAssets()
    {
        assetList = new List<Asset>();

        Asset asset1 = new Asset();
        asset1.RecordTypeId = recordTypeMap.get(ASSET_TYPE_PREMISE);
        asset1.Name = 'AssetTriggerHandlerTest Asset 1';
        asset1.AccountId = acct.Id;
        asset1.Parent_Project__c = projectList[0].Id;
        asset1.Product2Id = productList[0].Id;
        asset1.Quantity = 5;
        asset1.Sales_Price__c = 10.00;
        assetList.add(asset1);

        Asset asset2 = new Asset();
        asset2.RecordTypeId = recordTypeMap.get(ASSET_TYPE_PREMISE);
        asset2.Name = 'AssetTriggerHandlerTest Asset 2';
        asset2.AccountId = acct.Id;
        asset2.Parent_Project__c = projectList[0].Id;
        asset2.Product2Id = productList[0].Id;
        asset2.Quantity = 1;
        asset2.Sales_Price__c = 100.00;
        assetList.add(asset2);

        //create SaaS assets
        Asset asset3 = new Asset();
        asset3.RecordTypeId = recordTypeMap.get(ASSET_TYPE_SAAS);
        asset3.Name = 'AssetTriggerHandlerTest Saas Asset 1';
        asset3.AccountId = acct.Id;
        asset3.Parent_Project__c = projectList[0].Id;
        asset3.Sales_Price__c = 500.00;
        asset3.Quantity = 1.00;
        asset3.Type__c = 'MRC';
        assetList.add(asset3);

        Asset asset4 = new Asset();
        asset4.RecordTypeId = recordTypeMap.get(ASSET_TYPE_SAAS);
        asset4.Name = 'AssetTriggerHandlerTest Saas Asset 1';
        asset4.AccountId = acct.Id;
        asset4.Parent_Project__c = projectList[0].Id;
        asset4.Sales_Price__c = 1000.00;
        asset4.Quantity = 2.00;
        asset4.Type__c = 'NRC';
        assetList.add(asset4);

        insert assetList;
    }

    public static void createAssetAllocations() {
        assetAllocations = new List<Project_Asset_Allocation__c>();

        assetAllocations.add(new Project_Asset_Allocation__c(
                Asset__c = assetList[0].Id,
                Project__c = projectList[1].Id,
                Phase_Implemented_Quantity__c = 3,
                Quantity_Allocation__c = 5
        ));

        assetAllocations.add(new Project_Asset_Allocation__c(
                Asset__c = assetList[1].Id,
                Project__c = projectList[1].Id,
                Phase_Implemented_Quantity__c = 1,
                Quantity_Allocation__c = 1
        ));
        assetAllocations.add(new Project_Asset_Allocation__c(
                Asset__c = assetList[2].Id,
                Project__c = projectList[1].Id,
                Phase_Implemented_Quantity__c = 0,
                Quantity_Allocation__c = 1
        ));
        assetAllocations.add(new Project_Asset_Allocation__c(
                Asset__c = assetList[3].Id,
                Project__c = projectList[1].Id,
                Phase_Implemented_Quantity__c = 1,
                Quantity_Allocation__c = 2
        ));

        insert assetAllocations;
    }
}