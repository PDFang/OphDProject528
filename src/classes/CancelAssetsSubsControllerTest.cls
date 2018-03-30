/**
 * Created by arnab.karsarkar on 3/28/2018.
 */

@isTest
public with sharing class CancelAssetsSubsControllerTest {

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
	private static CancelAssetsSubsController canAssetSubCntrl;


	static testMethod void CancellationTest(){
		createTestData();
		createSubscription();
		createAssets();
		Test.startTest();
		//ApexPages.currentPage().getParameters().put('id', projectList[0].Id);
		canAssetSubCntrl = new CancelAssetsSubsController(new ApexPages.StandardController(projectList[0]));

		List<SelectOption> options = canAssetSubCntrl.Departments;
		system.assertNotEquals(0, options.size());

		List<SelectOption> optionsRootCase = canAssetSubCntrl.RootCase;
		system.assertNotEquals(0, optionsRootCase.size());


		canAssetSubCntrl.cancel();

		string assets = CancelAssetsSubsController.GetAllAssets(projectList[0].Id);
		string subs = CancelAssetsSubsController.GetAllSubscriptions(projectList[0].Id);

		List<Asset> cancelAsset = new list<Asset>{new Asset(Id = assetList[0].Id,
				QuantityCancelled__c = assetList[0].RemainingQuantity__c ,
				Department_Responsible__c = 'Customer',
				Root_Cause__c = 'Configuration',
				Additional_Detail__c = 'Test')};

		string jSonString = JSON.serialize(cancelAsset);

		string message = CancelAssetsSubsController.CancelAllAssets(jSonString);
		System.debug('message = > ' + message);
		//System.assertEquals(true, message.containsIgnoreCase('Success'));

		List<SubscriptionReplica__c> canSubs = new list<SubscriptionReplica__c>{ new SubscriptionReplica__c(
				Id = subscriptionReplica.Id,
				QuantityCancelled__c = subscriptionReplica.RemainingQuantity__c ,
				Department_Responsible__c = 'Customer',
				Root_Cause__c = 'Configuration',
				Additional_Detail__c = 'Test')};

		string jSonStringSubs = JSON.serialize(canSubs);

		string subsMessage = CancelAssetsSubsController.CancelAllSubs(jSonStringSubs);
		//System.assertEquals(true, subsMessage.containsIgnoreCase('Success'));

		canAssetSubCntrl = new CancelAssetsSubsController(new ApexPages.StandardController(projectList[1]));

		CancelAssetsSubsController.simplyfyErrorMessage('Test');
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
				Project__c = projectList[1].Id,
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