/**
 * Created by william.nelson on 6/22/2017.
 */

public with sharing class PSProjectAssetAttachmentTest {


    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String PROJECT_TYPE_PARENT_SAAS = 'PS Parent Project - SaaS';
    static final String PROJECT_TYPE_PHASE_SAAS = 'PS Project Phase SaaS';
    static final String ASSET_TYPE_PREMISE = 'Premise Asset';
    static final String ASSET_TYPE_SAAS = 'SaaS Asset';

    static final Set<String> recordTypeSet = new Set<String>
    {
            ACCOUNT_TYPE_CUSTOMERS,
            PROJECT_TYPE_PARENT_SAAS,
            PROJECT_TYPE_PHASE_SAAS,
            ASSET_TYPE_PREMISE,
            ASSET_TYPE_SAAS
    };

    static Map<String, Id> recordTypeMap = null;
    static Account acct = null;
    static List<Product2> productList = null;
    static List<Project__c> projectList = null;
    static List<Asset> assetList = null;









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
        projectList.add(project1);

        Project__c project2 = new Project__c();
        project2.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_SAAS);
        project2.Projected_Deadline__c = system.today() + 30;
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