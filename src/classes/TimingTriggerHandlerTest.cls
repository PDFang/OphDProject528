/**
 * Created by arnab.karsarkar on 12/14/2017.
 */
@IsTest
public class TimingTriggerHandlerTest {


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
	static SBQQ__Subscription__c subscription;
	static SubscriptionReplica__c subscriptionReplica;
	static Project_Subscription_Allocation__c projectSubscriptionAllocation;
	static Project_Asset_Allocation__c projectAssetAllocation = null;
    static WorkIt2__Session_Type__c session_type;
    static list<WorkIt2__Time_Entry__c> timeEntryList;
	static list<WorkIt2__Timing__c> timings;
	static Opportunity o;




	public static testMethod void testAssetTime(){
		ProjectRollupQueueable.doChainJob = false;
		createTestData();

		Test.startTest();
		timeEntryList[0].WorkIt2__Force_End__c = System.now();
		update timeEntryList[0];

		System.enqueueJob(new AssetRollupQueueable(new set<id>{assetList[0].Id}));

		System.enqueueJob(new ProjectRollupQueueable(new set<id>{projectList[0].Id}));

		System.enqueueJob(new OpportunityRollupQueueable(new Set<Id>{o.Id}));

		Test.stopTest();

		WorkIt2__Timing__c timingTest = [select WorkIt2__Time_In_Hours__c from WorkIt2__Timing__c where Id = : timings[0].Id];

		Asset testasset= [select Logged_Hours__c from Asset where id = : assetList[0].Id];
		System.assertEquals(timingTest.WorkIt2__Time_In_Hours__c, testasset.Logged_Hours__c, 'Hours Match');

		Project__c phaseProject= [select Phase_Logged_Hours__c from Project__c where id = : projectList[1].Id];
		System.assertEquals(timingTest.WorkIt2__Time_In_Hours__c, phaseProject.Phase_Logged_Hours__c, 'Phase Project Hours Match');

		Project__c parentProject= [select Parent_Logged_Hours__c from Project__c where id = : projectList[0].Id];
		System.assertEquals(timingTest.WorkIt2__Time_In_Hours__c, parentProject.Parent_Logged_Hours__c, 'Parent Project Hours Match');

		Opportunity testOppy= [select Logged_Hours__c from Opportunity where id = : o.Id];
		System.assertEquals(timingTest.WorkIt2__Time_In_Hours__c, testOppy.Logged_Hours__c, 'Opportunity Hours Match');

	}


	public static testMethod void testSubscriptionTime(){

		ProjectRollupQueueable.doChainJob = false;
		createTestData();

		Test.startTest();
		timeEntryList[1].WorkIt2__Force_End__c = System.now();
		update timeEntryList[1];

		System.enqueueJob(new SubscriptionRollupQueueable(new set<id>{subscription.Id}));

		System.enqueueJob(new ProjectRollupQueueable(new set<id>{projectList[0].Id}));

		System.enqueueJob(new OpportunityRollupQueueable(new Set<Id>{o.Id}));

		Test.stopTest();

		WorkIt2__Timing__c timingTest = [select WorkIt2__Time_In_Hours__c from WorkIt2__Timing__c where Id = : timings[0].Id];

		SubscriptionReplica__c testSubscription= [select Logged_Hours__c from SubscriptionReplica__c where id = : subscriptionReplica.Id];
		System.assertEquals(timingTest.WorkIt2__Time_In_Hours__c, testSubscription.Logged_Hours__c, 'Hours Match');

		Project__c phaseProject= [select Phase_Logged_Hours__c from Project__c where id = : projectList[1].Id];
		System.assertEquals(timingTest.WorkIt2__Time_In_Hours__c, phaseProject.Phase_Logged_Hours__c, 'Phase Project Hours Match');

		Project__c parentProject= [select Parent_Logged_Hours__c from Project__c where id = : projectList[0].Id];
		System.assertEquals(timingTest.WorkIt2__Time_In_Hours__c, parentProject.Parent_Logged_Hours__c, 'Parent Project Hours Match');

		Opportunity testOppy= [select Logged_Hours__c from Opportunity where id = : o.Id];
		System.assertEquals(timingTest.WorkIt2__Time_In_Hours__c, testOppy.Logged_Hours__c, 'Opportunity Hours Match');




	}


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
		createAssets();
		createSubscription();
		createTimingData();
	}

	static void createAccount()
	{

		acct = new Account(
				Name = 'TimingTriggerHandlerTest Account',
				RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS)
		);
		insert acct;
	}

	static void createProducts()
	{
		productList = new List<Product2>();

		Product2 p1 = new Product2();
		p1.Name     = 'TimingTriggerHandlerTest 1';
		p1.ProductCode ='1111';
		p1.Category__c = 'Maintenance';
		productList.add(p1);

		Product2 p2 = new Product2();
		p2.Name     = 'TimingTriggerHandlerTest 2';
		p2.ProductCode ='1097';
		p2.Category__c ='Integration';
		productList.add(p2);

		insert productList;

	}

	static void createProjects()
	{


		o = new Opportunity();
		o.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Qualified Opportunity', 'Opportunity');
		o.Name = 'test';
		o.CloseDate = system.today().addDays(30);
		o.StageName = 'Open';
		o.AccountId = acct.Id;

		insert o;


		projectList = new List<Project__c>();

		Project__c project1 = new Project__c();
		project1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_SAAS);
		project1.Projected_Deadline__c = system.today() + 30;
		project1.Opportunity__c = o.Id;
		projectList.add(project1);

		Project__c phase1 = new Project__c();
		phase1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_SAAS);
		phase1.Projected_Deadline__c = system.today() + 30;
		projectList.add(phase1);

        insert projectList;

		phase1.ParentProject__c = project1.Id;
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
		asset1.Product2Id = productList[0].Id;
		asset1.Quantity = 10;
		asset1.Price = 10.00;
		assetList.add(asset1);

		insert assetList;

		projectAssetAllocation = new Project_Asset_Allocation__c(
				Asset__c = assetList[0].Id,
				Project__c = projectList[1].Id,
				Quantity_Allocation__c = 5

		);

		insert  projectAssetAllocation;
		System.debug('projectAssetAllocation =>' + projectAssetAllocation);


	}

	static void createSubscription() {
		subscription = new SBQQ__Subscription__c();
		subscription.SBQQ__Account__c = acct.id;
		subscription.SBQQ__Quantity__c = 10;
		subscription.SBQQ__Product__c = productList[0].Id;
		subscription.Budgeted_Hours__c = 10;
		subscription.Project_Phase__c = projectList[1].Id;

		insert subscription;

		subscriptionReplica = new SubscriptionReplica__c();
		subscriptionReplica = [SELECT Id, Account__c, Product__c, ParentProject__c, Subscription__r.Project_Phase__c, Quantity__c, Subscription__c FROM SubscriptionReplica__c WHERE Subscription__c = :subscription.Id limit 1];
		subscriptionReplica.ParentProject__c = projectList[0].id;
		update subscriptionReplica;

		projectSubscriptionAllocation = new Project_Subscription_Allocation__c(
				Project__c = subscriptionReplica.Subscription__r.Project_Phase__c,
				Subscription__c = subscriptionReplica.Id,
				Quantity_Allocation__c = 5
		);
		insert projectSubscriptionAllocation;
	}

	static void createTimingData(){
		session_type = new WorkIt2__Session_Type__c(
			Name = 'Reviewing Details Test',
			WorkIt2__Priority__c = 50
		);

		insert session_type;

		timings = new list<WorkIt2__Timing__c>();
		WorkIt2__Timing__c asset_timing = new WorkIt2__Timing__c(
				Project_Asset_Allocation__c = projectAssetAllocation.Id
		);

		timings.add(asset_timing);

		WorkIt2__Timing__c subscription_timing = new WorkIt2__Timing__c(
				Project_Subscription_Allocation__c = projectSubscriptionAllocation.Id
		);

		timings.add(subscription_timing);

		insert timings;

		timeEntryList = new list<WorkIt2__Time_Entry__c>();

		WorkIt2__Time_Entry__c time_entry1 = new WorkIt2__Time_Entry__c(
					WorkIt2__Session_Type__c = session_type.Id,
					WorkIt2__Start__c = System.now().addHours(-1),
					WorkIt2__Timing__c = timings[0].Id
		);
		timeEntryList.add(time_entry1);

		WorkIt2__Time_Entry__c time_entry2 = new WorkIt2__Time_Entry__c(
				WorkIt2__Session_Type__c = session_type.Id,
				WorkIt2__Start__c = System.now().addHours(-1),
				WorkIt2__Timing__c = timings[1].Id
		);

		timeEntryList.add(time_entry2);

		insert timeEntryList;

	}

}