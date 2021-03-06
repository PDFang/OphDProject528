/**
 * Created by ravish.chawla on 10/25/2017.
 */

@IsTest
private class AssetSubscriptionAllocationNewCtrlTest {
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
    static ImplementedProduct__c implementedProduct = null;
    static List<Product2> productList = null;
    static List<Project__c> projectList = null;
    static List<Asset> assetList = null;
    static Project_Asset_Allocation__c projectAssetAllocation = null;
    private static SBQQ__Subscription__c subscription;
    private static SubscriptionReplica__c subscriptionReplica;
    private static Project_Subscription_Allocation__c projectSubscriptionAllocation;
    private static AssetSubscriptionAllocationNewController asstSubsAlloCont;


    static testMethod void AssetAllocationNewControllerTest() {

        createTestData();
        createAssets();
        Test.startTest();
        Test.setCurrentPage(Page.AssetSubscriptionAllocationNew);

	    ApexPages.currentPage().getParameters().put('id', null);
	    asstSubsAlloCont = new AssetSubscriptionAllocationNewController();

	    ApexPages.currentPage().getParameters().put('id', projectList[1].Id);
        asstSubsAlloCont = new AssetSubscriptionAllocationNewController();
        ApexPages.currentPage().getParameters().put('id', assetList[0].Id);
        asstSubsAlloCont = new AssetSubscriptionAllocationNewController();


        Asset testAsset = asstSubsAlloCont.Asset;
        SubscriptionReplica__c testReplica = asstSubsAlloCont.Subscription;
        Project__c testProject = asstSubsAlloCont.Project;

        string objType = AssetSubscriptionAllocationNewController.getObjectType(assetList[0].Id);
        System.debug('objType =>' + objType);
        System.assertEquals('Asset', objType);

        string assetAllocationRes = AssetSubscriptionAllocationNewController.getAssetAllocationData(null, assetList[0].Id);
        System.debug('assetAllocationRes =>' + assetAllocationRes);
        System.assertNotEquals(null, assetAllocationRes);

        assetAllocationRes = assetAllocationRes.remove('[');
        assetAllocationRes = assetAllocationRes.remove(']');
        System.debug('assetAllocationRes =>' + assetAllocationRes);
        string assetAllocationRes1 = AssetSubscriptionAllocationNewController.UpsertAssetSubscriptionAllocation(objType, assetAllocationRes);
        System.debug('assetAllocationRes1 =>' + assetAllocationRes1);
        System.assertNotEquals(null, assetAllocationRes1);

        string phaseProjectResponse = AssetSubscriptionAllocationNewController.PhaseProjectDetails(assetList[0].Id, objType);
        System.debug('phaseProjectResponse =>' + phaseProjectResponse);
        System.assertNotEquals(null, phaseProjectResponse);

        string assetSubsResponseFromProj = AssetSubscriptionAllocationNewController.AssetSubscriptionDetailsFromProjectPhase(projectList[1].Id, objType);
        //System.debug('assetSubsResponseFromProj =>' + assetSubsResponseFromProj);
        System.assertNotEquals(null, assetSubsResponseFromProj);

        asstSubsAlloCont.Asset.QuantityCancelled__c = 2;
	    asstSubsAlloCont.Asset.QuantityonHold__c = 0;
        asstSubsAlloCont.SaveCancSuspQuantity();
        //System.debug('ApexPages.hasMessages(ApexPages.Severity.ERROR) ==>' + ApexPages.hasMessages(ApexPages.Severity.ERROR));
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Department Responsible or Root Cause can not be empty if Quantity Cancelled is greater than 0.');

        asstSubsAlloCont.Asset.QuantityonHold__c = 2;
	    asstSubsAlloCont.Asset.QuantityCancelled__c = 0;

        asstSubsAlloCont.SaveCancSuspQuantity();
        //System.debug('ApexPages.hasMessages(ApexPages.Severity.ERROR) ==>' + ApexPages.hasMessages(ApexPages.Severity.ERROR));
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Department Responsible or Root Cause can not be empty if Quantity On Hold is greater than 0.');

	    asstSubsAlloCont.Asset.QuantityonHold__c = 2;
	    asstSubsAlloCont.Asset.QuantityCancelled__c = 0;
	    asstSubsAlloCont.Asset.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Asset.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Asset.Additional_Detail__c = null;
	    asstSubsAlloCont.SaveCancSuspQuantity();
	    //System.debug('ApexPages.hasMessages(ApexPages.Severity.ERROR) ==>' + ApexPages.hasMessages(ApexPages.Severity.ERROR));
	    system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Additional Detail must be populated if the Quantity  on Hold is greater than 0.');

	    asstSubsAlloCont.Asset.QuantityonHold__c = 2;
	    asstSubsAlloCont.Asset.QuantityCancelled__c = 0;
	    asstSubsAlloCont.Asset.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Asset.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Asset.Additional_Detail__c = null;
	    asstSubsAlloCont.SaveCancSuspQuantity();
	    //System.debug('ApexPages.hasMessages(ApexPages.Severity.ERROR) ==>' + ApexPages.hasMessages(ApexPages.Severity.ERROR));
	    system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Additional Detail must be populated if the Quantity  Cancelled is greater than 0.');

        asstSubsAlloCont.Asset.QuantityCancelled__c = 5;
        asstSubsAlloCont.Asset.QuantityonHold__c = 0;
	    asstSubsAlloCont.Asset.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Asset.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Asset.Additional_Detail__c = 'test';
        asstSubsAlloCont.SaveCancSuspQuantity();
        //System.debug('ApexPages.hasMessages(ApexPages.Severity.ERROR) ==>' + ApexPages.hasMessages(ApexPages.Severity.ERROR));
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Only managers can suspend or cancel the entire quantity of an asset or subscription.');


	    asstSubsAlloCont.Asset.QuantityCancelled__c = 3;
	    asstSubsAlloCont.Asset.QuantityonHold__c = 3;
	    asstSubsAlloCont.Asset.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Asset.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Asset.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantity();

        asstSubsAlloCont.Asset.QuantityCancelled__c = 1;
        asstSubsAlloCont.Asset.QuantityonHold__c = 1;
        asstSubsAlloCont.Asset.Root_Cause__c = 'Configuration';
        asstSubsAlloCont.Asset.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Asset.Additional_Detail__c = 'test';
        asstSubsAlloCont.SaveCancSuspQuantity();

	    asstSubsAlloCont.Asset.QuantityCancelled__c = 1;
	    asstSubsAlloCont.Asset.QuantityonHold__c = 1;
	    asstSubsAlloCont.Asset.Root_Cause__c = 'Against policy/regulations';
	    asstSubsAlloCont.Asset.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Asset.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantity();


	    //System.debug('ApexPages.hasMessages(ApexPages.Severity.CONFIRM) ==>' + ApexPages.hasMessages(ApexPages.Severity.CONFIRM));
       //system.assert(ApexPages.hasMessages(ApexPages.Severity.CONFIRM), 'Saved Successfully.');

        asstSubsAlloCont.Asset.QuantityCancelled__c = 16;
        asstSubsAlloCont.Asset.QuantityonHold__c = 0;
        asstSubsAlloCont.Asset.Root_Cause__c = 'Configuration';
        asstSubsAlloCont.Asset.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Asset.Additional_Detail__c = 'test';
        asstSubsAlloCont.SaveCancSuspQuantity();
        //System.debug('ApexPages.hasMessages(ApexPages.Severity.ERROR) ==>' + ApexPages.hasMessages(ApexPages.Severity.ERROR));
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), '"Cancelled Quantity" cannot exceed the contract quantity');

        asstSubsAlloCont.Asset.QuantityCancelled__c = 0;
        asstSubsAlloCont.Asset.QuantityonHold__c = 4;
        asstSubsAlloCont.Asset.Root_Cause__c = 'Configuration';
        asstSubsAlloCont.Asset.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Asset.Additional_Detail__c = 'test';
        asstSubsAlloCont.SaveCancSuspQuantity();


        asstSubsAlloCont.Asset.QuantityCancelled__c = 4;
        asstSubsAlloCont.Asset.QuantityonHold__c = 0;
        asstSubsAlloCont.Asset.Root_Cause__c = 'Configuration';
        asstSubsAlloCont.Asset.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Asset.Additional_Detail__c = 'test';
        asstSubsAlloCont.SaveCancSuspQuantity();




        projectAssetAllocation.Implemented__c = true;
	    projectAssetAllocation.Phase_Implemented_Quantity__c = 2;
        update projectAssetAllocation;

        asstSubsAlloCont.Asset.QuantityCancelled__c = 0;
        asstSubsAlloCont.Asset.QuantityonHold__c = 4;
        asstSubsAlloCont.Asset.Root_Cause__c = 'Configuration';
        asstSubsAlloCont.Asset.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Asset.Additional_Detail__c = 'test';
        asstSubsAlloCont.SaveCancSuspQuantity();


	    asstSubsAlloCont.Asset.QuantityCancelled__c = 4;
	    asstSubsAlloCont.Asset.QuantityonHold__c = 0;
	    asstSubsAlloCont.Asset.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Asset.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Asset.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantity();

	    asstSubsAlloCont.Asset.QuantityCancelled__c = 2;
	    asstSubsAlloCont.Asset.QuantityonHold__c = 2;
	    asstSubsAlloCont.Asset.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Asset.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Asset.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantity();



	    Test.setCurrentPageReference(new PageReference('Page.AssetSubscriptionAllocationNew'));
	    System.debug('implementedProduct =>> ' + implementedProduct);
        System.currentPageReference().getParameters().put('rowid', implementedProduct.Id);
        asstSubsAlloCont.saveImplementedProduct();
        asstSubsAlloCont.deleteAssetAllocation();

	    string assetAllocationDel = AssetSubscriptionAllocationNewController.DeleteAllocation(projectAssetAllocation.Id, objType);
	    //System.debug('assetAllocationDel =>' + assetAllocationDel);
	    System.assertNotEquals(null, assetAllocationDel);

	    Test.stopTest();

    }


    static testMethod void SubscriptionAllocationNewControllerTest() {

        createTestData();
        createSubscription();
        Test.startTest();
        Test.setCurrentPage(Page.AssetSubscriptionAllocationNew);
        ApexPages.currentPage().getParameters().put('id', subscriptionReplica.Id);
        //ApexPages.currentPage().getParameters().put('id', assetList[2].Id);
        asstSubsAlloCont = new AssetSubscriptionAllocationNewController();

        string objType = AssetSubscriptionAllocationNewController.getObjectType(subscriptionReplica.Id);
        System.debug('objType =>' + objType);
        System.assertEquals('Subscription', objType);

        string subscriptionAllocationRes = AssetSubscriptionAllocationNewController.getSubscriptionAllocationData(null, subscriptionReplica.Id);
        System.debug('subscriptionAllocationRes =>' + subscriptionAllocationRes);
        System.assertNotEquals(null, subscriptionAllocationRes);

        subscriptionAllocationRes = subscriptionAllocationRes.remove('[');
        subscriptionAllocationRes = subscriptionAllocationRes.remove(']');
        System.debug('subscriptionAllocationRes =>' + subscriptionAllocationRes);
        string subscriptionAllocationRes1 = AssetSubscriptionAllocationNewController.UpsertAssetSubscriptionAllocation(objType, subscriptionAllocationRes);
        System.debug('subscriptionAllocationRes1 =>' + subscriptionAllocationRes1);
        System.assertNotEquals(null, subscriptionAllocationRes1);

        string phaseProjectResponse = AssetSubscriptionAllocationNewController.PhaseProjectDetails(subscriptionReplica.Id, objType);
        System.debug('phaseProjectResponse =>' + phaseProjectResponse);
        System.assertNotEquals(null, phaseProjectResponse);

        string assetSubsResponseFromProj = AssetSubscriptionAllocationNewController.AssetSubscriptionDetailsFromProjectPhase(projectList[1].Id, objType);
        System.debug('assetSubsResponseFromProj =>' + assetSubsResponseFromProj);
        System.assertNotEquals(null, assetSubsResponseFromProj);

        asstSubsAlloCont.cancel();
        asstSubsAlloCont.reloadDetails();


        asstSubsAlloCont.Subscription.QuantityCancelled__c = 2;
        asstSubsAlloCont.Subscription.QuantityonHold__c = 0;
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
        asstSubsAlloCont.SaveCancSuspQuantitySubs();
        System.debug('ApexPages.hasMessages(ApexPages.Severity.ERROR) ==>' + ApexPages.hasMessages(ApexPages.Severity.ERROR));
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Department Responsible or Root Cause can not be empty if Quantity Cancelled is greater than 0.');

        asstSubsAlloCont.Subscription.QuantityonHold__c = 2;
        asstSubsAlloCont.Subscription.QuantityonHold__c = 0;
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
        asstSubsAlloCont.SaveCancSuspQuantitySubs();
        System.debug('ApexPages.hasMessages(ApexPages.Severity.ERROR) ==>' + ApexPages.hasMessages(ApexPages.Severity.ERROR));
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Department Responsible or Root Cause can not be empty if Quantity On Hold is greater than 0.');

        asstSubsAlloCont.Subscription.QuantityCancelled__c = 0;
	    asstSubsAlloCont.Subscription.QuantityonHold__c = 5;
	    asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Subscription.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantitySubs();
	    System.debug('ApexPages.hasMessages(ApexPages.Severity.ERROR) ==>' + ApexPages.hasMessages(ApexPages.Severity.ERROR));
	    system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Only managers can suspend or cancel the entire quantity of an asset or subscription.');

	    asstSubsAlloCont.Subscription.QuantityCancelled__c = 2;
	    asstSubsAlloCont.Subscription.QuantityonHold__c = 0;
	    asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Subscription.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = null;
	    asstSubsAlloCont.SaveCancSuspQuantitySubs();
	    System.debug('ApexPages.hasMessages(ApexPages.Severity.ERROR) ==>' + ApexPages.hasMessages(ApexPages.Severity.ERROR));
	    system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Additional Detail must be populated if the Quantity Cancelled is greater than 0.');

	    asstSubsAlloCont.Subscription.QuantityCancelled__c = 2;
	    asstSubsAlloCont.Subscription.QuantityonHold__c = 0;
	    asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Subscription.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = null;
	    asstSubsAlloCont.SaveCancSuspQuantitySubs();
	    System.debug('ApexPages.hasMessages(ApexPages.Severity.ERROR) ==>' + ApexPages.hasMessages(ApexPages.Severity.ERROR));
	    system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Additional Detail must be populated if the Quantity on Hold is greater than 0.');



	    asstSubsAlloCont.Subscription.QuantityCancelled__c = 2;
        asstSubsAlloCont.Subscription.QuantityonHold__c = 2;
        asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
        asstSubsAlloCont.Subscription.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
        asstSubsAlloCont.SaveCancSuspQuantitySubs();
        System.debug('ApexPages.hasMessages(ApexPages.Severity.CONFIRM) ==>' + ApexPages.hasMessages(ApexPages.Severity.CONFIRM));
        //system.assert(ApexPages.hasMessages(ApexPages.Severity.CONFIRM), 'Saved Successfully.');

        asstSubsAlloCont.Subscription.QuantityCancelled__c = 15;
        asstSubsAlloCont.Subscription.QuantityonHold__c = 0;
        asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
        asstSubsAlloCont.Subscription.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
        asstSubsAlloCont.SaveCancSuspQuantitySubs();

	    asstSubsAlloCont.Subscription.QuantityCancelled__c = 0;
	    asstSubsAlloCont.Subscription.QuantityonHold__c = 15;
	    asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Subscription.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantitySubs();

	    asstSubsAlloCont.Subscription.QuantityCancelled__c = 3;
	    asstSubsAlloCont.Subscription.QuantityonHold__c = 3;
	    asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Subscription.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantitySubs();

	    asstSubsAlloCont.Subscription.QuantityCancelled__c = 3;
	    asstSubsAlloCont.Subscription.QuantityonHold__c = 2;
	    asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Subscription.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantitySubs();

	    projectSubscriptionAllocation.Implemented__c = true;
	    projectSubscriptionAllocation.Phase_Implemented_Quantity__c = 2;
	    update projectSubscriptionAllocation;

	    asstSubsAlloCont.Subscription.QuantityCancelled__c = 4;
	    asstSubsAlloCont.Subscription.QuantityonHold__c = 0;
	    asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Subscription.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantitySubs();

	    asstSubsAlloCont.Subscription.QuantityCancelled__c = 0;
	    asstSubsAlloCont.Subscription.QuantityonHold__c = 4;
	    asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Subscription.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantitySubs();

	    asstSubsAlloCont.Subscription.QuantityCancelled__c = 2;
	    asstSubsAlloCont.Subscription.QuantityonHold__c = 2;
	    asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Subscription.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantitySubs();

	    asstSubsAlloCont.Subscription.QuantityCancelled__c =1;
	    asstSubsAlloCont.Subscription.QuantityonHold__c = 1;
	    asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Subscription.Department_Responsible__c = 'Customer';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantitySubs();


	    asstSubsAlloCont.Subscription.QuantityCancelled__c =1;
	    asstSubsAlloCont.Subscription.QuantityonHold__c = 1;
	    asstSubsAlloCont.Subscription.Root_Cause__c = 'Configuration';
	    asstSubsAlloCont.Subscription.Department_Responsible__c = 'Accounting/Billing';
	    asstSubsAlloCont.Subscription.Additional_Detail__c = 'test';
	    asstSubsAlloCont.SaveCancSuspQuantitySubs();

        Test.setCurrentPageReference(new PageReference('Page.AssetSubscriptionAllocationNew'));
        System.debug('implementedProduct =>> ' + implementedProduct);
        System.currentPageReference().getParameters().put('rowid', implementedProduct.Id);
        asstSubsAlloCont.saveImplementedProduct();
        asstSubsAlloCont.deleteSubsAllocation();
        boolean isManager = asstSubsAlloCont.Manager;

       // system.assertEquals(false, isManager);

	    string subscriptionAllocationDel = AssetSubscriptionAllocationNewController.DeleteAllocation(projectSubscriptionAllocation.Id, objType);
	    System.debug('subscriptionAllocationDel =>' + subscriptionAllocationDel);
	    System.assertNotEquals(null, subscriptionAllocationDel);


	    Test.stopTest();

    }


	static testMethod void PhaseProjectNewControllerTest(){
		createTestData();
		createSubscription();
		createAssets();
		Test.startTest();
			ApexPages.currentPage().getParameters().put('id', projectList[1].Id);
		    asstSubsAlloCont = new AssetSubscriptionAllocationNewController();

			string message = AssetSubscriptionAllocationNewController.CancelAllocations(projectList[1].Id);
			System.assertEquals(true, message.containsIgnoreCase('Successfully'));

			string holdMessage = AssetSubscriptionAllocationNewController.ManageOnHoldAllocations(projectList[1].Id, true);
			//System.assertEquals(true, holdMessage.containsIgnoreCase('Successfully'));

			set<id> assetIds = new set<id>{assetList[0].Id};
			set<id> subscriptionIds = new set<id>{subscriptionReplica.Id};

			string assetIdString = JSON.serialize(assetIds);
			string subscriptionIdString = JSON.serialize(assetIds);

			string saveMessage = AssetSubscriptionAllocationNewController.SaveAllAllocation(assetIdString, subscriptionIdString,projectList[1].Id);
			//System.assertEquals(true, saveMessage.containsIgnoreCase('Success'));

			string allusers = AssetSubscriptionAllocationNewController.SearchUsers('Arnab');

		Test.stopTest();
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
        createProducts();
        createProjects();

        Opportunity o = new Opportunity();
        o.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Historical Products', 'Opportunity');
        o.Name = 'test';
        o.CloseDate = system.today().addDays(30);
        o.StageName = 'Open';
        o.AccountId = acct.Id;

        insert o;

        implementedProduct = new ImplementedProduct__c();
        implementedProduct.Account__c = acct.Id;
        implementedProduct.GoLiveDate__c = system.today() - 1;
        implementedProduct.Status__c = 'Implemented';
        implementedProduct.Product__c = 'inContact';
        implementedProduct.Opportunity__c = o.Id;
        insert implementedProduct;

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
        project1.ProjectManager__c = '00539000005M7TO';
        //project1.Projected_Deadline__c = system.today() + 30;
        projectList.add(project1);

        Project__c phase1 = new Project__c();
        phase1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_SAAS);
        phase1.ProjectManager__c = '00539000005M7TO';
        //phase1.Projected_Deadline__c = system.today() + 30;
        projectList.add(phase1);

        Project__c phase2 = new Project__c();
        phase2.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_SAAS);
        phase2.ProjectManager__c = '00539000005M7TO';
        //phase1.Projected_Deadline__c = system.today() + 30;
        projectList.add(phase2);

        insert projectList;

        phase1.ParentProject__c = project1.Id;
        //phase1.Phase_Status__c = 'Closed';
        update phase1;

        phase2.ParentProject__c = project1.Id;
        //phase1.Phase_Status__c = 'Closed';
        update phase2;

    }

    static void createAssets()
    {
        assetList = new List<Asset>();

        //create SaaS assets
        Asset asset3 = new Asset();
        asset3.RecordTypeId = recordTypeMap.get(ASSET_TYPE_SAAS);
        asset3.Name = 'AssetTriggerHandlerTest Saas Asset 1';
        asset3.AccountId = acct.Id;
        asset3.Parent_Project__c = projectList[0].Id;
        asset3.Project_Phase__c = projectList[1].Id;
        asset3.Sales_Price__c = 500.00;
        asset3.Quantity = 5.00;
        asset3.Type__c = 'MRC';
        assetList.add(asset3);

        //create SaaS assets
        Asset asset4 = new Asset();
        asset4.RecordTypeId = recordTypeMap.get(ASSET_TYPE_SAAS);
        asset4.Name = 'AssetTriggerHandlerTest Saas Asset 2';
        asset4.AccountId = acct.Id;
        asset4.Parent_Project__c = projectList[0].Id;
        asset4.Sales_Price__c = 1000.00;
        asset4.Quantity = 1.00;
        asset4.Type__c = 'NRC';
        assetList.add(asset4);

        insert assetList;
        System.debug('assetList =>' + assetList.size());


        projectAssetAllocation = new Project_Asset_Allocation__c(
                Asset__c = assetList[0].Id,
                Project__c = assetList[0].Project_Phase__c,
                Quantity_Allocation__c = 2

        );

        insert  projectAssetAllocation;
        System.debug('projectAssetAllocation =>' + projectAssetAllocation);


    }

    static void createSubscription(){
        subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c =  acct.id;
        //subscription.SBQQ__QuoteLine__c = QuoteLine.id;
        subscription.SBQQ__Quantity__c = 5;
        subscription.SBQQ__Product__c = productList[0].Id;
        subscription.Budgeted_Hours__c = 10;
        subscription.Project_Phase__c = projectList[1].Id;

        insert subscription;

        SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c();
        subscription2.SBQQ__Account__c =  acct.id;
        //subscripti2on.SBQQ__QuoteLine__c = QuoteLine.id;
        subscription2.SBQQ__Quantity__c = 1;
        subscription2.SBQQ__Product__c = productList[0].Id;
        subscription2.Budgeted_Hours__c = 10;
        subscription2.Project_Phase__c = projectList[1].Id;

        insert subscription2;

        subscriptionReplica = new SubscriptionReplica__c();
        subscriptionReplica = [SELECT Id, Account__c, Product__c, ParentProject__c, Subscription__r.Project_Phase__c, Quantity__c, Subscription__c FROM SubscriptionReplica__c WHERE Subscription__c = :subscription.Id limit 1];
        subscriptionReplica.ParentProject__c = projectList[0].id;
        update subscriptionReplica;

        SubscriptionReplica__c subscriptionReplica2 = new SubscriptionReplica__c();
        subscriptionReplica2 = [SELECT Id, Account__c, Product__c, ParentProject__c, Subscription__r.Project_Phase__c, Quantity__c, Subscription__c FROM SubscriptionReplica__c WHERE Subscription__c = :subscription2.Id limit 1];
        subscriptionReplica2.ParentProject__c = projectList[0].id;
        update subscriptionReplica2;

        projectSubscriptionAllocation = new Project_Subscription_Allocation__c(
                Project__c = subscriptionReplica.Subscription__r.Project_Phase__c,
                Subscription__c  = subscriptionReplica.Id,
                Quantity_Allocation__c = 2
        );
        insert projectSubscriptionAllocation;
    }
}