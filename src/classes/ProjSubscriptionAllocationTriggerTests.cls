/**
 * Created by jeremy.sparrell on 1/30/2018.
 */
@IsTest
private class ProjSubscriptionAllocationTriggerTests {
    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String PROJECT_TYPE_PARENT_SAAS = 'PS Parent Project - SaaS';
    static final String PROJECT_TYPE_PHASE_SAAS = 'PS Project Phase SaaS';
	static SBQQ__QuoteLine__c QuoteLine;
	static SBQQ__Quote__c objQuote;
    static final Set<String> recordTypeSet = new Set<String>
    {
            ACCOUNT_TYPE_CUSTOMERS,
            PROJECT_TYPE_PARENT_SAAS,
            PROJECT_TYPE_PHASE_SAAS
    };

    static Map<String, Id> recordTypeMap = null;
    static Account acct = null;
    static ImplementedProduct__c implementedProduct = null;
    static List<Product2> productList = null;
    static List<Project__c> projectList = null;
    private static SBQQ__Subscription__c subscription;
    private static SubscriptionReplica__c subscriptionReplica;
    private static Project_Subscription_Allocation__c projectSubscriptionAllocation;
	static WorkIt2__Session_Type__c session_type;
	static list<WorkIt2__Time_Entry__c> timeEntryList;
	static list<WorkIt2__Timing__c> timings;

    static testMethod void AddParentProjectTest() {

        createTestData();
        createSubscription();

	    Project_Subscription_Allocation__c projectSubscriptionAllocation2 = new Project_Subscription_Allocation__c(
			    Project__c = projectList[2].id,
			    Subscription__c  = subscriptionReplica.Id,
			    Quantity_Allocation__c = 2
	    );


        Test.startTest();
        Project_Subscription_Allocation__c savedAllocation = [SELECT Id, ParentProjectId__c FROM Project_Subscription_Allocation__c WHERE Id = :projectSubscriptionAllocation.Id];
	    system.assertEquals(savedAllocation.ParentProjectId__c, projectList[0].Id);

	    insert projectSubscriptionAllocation2;

	    Project_Subscription_Allocation__c implementedAllocation = [SELECT Id, Implemented__c FROM Project_Subscription_Allocation__c WHERE Id = :projectSubscriptionAllocation2.Id];
	    system.assertEquals(implementedAllocation.Implemented__c, true);
        Test.StopTest();
    }

	static testMethod  void TestTimingError(){
		createTestData();
		createSubscription();
		createTimingData();
		try{

				//Project_Subscription_Allocation__c savedAllocation = [SELECT Id, ParentProjectId__c FROM Project_Subscription_Allocation__c WHERE Id = :projectSubscriptionAllocation.Id];
				delete projectSubscriptionAllocation;

		}catch (Exception ex){
			Boolean expectedExceptionThrown =  ex.getMessage().contains('Subscription Allocation can not be deleted as there are time enteries') ? true : false;
			System.AssertEquals(expectedExceptionThrown, true);
		}
	}

	static testMethod void TestRollup(){
		createTestData();
		createSubscription();

		Test.startTest();

		string localProjectId = projectSubscriptionAllocation.Project__c;
		Project__c projBeforeDelete = [select Contracted_MRR__c from Project__c where Id = :localProjectId];
		System.debug('actual MRR before delete ==> ' + projBeforeDelete.Contracted_MRR__c);
		delete projectSubscriptionAllocation;
		Test.StopTest();

		Project__c projafterDelete = [select Contracted_MRR__c from Project__c where Id = :localProjectId];
		System.debug('actual MRR before delete ==> ' + projBeforeDelete.Contracted_MRR__c);
		system.assertEquals(projafterDelete.Contracted_MRR__c, 0);
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

	    createQuoteTestData(o);



        implementedProduct = new ImplementedProduct__c();
        implementedProduct.Account__c = acct.Id;
        implementedProduct.GoLiveDate__c = system.today() - 1;
        implementedProduct.Status__c = 'Implemented';
        implementedProduct.Product__c = 'inContact';
        implementedProduct.Opportunity__c = o.Id;
        insert implementedProduct;


    }

	static void createQuoteTestData(Opportunity opp) {

		Id strRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.RecordTypeInfosByName.get('SaaS').RecordTypeId;

		objQuote = new SBQQ__Quote__c();
		objQuote.SBQQ__Account__c = opp.AccountId;
		objQuote.SBQQ__Opportunity2__c = opp.Id;
		objQuote.SBQQ__Type__c = 'Quote';
		objQuote.SBQQ__Status__c = 'Draft';
		objQuote.RecordTypeId = strRecordtypeId;
		objQuote.Usage_Rate_Type__c = 'Flat Usage Rates';
		objQuote.Flat_Usage_Rates__c ='0.0140';
		insert objQuote;
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
	    phase2.Phase_Status__c = 'Closed';
        projectList.add(phase2);

        insert projectList;

        phase1.ParentProject__c = project1.Id;
        //phase1.Phase_Status__c = 'Closed';
        update phase1;

        phase2.ParentProject__c = project1.Id;
        //phase1.Phase_Status__c = 'Closed';
        update phase2;

    }

    static void createSubscription(){


	    QuoteLine = new SBQQ__QuoteLine__c();
	    QuoteLine.SBQQ__Product__c = productList[0].Id;
	    QuoteLine.SBQQ__Existing__c = true;
	    QuoteLine.SBQQ__NetPrice__c  = 10.00;
	    QuoteLine.SBQQ__Quantity__c = 5;
	    QuoteLine.SBQQ__Quote__c = objQuote.Id;
	    //q1.SBQQ__Assets__r = asset1.id;
	    insert (QuoteLine);




        subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c =  acct.id;
        subscription.SBQQ__QuoteLine__c = QuoteLine.id;
        subscription.SBQQ__Quantity__c = 5;
        subscription.SBQQ__Product__c = productList[0].Id;
        subscription.Budgeted_Hours__c = 10;
        insert subscription;

        SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c();
        subscription2.SBQQ__Account__c =  acct.id;
        //subscripti2on.SBQQ__QuoteLine__c = QuoteLine.id;
        subscription2.SBQQ__Quantity__c = 1;
        subscription2.SBQQ__Product__c = productList[0].Id;
        subscription2.Budgeted_Hours__c = 10;


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
                Project__c = projectList[1].id,
                Subscription__c  = subscriptionReplica.Id,
                Quantity_Allocation__c = 2
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


		insert timeEntryList;

	}

}