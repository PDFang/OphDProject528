@isTest
private class CaseAssignmentTestClass {

	public static testMethod void testCasesAssignment()
	{
		//bulk load cases
		List<Account> accounts = new List<Account>();
		//build accounts
		for (Integer i=0; i < 20; i++){
			Account a = inContactBaseClass.CreateAccount('testName' + i);
			a.Site = string.valueOf(i);
			a.CS_AM__c = UserInfo.getUserId();
			accounts.add(a);
		}
		
		insert accounts;
		System.debug('Insert accounts.');
		
		//get record type IDs
		Id rtIncident = '01270000000LuEpAAK';
		Id rtInfo = '01270000000LuEqAAK';
		Id rtWO = '01270000000LuErAAK';
		Id rtCustOther = '01270000000Lrn4AAC';
		
		List<Contact> contacts = new List<Contact>();
		//create contacts
		for(Account a:accounts)
		{
			Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
			contacts.add(ct);
			
		}
		
		insert contacts;
		
		
		//test bulk loading cases
		List<Case> cases = new List<Case>();
		
		for(Integer i=0;i<5;i++)
		{
			Case c = inContactBaseClass.CreateCase(accounts[i].Id, contacts[i].Id, rtWO, accounts[i].Name);
			c.Request_Type__c = 'Adds/Moves/Changes';
			c.Product_or_Service__c = 'DIA';
			c.Status = 'New';
			c.Freqeuncy__c = 'Occasional';
			c.Number_of_Customers_Affected__c = '1';
			c.Severity__c = 'S4';
			
			cases.add(c);
		}
		
		
		
		for(Integer i=0;i<5;i++)
		{
			Case c = inContactBaseClass.CreateCase(accounts[i].Id, contacts[i].Id, rtWO, accounts[i].Name);
			c.Request_Type__c = 'Application/Reporting/Scripting Issues';
			c.Product_or_Service__c = 'Coaching';
			c.Status = 'New';
			c.Freqeuncy__c = 'Constant';
			c.Number_of_Customers_Affected__c = '4 +';
			c.Severity__c = 'S1';


			cases.add(c);
		}
		
		for(Integer i=0;i<5;i++)
		{
			Case c = inContactBaseClass.CreateCase(accounts[i].Id, contacts[i].Id, rtWO, accounts[i].Name);
			c.Request_Type__c = 'Information Request';
			c.Product_or_Service__c = 'DIA';
			c.Status = 'New';
			c.Freqeuncy__c = 'Constant';
			c.Number_of_Customers_Affected__c = '1';
			c.Severity__c = 'S1';


			cases.add(c);
		}
		
		for(Integer i=0;i<5;i++)
		{
			Case c = inContactBaseClass.CreateCase(accounts[i].Id, contacts[i].Id, rtWO, accounts[i].Name);
			c.Request_Type__c = 'Not Sure...';
			c.Product_or_Service__c = 'DIA';
			c.Status = 'New';
			c.Freqeuncy__c = 'Occasional';
			c.Number_of_Customers_Affected__c = '1';
			c.Severity__c = 'S1';


			cases.add(c);
		}
		
		Test.startTest();		
		insert cases;
		
		Case c1 = cases[10];	
		
		c1.Status = 'Closed';
		c1.Disposition__c = 'Other';
		c1.Reason = 'Other';
		c1.WorkDuration__c = 10;
		c1.PublicComment__c = 'Test';
		c1.StatusDetails__c = 'Test';
		c1.FirstResponseViolated__c = true;
		c1.SLAViolated__c = true;
		
		update c1;
        
		Test.stopTest();
	}
	
	public static testMethod void testCaseUpdate()
	{ //update case
		Id sfQueue = '00G70000001ciT7';
		
		//Case c = [SELECT Id, OwnerId, Priority, Freqeuncy__c, Number_of_Customers_Affected__c, Severity__c FROM Case WHERE Priority = 'P4' AND Status != 'New' AND OwnerID != :sfQueue LIMIT 1];
		Account a = inContactBaseClass.CreateAccount('testName');
		insert a;
		
		Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com');
		insert ct;
		
		Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, inContactBaseClass.SelectRecordTypeIDByName('Incident', 'Case'), 'test subject');
		c.OwnerId = sfQueue;
		c.Origin = 'Web';
		c.Severity__c = 'S4';
		c.Priority = 'P4';
		
		insert c;
		
		c.OwnerId = sfQueue;
		c.Freqeuncy__c = 'Constant';
		c.Number_of_Customers_Affected__c = '4 +';
		c.Severity__c = 'S1';
		c.Priority = 'P1';
		c.WorkDuration__c = 10;
		c.PublicComment__c = 'Test';
		update c;
	}
	
	public static testMethod void testCaseUpdate2()
	{//update case
		Id sfQueue = '00G70000001ciT7';
		
		Account a = inContactBaseClass.CreateAccount('testName');
		insert a;
		
		Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com');
		insert ct;
		//Case c = [SELECT Id, OwnerId, Priority, Freqeuncy__c, Number_of_Customers_Affected__c, Severity__c FROM Case WHERE Priority = 'P1' AND Status != 'New' AND OwnerID = :sfQueue LIMIT 1];
		Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, inContactBaseClass.SelectRecordTypeIDByName('Incident', 'Case'), 'test subject');
		c.OwnerId = sfQueue;
		c.Origin = 'Web';
		c.Severity__c = 'S1';
		c.Priority = 'P1';
		
		insert c;
				
		c.Assigned_To__c = '00570000001GvceAAC';
		c.Freqeuncy__c = 'Occasional';
		c.Number_of_Customers_Affected__c = '1';
		c.Severity__c = 'S4';
		c.Priority = 'P4';
		update c;



	}

	// test incident case update to Advanced tech support
	public static testMethod void updateCaseComment(){

		//insertQueeueFuture();
		Group g1 = [select Id from Group where DeveloperName = 'TechSupportQueue' limit 1];
		Id sfQueue = '00G70000001ciT7';
		Account a = inContactBaseClass.CreateAccount('testName');
		insert a;

		Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com');
		insert ct;
		//Case c = [SELECT Id, OwnerId, Priority, Freqeuncy__c, Number_of_Customers_Affected__c, Severity__c FROM Case WHERE Priority = 'P1' AND Status != 'New' AND OwnerID = :sfQueue LIMIT 1];
		Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, inContactBaseClass.SelectRecordTypeIDByName('Incident', 'Case'), 'test subject');
		c.OwnerId =sfQueue;
		c.Origin = 'Web';
		c.Severity__c = 'S1';
		c.Priority = 'P1';

		insert c;
		system.debug('g1.Id ===>' + g1.Id);
		c.SLA_Halfway__c = true;
		c.OwnerId = g1.Id;
		update c;

		CaseComment [] comments = [select Id, CommentBody from CaseComment where ParentId = :c.Id];
		system.assertEquals(1, comments.size());



	}
	
	static testMethod void TestCaseReassignExtension()
    {
        //create test account
        Account a = inContactBaseClass.CreateAccount('testName');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
        a.CSM__c = UserInfo.getUserId();
        a.TechnicalSuccessManagerprimary__c = UserInfo.getUserId();
        a.TSA__c = UserInfo.getUserId();
        a.TSA_Manager__c = UserInfo.getUserId();
                
        insert a;
        System.debug('Insert accounts.');
        
        //get record type IDs
        Id rtIncident = '01270000000LuEpAAK';
        Id rtInfo = '01270000000LuEqAAK';
        Id rtWO = '01270000000LuErAAK';
        Id rtCustOther = '01270000000Lrn4AAC';
        
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
                            
        insert ct;
        
        //create test case      
        Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, rtWO, a.Name);
        c.Request_Type__c = 'Adds/Moves/Changes';
        c.Product_or_Service__c = 'DIA';
        c.Status = 'New';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';
        
        insert c;
        
        ApexPages.StandardController controller = new ApexPages.StandardController(c);
        CaseReassignExtension extension = new CaseReassignExtension(controller);
        
        List<SelectOption> queues = extension.AvailableQueues;
                
        try
        {
        	extension.Save();	
        }
        catch(Exception ex)
        {
        	system.assertEquals(ex.getMessage(), 'User is required.');
        }
        
        extension.assignBy = 'User';
        c.Assigned_To__c = UserInfo.getUserId();
        extension.UpdateUsersQueue();
        
        try
        {
        	extension.Save();	
        }
        catch(Exception ex)
        {
        	system.assertEquals(ex.getMessage(), 'Queue is required.');
        }
        
        extension.selectedQueue = queues[1].getValue();
        
        try
        {
        	extension.Save();	
        }
        catch(Exception ex)
        {
        	system.assertEquals(ex.getMessage(), 'Comment is required.');
        }
        
        extension.commentBody = 'Test Comment';
        extension.Save();
    }

    static testmethod void KnowIssueClosedTest(){

        ProductEventMap__c testEventMap = new ProductEventMap__c();
        testEventMap.HasClusters__c = true;
        testEventMap.Name = 'Test Product';
        testEventMap.ImplementedProduct__c = 'Test Product';
        testEventMap.Product__c = 'Test Product';
        testEventMap.Platform__c = 'Cluster - inContact';
        insert testEventMap;

        Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SobjectType.Case.getRecordTypeInfosByName();

        // known issue
        Case knownIssue = new Case(
                //AccountId = testAccount.Id,
                RecordTypeId = recordTypeMap.get('Known Issue').getRecordTypeId(),
                Type = 'Known Issue',
                Status = 'New',
                KB_Attached__c = false,
                Subject = 'KnowIssueClosedTest',
                Description = 'KnowIssueClosedTest',
                Origin = 'Email',
                ProductImpacted__c = 'Test Product',
                PlatformsImpacted__c = 'C1 - inContact'

        );

        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        knownIssue.setOptions(dmo);

        insert knownIssue;

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'KnowIssueClosedTest Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                IsPartner__c = false,
                CustomerSegment__c = 'Strategic',
                GYRStatus__c = 'Green',
                inContact_Cluster__c = 'C7'
        );

        insert testAccount;

        Case incident = new Case(
                AccountId = testAccount.Id,
                RecordTypeId = recordTypeMap.get('Incident').getRecordTypeId(),
                Type = 'Incident',
                Status = 'New',
                KB_Attached__c = false,
                Subject = 'KnowIssueClosedTest',
                Description = 'KnowIssueClosedTest',
                Origin = 'Web',
                Priority = 'P3'
        );
        incident.setOptions(dmo);
        insert incident;

        test.startTest();

        // attach to KI
        incident.KnownIssue__c = knownIssue.Id;
        update incident;

        test.stopTest();

        Case ki = [Select PlatformsImpacted__c from Case where Id = :knownIssue.Id ];
        system.assert(ki.PlatformsImpacted__c.containsIgnoreCase('C7 - inContact'), ki.PlatformsImpacted__c);


        // close KI
        knownIssue.Status = 'Closed';
        update knownIssue;

    }

}