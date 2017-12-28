@IsTest
private class AssetTriggerHandlerTest {

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

    static Map<String, Id> recordTypeMap = null;
    static Account acct = null;
    static Opportunity testOpportunity = null;
    static List<Product2> productList = null;
    static List<Project__c> projectList = null;
    static List<Asset> assetList = null;

    /**** Validate Project asset totals on asset creation ***/
    static testMethod void addAssetTotalTest()
    {
        createTestData();
        Test.startTest();
        createAssets();
        Test.stopTest();

        /*** Assert PS Project Phase ***/
        // Expected
        AggregateResult ar = [select SUM(Price), SUM(FinalPrice__c)
                                FROM Asset
                                WHERE Project_Phase__c = :projectList[2].Id];

        Decimal phaseAsset = decimal.valueOf(string.valueOf(ar.get('expr0'))) + decimal.valueOf(string.valueOf(ar.get('expr1')));

        ar = [select SUM(FinalPrice__c)
                FROM Asset
                WHERE Project_Phase__c = :projectList[2].Id
                AND Type__c = 'MRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal phaseMRC = decimal.valueOf(string.valueOf(ar.get('expr0')));

        ar = [select SUM(FinalPrice__c)
                FROM Asset
                WHERE Project_Phase__c = :projectList[2].Id
                AND Type__c = 'NRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal phaseNRC = decimal.valueOf(string.valueOf(ar.get('expr0')));

        // Actual
        Project__c result = [select Phase_Asset__c, PhaseMRC__c, PhaseNRC__c from Project__c where Id = :projectList[2].Id];

        system.assertEquals(phaseAsset, result.Phase_Asset__c);
        system.assertEquals(phaseMRC, result.PhaseMRC__c);
        system.assertEquals(phaseNRC, result.PhaseNRC__c);

        /*** Assert PS Parent Project Phase ***/

        // Expected
        ar  = [SELECT SUM(Price), SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Parent_Project__c = :projectList[0].Id];
        Decimal projectAsset = decimal.valueOf(string.valueOf(ar.get('expr0'))) + decimal.valueOf(string.valueOf(ar.get('expr1')));

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Parent_Project__c = :projectList[0].Id
                    AND Type__c = 'MRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal projectMRC = decimal.valueOf(string.valueOf(ar.get('expr0')));

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Parent_Project__c = :projectList[0].Id
                    AND Type__c = 'NRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal projectNRC = decimal.valueOf(string.valueOf(ar.get('expr0')));

        // actual
        result = [select Project_Asset__c, ProjectMRC__c, ProjectNRC__c from Project__c where Id = :projectList[0].Id];

        system.assertEquals(projectAsset, result.Project_Asset__c);
        system.assertEquals(projectMRC, result.ProjectMRC__c);
        system.assertEquals(projectNRC, result.ProjectNRC__c);

    } // end of addAssetTotalTest()

    /**** Validate Project asset totals on asset updation ***/
    static testMethod void updateAssetTotalTest()
    {
        createTestData();
        createAssets();

        Test.startTest();
        // change parent project
        assetList[0].Parent_Project__c = projectList[1].Id;
        assetList[1].Parent_Project__c = projectList[1].Id;
        // Change Project Phase
        assetList[2].Project_Phase__c = projectList[3].Id;
        assetList[3].Project_Phase__c = projectList[3].Id;
        // Change price
        assetList[1].Price = 80;
        // Change quantity
        assetList[2].Quantity = 5;
        // Change Type
        assetList[2].Type__c = 'Telco';
        assetList[3].Type__c = 'MRC'; // Change Type
        update assetList;


        /*** Assert PS Project Phase ***/
        // Expected
        AggregateResult ar = [select SUM(Price), SUM(FinalPrice__c)
                                    FROM Asset
                                    WHERE Project_Phase__c = :projectList[2].Id];

        Decimal phaseAsset = decimal.valueOf(string.valueOf(ar.get('expr0'))) + decimal.valueOf(string.valueOf(ar.get('expr1')));

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Project_Phase__c = :projectList[2].Id
                    AND Type__c = 'MRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal phaseMRC = (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0')));

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Project_Phase__c = :projectList[2].Id
                    AND Type__c = 'NRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal phaseNRC = (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0')));

        // Actual
        Project__c result = [select Phase_Asset__c, PhaseMRC__c, PhaseNRC__c, Phase_Telco__c from Project__c where Id = :projectList[2].Id];

        system.assertEquals(phaseAsset, result.Phase_Asset__c);
        system.assertEquals(phaseMRC, result.PhaseMRC__c);
        system.assertEquals(phaseNRC, result.PhaseNRC__c);

        /*** Assert PS Project Phase ***/
        // Expected
        ar = [select SUM(Price), SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Project_Phase__c = :projectList[3].Id];

        phaseAsset = ( (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0'))) )
                            + ( (ar.get('expr1') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr1'))) );

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Project_Phase__c = :projectList[3].Id
                    AND Type__c = 'MRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        phaseMRC = (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0')));

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Project_Phase__c = :projectList[3].Id
                    AND Type__c = 'Telco' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal phaseTelco = (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0')));

        // Actual
        result = [select Phase_Asset__c, PhaseMRC__c, PhaseNRC__c, Phase_Telco__c from Project__c where Id = :projectList[3].Id];

        system.assertEquals(phaseAsset, result.Phase_Asset__c);
        system.assertEquals(phaseMRC, result.PhaseMRC__c);
        system.assertEquals(phaseTelco, result.Phase_Telco__c);

        /*** Assert PS Parent Project Phase ***/

        // Expected
        ar  = [SELECT SUM(Price), SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Parent_Project__c = :projectList[0].Id];
        Decimal projectAsset = ( (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0'))) )
                                    + ( (ar.get('expr1') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr1'))) );

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Parent_Project__c = :projectList[0].Id
                    AND Type__c = 'MRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal projectMRC = (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0')));

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Parent_Project__c = :projectList[0].Id
                    AND Type__c = 'NRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal projectNRC = (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0')));

        // actual
        result = [select Project_Asset__c, ProjectMRC__c, ProjectNRC__c from Project__c where Id = :projectList[0].Id];

        system.assertEquals(projectAsset, result.Project_Asset__c);
        system.assertEquals(projectMRC, result.ProjectMRC__c);
        system.assertEquals(projectNRC, result.ProjectNRC__c);

        /*** Assert PS Parent Project Phase ***/

        // Expected
        ar  = [SELECT SUM(Price), SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Parent_Project__c = :projectList[1].Id];
        projectAsset = ( (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0'))) )
                            + ( (ar.get('expr1') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr1'))) );

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Parent_Project__c = :projectList[1].Id
                    AND Type__c = 'MRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        projectMRC = (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0')));

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Parent_Project__c = :projectList[1].Id
                    AND Type__c = 'NRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        projectNRC = (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0')));

        // actual
        result = [select Project_Asset__c, ProjectMRC__c, ProjectNRC__c from Project__c where Id = :projectList[1].Id];

        system.assertEquals(projectAsset, result.Project_Asset__c);
        system.assertEquals(projectMRC, result.ProjectMRC__c);
        system.assertEquals(projectNRC, result.ProjectNRC__c);

        Test.stopTest();

    } // end of updateAssetTotalTest()

    /**** Validate Project asset totals on asset deletion ***/
    static testMethod void deleteAssetTotalTest()
    {
        createTestData();
        createAssets();

        Test.startTest();
        List<Asset> deleteList = new List<Asset>();
        deleteList.add(assetList[0]);
        deleteList.add(assetList[2]);
        delete deleteList; // delete assets
        Test.stopTest();

        /*** Assert PS Project Phase ***/
        // Expected
        AggregateResult ar = [select SUM(Price), SUM(FinalPrice__c)
        FROM Asset
        WHERE Project_Phase__c = :projectList[2].Id];

        Decimal phaseAsset = decimal.valueOf(string.valueOf(ar.get('expr0'))) + decimal.valueOf(string.valueOf(ar.get('expr1')));

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Project_Phase__c = :projectList[2].Id
                    AND Type__c = 'MRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal phaseMRC = (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0')));

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Project_Phase__c = :projectList[2].Id
                    AND Type__c = 'NRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal phaseNRC = (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0')));

        // Actual
        Project__c result = [select Phase_Asset__c, PhaseMRC__c, PhaseNRC__c from Project__c where Id = :projectList[2].Id];

        system.assertEquals(phaseAsset, result.Phase_Asset__c);
        system.assertEquals(phaseMRC, result.PhaseMRC__c);
        system.assertEquals(phaseNRC, result.PhaseNRC__c);

        /*** Assert PS Parent Project Phase ***/

        // Expected
        ar  = [SELECT SUM(Price), SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Parent_Project__c = :projectList[0].Id];
        Decimal projectAsset = decimal.valueOf(string.valueOf(ar.get('expr0'))) + decimal.valueOf(string.valueOf(ar.get('expr1')));

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Parent_Project__c = :projectList[0].Id
                    AND Type__c = 'MRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal projectMRC = (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0')));

        ar = [select SUM(FinalPrice__c)
                    FROM Asset
                    WHERE Parent_Project__c = :projectList[0].Id
                    AND Type__c = 'NRC' AND RecordType.Name = :ASSET_TYPE_SAAS];
        Decimal projectNRC = (ar.get('expr0') == null) ? 0.0 : decimal.valueOf(string.valueOf(ar.get('expr0')));

        // actual
        result = [select Project_Asset__c, ProjectMRC__c, ProjectNRC__c from Project__c where Id = :projectList[0].Id];

        system.assertEquals(projectAsset, result.Project_Asset__c);
        system.assertEquals(projectMRC, result.ProjectMRC__c);
        system.assertEquals(projectNRC, result.ProjectNRC__c);

    } // end of deleteAssetTotalTest()


    /**** Following methods create test data ******/

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
        //createAssets();
    }

    static void createAccount()
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

    static void createProducts()
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

    static void createProjects()
    {
        projectList = new List<Project__c>();

        Project__c project1 = new Project__c();
        project1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_SAAS);
        project1.Projected_Deadline__c = system.today() + 30;
        project1.Opportunity__c = testOpportunity.Id;
        projectList.add(project1);

        Project__c project2 = new Project__c();
        project2.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_SAAS);
        project2.Projected_Deadline__c = system.today() + 30;
        project2.Opportunity__c = testOpportunity.Id;
        projectList.add(project2);

        Project__c phase1 = new Project__c();
        phase1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_SAAS);
        phase1.Projected_Deadline__c = system.today() + 30;
        projectList.add(phase1);

        Project__c phase2 = new Project__c();
        phase2.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_SAAS);
        phase2.Projected_Deadline__c = system.today() + 30;
        projectList.add(phase2);

        insert projectList;

        phase1.ParentProject__c = project1.Id;
        phase1.Phase_Status__c = 'Closed';
        phase1.ActualProjectGoLiveDate__c = system.today();
        update phase1;

    }

    static void createAssets()
    {
        assetList = new List<Asset>();

        Asset asset1 = new Asset();
        asset1.RecordTypeId = recordTypeMap.get(ASSET_TYPE_PREMISE);
        asset1.Name = 'AssetTriggerHandlerTest Asset 1';
        asset1.AccountId = acct.Id;
        asset1.Parent_Project__c = projectList[0].Id;
        asset1.Project_Phase__c = projectList[2].Id;
        asset1.Product2Id = productList[0].Id;
        asset1.Quantity = 1;
        asset1.Price = 10.00;
        assetList.add(asset1);

        Asset asset2 = new Asset();
        asset2.RecordTypeId = recordTypeMap.get(ASSET_TYPE_PREMISE);
        asset2.Name = 'AssetTriggerHandlerTest Asset 2';
        asset2.AccountId = acct.Id;
        asset2.Parent_Project__c = projectList[0].Id;
        asset2.Project_Phase__c = projectList[2].Id;
        asset2.Product2Id = productList[0].Id;
        asset2.Quantity = 1;
        asset2.Price = 100.00;
        assetList.add(asset2);

        //create SaaS assets
        Asset asset3 = new Asset();
        asset3.RecordTypeId = recordTypeMap.get(ASSET_TYPE_SAAS);
        asset3.Name = 'AssetTriggerHandlerTest Saas Asset 1';
        asset3.AccountId = acct.Id;
        asset3.Parent_Project__c = projectList[0].Id;
        asset3.Project_Phase__c = projectList[2].Id;
        asset3.Sales_Price__c = 500.00;
        asset3.Quantity = 1.00;
        asset3.Type__c = 'MRC';
        assetList.add(asset3);

        Asset asset4 = new Asset();
        asset4.RecordTypeId = recordTypeMap.get(ASSET_TYPE_SAAS);
        asset4.Name = 'AssetTriggerHandlerTest Saas Asset 1';
        asset4.AccountId = acct.Id;
        asset4.Parent_Project__c = projectList[0].Id;
        asset4.Project_Phase__c = projectList[2].Id;
        asset4.Sales_Price__c = 1000.00;
        asset4.Quantity = 2.00;
        asset4.Type__c = 'NRC';
        assetList.add(asset4);

        insert assetList;
    }
}