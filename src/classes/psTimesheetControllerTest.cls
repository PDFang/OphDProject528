@IsTest
public class psTimesheetControllerTest {

    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String ACCOUNT_TYPE_PARTNERS = 'Partners';
    static final String CONTACT_TYPE_PARTNER = 'Partner Contact';
    static final String ACCOUNT_PARTNER_TYPE_ACCOUNT = 'Partner Account';
    static final String ACCOUNT_PARTNER_TYPE_GROUP = 'Public Group';
    static final String PROJECT_TYPE_PARENT_SAAS = 'PS Parent Project - SaaS';
    static final String PROJECT_TYPE_PHASE_PREMISE = 'PS Project Phase Premise WFO';
    static final String PROJECT_TYPE_PARENT_PREMISE = 'PS Parent Project - Premise';
    static final String OPPORTUNITY_TYPE_NEW = 'New Opportunity';
    static final String CASE_TYPE_INCIDENT = 'Incident';
    static final String CASE_TYPE_EVENT = 'Event';

    static final Set<String> recordTypeSet = new Set<String>
    {
            ACCOUNT_TYPE_CUSTOMERS,
            ACCOUNT_TYPE_PARTNERS,
            CONTACT_TYPE_PARTNER,
            ACCOUNT_PARTNER_TYPE_ACCOUNT,
            ACCOUNT_PARTNER_TYPE_GROUP,
            OPPORTUNITY_TYPE_NEW,
            PROJECT_TYPE_PARENT_SAAS,
            PROJECT_TYPE_PARENT_PREMISE,
            PROJECT_TYPE_PHASE_PREMISE,
            CASE_TYPE_EVENT
    };

    static Map<String, Id> recordTypeMap 				= null;
    static List<User> userList 							= null;
    static List<Account> accountList 					= null;
    static List<Opportunity> oppList 					= null;
    static List<Project__c> projList 					= null;
    static List<Case> caseList 		 					= null;
    static List<Issues__c> riskList  					= null;
    static List<Asset> assetList	 					= null;
    static List<WorkIt2__Timing__c> timingList		  	= null;
    static List<WorkIt2__Time_Entry__c> timeEntryList 	= null;
    static List<Project_Asset_Allocation__c> allList  	= null;
    static List<WorkIt2__Session_Type__c> sessionList 	= null;

    @TestSetup
    static void createTestData(){

        recordTypeMap = new Map<String, Id>();
        for(RecordType record : [
                Select Id, Name from RecordType
                where Name IN :recordTypeSet
        ])
        {
            recordTypeMap.put(record.Name, record.Id);
        }

        createUsers();
        //updateUserTitle();
        createAccounts();
        createOpportunities();
        createProjects();
        //createCases();
        createRisks();
        createAssets();
        createAllocations();
        createTimings();
        createTimeEntries();
        createSessionTypes();

    } // end of createTestData()

    static void createUsers() {

        userList = new List<User>();
        Profile profile = [SELECT Id from Profile where Name = 'Implementation Management'];

        userList.add(
                new User(
                        FirstName = 'ES',
                        LastName = 'User1',
                        Email = 'user1@incontact.com',
                    	Team__c = 'Expert Services',
                        Username = 'esuser1@incontact.com',
                        Alias = 'test',
                    	CommunityNickname = 'test',
                        profileId = profile.Id,
                        EmailEncodingKey = 'UTF-8',
                        TimeZoneSidKey = 'America/Los_Angeles',
                        LocaleSidKey = 'en_US',
                        LanguageLocaleKey = 'en_US'
                )
        );
        // avoid mixed dml operation
        system.runAs( new user( Id = UserInfo.getUserID() ) ) {
            insert userList;
        }
    } // end of createUsers
    static void updateUserTitle(){
        String uId = UserInfo.getUserId();
        User userToUpdate = [Select Id From User where Id = :uId limit 1];
        userToUpdate.Title = 'Project Manager';
        update userToUpdate;
    }
    static void createAccounts() {

        accountList = new List<Account>();
        accountList.add(
                new Account(
                        Name = 'ProjectTriggerHandlerTest Customer 1',
                    	TsaSecondary__c = UserInfo.getUserID(),
                        Type = 'Customer',
                    	Active__c = true, 
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS)
                )
        );
        insert accountList;
    } // end of createAccounts
    static void createOpportunities(){

        oppList = new List<Opportunity>();
        oppList.add(
                new Opportunity(
                        Name = 'ProjectTriggerHandlerTest Opp 1',
                        AccountId = accountList[0].Id,
                        RecordTypeId = recordTypeMap.get(OPPORTUNITY_TYPE_NEW),
                        StageName = 'Prospecting',
                        CloseDate = Date.today(),
                        Probability = 25,
                        Partner_Deal__c = 'NO',
                        Contract_Type__c = 'New Customer',
                        inContact__c = 'YES',
                        inContact_Setup_Fee__c = 1000,
                        inContact_Seats__c = 1,
                        inContact_MRC_Min__c = 1000,
                        inContact_Ports__c = 1,
                        inContact_MRC_Exp__c = 1000,
                        ECHO__c = 'NO',
                        eLearning__c = 'NO',
                        Hiring__c = 'NO',
                        WFM__c = 'NO'
                )
        );
        insert oppList;
    } // end of createOpportunities()
    static void createProjects() {

        String uId = UserInfo.getUserId();
        projList = new List<Project__c>();
        projList.add(
            new Project__c(
                TotalWorkLogHours__c = 40,
                ES_AssetCount__c = 4,
                ES_ProjectComplexity__c = 10,
                ES_Project_Color__c = 'ffffff',
                EstimatedProjectGoLiveDate__c = Date.today(),
                Account__c = accountList[0].Id,
                Opportunity__c = oppList[0].Id,
                OwnerId = uId,
                ImplementationConsultant__c = uId,
                Summary__c = 'Test Project 1',
                ES_PrevQ_PercentComplete__c = 40,
                PercentComplete__c = 40,
                RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_PREMISE),
                Phase_Status__c = 'Align',
                ProjectStatus__c = 'Align',
                Team__c = 'Expert Services',
                Status__c = '0 - PreSale'
            )
        );
        projList.add(           
            new Project__c(
                TotalWorkLogHours__c = 40,
                ES_AssetCount__c = 4,
                ES_ProjectComplexity__c = 10,
                ES_Project_Color__c = 'ffffff',
                EstimatedProjectGoLiveDate__c = Date.today(),
                Account__c = accountList[0].Id,
                Opportunity__c = oppList[0].Id,
                OwnerId = uId,
                Summary__c = 'Test Project 2',
                ES_PrevQ_PercentComplete__c = 40,
                PercentComplete__c = 40,
                RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_PREMISE),
                Phase_Status__c = 'Align',
                ProjectStatus__c = 'Align',
                Team__c = 'Expert Services'
            )
        );
        projList.add(           
            new Project__c(
                TotalWorkLogHours__c = 40,
                ES_AssetCount__c = 4,
                ES_ProjectComplexity__c = 10,
                ES_Project_Color__c = 'ffffff',
                EstimatedProjectGoLiveDate__c = Date.today(),
                Account__c = accountList[0].Id,
                Opportunity__c = oppList[0].Id,
                OwnerId = uId,
                Summary__c = 'Test Project 3',
                ES_PrevQ_PercentComplete__c = 40,
                PercentComplete__c = 40,
                RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_PREMISE),
                Phase_Status__c = 'Align',
                ProjectStatus__c = 'Align',
                Team__c = 'Expert Services'
            )
        );   
        insert projList;
    } // end of createProjects()
    static void createCases(){
        
        //set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        
        String uId = UserInfo.getUserId();
        caseList = new List<Case>();
        caseList.add(
                new Case(
                    Assigned_To__c = uId,
                    Subject = 'TriggerHandlerTest Case 1',
                    AccountId = accountList[0].Id
                )
        );
        caseList[0].setOptions(dmo);
        insert caseList;
    } // end of createCases()
    static void createRisks(){
        
        String uId = UserInfo.getUserId();
        riskList = new List<Issues__c>();
        riskList.add(
                new Issues__c(
                    Owner__c = uId,
                    Account__c = accountList[0].Id
                )
        );
        insert riskList;
    } // end of createRisks()
    static void createAssets(){
        assetList = new List<Asset>();
        assetList.add(
                new Asset(
                    	Name	 		  = 'inContact Call Recording (per concurrent user)',
                    	AccountId		  = accountList[0].Id
                )
        );
        insert assetList;
    } // end of createAssets()
    static void createAllocations(){
        allList = new List<Project_Asset_Allocation__c>();
        String uId = UserInfo.getUserId();
        allList.add(
                new Project_Asset_Allocation__c(
                    	Project__c 		  = projList[1].Id,
                    	Assigned_User__c  = uId,
                    	Asset__c		  = assetList[0].Id
                )
        );
        allList.add(
                new Project_Asset_Allocation__c(
                    	Project__c 		  = projList[2].Id,
                    	Assigned_User__c  = uId,
                    	Asset__c		  = assetList[0].Id
                )
        );
        insert allList;
    } // end of createAllocations()
    static void createTimings(){

        String uId = UserInfo.getUserId();
        timingList = new List<WorkIt2__Timing__c>();
        timingList.add(
                new WorkIt2__Timing__c(
                    ownerId    = userList[0].Id,
                    Project_Asset_Allocation__c = allList[0].Id
                )
        );
        timingList.add(
                new WorkIt2__Timing__c(
                    ownerId    = uId,
                    Project_Asset_Allocation__c = allList[1].Id
                )
        );
        insert timingList;
    } // end of createTimings()
    static void createTimeEntries(){
        
        Integer yr  = System.Today().year();
        Integer mo  = System.Today().month();
        Integer dy  = System.Today().day();
        DateTime beginTime = DateTime.newInstance(yr, mo, dy, 00, 00, 00);
        DateTime endTime   = beginTime.addMinutes(2);

        timeEntryList = new List<WorkIt2__Time_Entry__c>();
        timeEntryList.add(
                new WorkIt2__Time_Entry__c(
                    WorkIt2__Timing__c    = timingList[0].Id,
                    WorkIt2__Start__c     = beginTime,
                    WorkIt2__Heartbeat__c = endTime
                )
        );
        timeEntryList.add(
                new WorkIt2__Time_Entry__c(
                    WorkIt2__Timing__c    = timingList[1].Id,
                    WorkIt2__Start__c     = beginTime,
                    WorkIt2__Heartbeat__c = endTime
                )
        );
        insert timeEntryList;
    } // end of createTimeEntries()
    static void createSessionTypes(){

        sessionList = new List<WorkIt2__Session_Type__c>();
        sessionList.add(
                new WorkIt2__Session_Type__c(
					Name = 'Travel'
                )
        );
        insert sessionList;
    } // end of createSessionTypes()

    static testMethod void OwnershipTest1(){
        Test.startTest();

        PageReference myVfPage = Page.psTimesheet;
        Test.setCurrentPage(myVfPage);
        psTimesheetController testController = new psTimesheetController();

        // Run Object Ownership methods
        String paResults = psTimesheetController.getPhaseAllocationsMethod();
        
        // Test Results
        System.Assert(paResults.length() > 2); // Test getPhaseAllocationsMethod

        
        // Get records
        String projId = [Select Id from Project__c Where Summary__c = 'Test Project 2' limit 1].Id;
        String alloId = [Select Id from Project_Asset_Allocation__c Where Project__c = :projId limit 1].Id;

        // Assertions
        System.Assert(paResults.indexOf(alloId) != -1);
        System.Assert(paResults.indexOf(projId) != -1);

        Test.stopTest();
    }
    static testMethod void OwnershipTest2(){
        Test.startTest();

        PageReference myVfPage = Page.psTimesheet;
        Test.setCurrentPage(myVfPage);
        psTimesheetController testController = new psTimesheetController();

        // Run Object Ownership methods
        String prResults = psTimesheetController.getPreSalesMethod();
        
        // Test Results
        System.Assert(prResults.length() > 2); // Test getPreSalesMethod
        
        // Get records
        String presaleId = [Select Id from Project__c Where Summary__c = 'Test Project 1' limit 1].Id;
        
        // Assertions
        System.Assert(prResults.indexOf(presaleId) != -1);

        Test.stopTest();
    }
    static testMethod void OwnershipTest3(){
        Test.startTest();

        PageReference myVfPage = Page.psTimesheet;
        Test.setCurrentPage(myVfPage);
        psTimesheetController testController = new psTimesheetController();
        
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        
        String uId = UserInfo.getUserId();
        String accountId = [Select Id from Account Where Name = 'ProjectTriggerHandlerTest Customer 1' limit 1].Id;
        caseList = new List<Case>();
        caseList.add(
                new Case(
                    Assigned_To__c = uId,
                    Subject = 'TriggerHandlerTest Case 1',
                    AccountId = accountId
                )
        );
        caseList[0].setOptions(dmo);
        insert caseList;

        // Run Object Ownership methods
        String caResults = psTimesheetController.getCasesMethod();
        
        // Test Results
        System.Assert(caResults.length() > 2); // Test getCasesMethod
        
        // Get records
        String caseId = [Select Id from Case Where Subject = 'TriggerHandlerTest Case 1' limit 1].Id;
        
        // Assertions
        System.Assert(caResults.indexOf(caseId) != -1);

        Test.stopTest();
    }
    static testMethod void OwnershipTest4(){
        Test.startTest();

        PageReference myVfPage = Page.psTimesheet;
        Test.setCurrentPage(myVfPage);
        psTimesheetController testController = new psTimesheetController();

        // Run Object Ownership methods
        String riResults = psTimesheetController.getRisksMethod();
        
        // Test Results
        System.Assert(riResults.length() > 2); // Test getRisksMethod
        
        // Get records
        String riskId = [Select Id from Issues__c limit 1].Id;
        
        // Assertions
        System.Assert(riResults.indexOf(riskId) != -1);

        Test.stopTest();
    }
    static testMethod void OwnershipTest5(){
        Test.startTest();

        PageReference myVfPage = Page.psTimesheet;
        Test.setCurrentPage(myVfPage);
        psTimesheetController testController = new psTimesheetController();

        // Run Object Ownership methods
        String acResults = psTimesheetController.getTamAccountsMethod();
        
        // Test Results
        System.Assert(acResults.length() > 2); // Test getTamAccountsMethod
        
        // Get records
        String accountId = [Select Id from Account Where Name = 'ProjectTriggerHandlerTest Customer 1' limit 1].Id;
        
        // Assertions
        System.Assert(acResults.indexOf(accountId) != -1);

        Test.stopTest();
    }
    
    static testMethod void newRecordsTest1(){
        Test.startTest();
        
        // Get Project data
        List<Project__c> tempList = [Select Id, Name From Project__c Where Summary__c = 'Test Project 2' limit 1]; 
        Project__c tempRecord = tempList.get(0);
        String projId   = tempRecord.Id;
        String projName = tempRecord.Name;
        
        // Run getNewRecordsMethod using various scenarios
        String pr2Results = psTimesheetController.getNewRecordsMethod(projName,'Project');

        // Test Results
        System.Assert(pr2Results.length() > 2); // Test using a Project
        System.Assert(pr2Results.indexOf(projId)   != -1);
        System.Assert(pr2Results.indexOf(projName) != -1);
        
        // Run getAssetAllocations
        List<Project_Asset_Allocation__c> tempList2 = [Select Id, Name From Project_Asset_Allocation__c Where Project__c = :projId limit 1]; 
        Project_Asset_Allocation__c tempRecord2 = tempList2.get(0);
        String alloId   = tempRecord2.Id;
        String alloName = tempRecord2.Name;
        String allResults = psTimesheetController.getAssetAllocations(projId);
        System.Debug('allResults: ' + allResults);
        System.Assert(allResults.length() > 2);
        System.Assert(allResults.indexOf(projId)   != -1);
        System.Assert(allResults.indexOf(alloId)   != -1);
        System.Assert(allResults.indexOf(alloName) != -1);
        
        Test.stopTest();
    }
    static testMethod void newRecordsTest2(){
        Test.startTest();
        
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        
        String uId = UserInfo.getUserId();
        String accountId = [Select Id from Account Where Name = 'ProjectTriggerHandlerTest Customer 1' limit 1].Id;
        caseList = new List<Case>();
        caseList.add(
                new Case(
                    Assigned_To__c = uId,
                    Subject = 'TriggerHandlerTest Case 1',
                    AccountId = accountId
                )
        );
        caseList[0].setOptions(dmo);
        insert caseList;
        
        // Get Case data
        List<Case> tempList = [Select Id, CaseNumber From Case Where Subject = 'TriggerHandlerTest Case 1' limit 1]; 
        Case tempCase = tempList.get(0);
        String caseId   = tempCase.Id;
        String caseName = tempCase.CaseNumber;
        
        // Run getNewRecordsMethod using various scenarios
        String caseResults = psTimesheetController.getNewRecordsMethod(caseName,'Case');

        // Test Results
        System.Assert(caseResults.length() > 2); // Test using a Case
        System.Assert(caseResults.indexOf(caseId)   != -1);
        System.Assert(caseResults.indexOf(caseName) != -1);

        Test.stopTest();
    }
    static testMethod void newRecordsTest3(){
        Test.startTest();
        
        // Get Project and Case names
        List<Account> tempList = [Select Id, Name From Account Where Name = 'ProjectTriggerHandlerTest Customer 1' limit 1]; 
        Account tempAccount = tempList.get(0);
        String accId   = tempAccount.Id;
        String accName = tempAccount.Name;

        List<Issues__c> tempList2 = [Select Id, Name From Issues__c Where Account__c = :accId limit 1]; 
        Issues__c tempRisk = tempList2.get(0);
        String riskId   = tempAccount.Id;
        String riskName = tempAccount.Name;
        
        // Run getNewRecordsMethod using various scenarios
        String ri2Results = psTimesheetController.getNewRecordsMethod('Project','Risk');
        String ac2Results = psTimesheetController.getNewRecordsMethod('Project','Account');
        
        // Log Results
        System.debug('ri2Results: ' + ri2Results);
        System.debug('ac2Results: ' + ac2Results);
        
        // Test Results
        System.Assert(ri2Results.length() > 2); // Test using a Risk (Issues__c)
        System.Assert(ac2Results.length() > 2); // Test using an Account
        System.Assert(ri2Results.indexOf(riskId)   != -1);
        System.Assert(ri2Results.indexOf(riskName) != -1);
        System.Assert(ac2Results.indexOf(accId)    != -1);
        System.Assert(ac2Results.indexOf(accName)  != -1);
        
        Test.stopTest();
    }
    
    static testMethod void queryTimesheetsTest(){
        Test.startTest();
        
        String uId    = UserInfo.getUserId();
        String tsId   = [Select Id From WorkIt2__Timing__c Where ownerId = :uId limit 1].Id;
        String alloId = [Select Project_Asset_Allocation__c From WorkIt2__Timing__c Where Id = :tsId limit 1].Project_Asset_Allocation__c;
        String tsEId  = [Select Id From WorkIt2__Time_Entry__c Where WorkIt2__Timing__c = :tsId limit 1].Id;
        
		Integer currentYear  = System.Today().year();
        Integer currentMonth = System.Today().month();
        Integer currentDay   = System.Today().day();

        String tsResults = psTimesheetController.queryTimesheets(currentYear, currentMonth, currentDay);
        System.debug('tsResults: ' + tsResults);
        System.Assert(tsResults != null);
        System.Assert(tsResults.indexOf(tsEId)  != -1);
        System.Assert(tsResults.indexOf(tsId)   != -1);
        System.Assert(tsResults.indexOf(alloId) != -1);
        
        Test.stopTest();
    }
    
    static testMethod void submitTest1(){
        Test.startTest();
        
        // Set Test Data
        String accountId 	= [Select Id From Account limit 1].Id;
        Date today			= System.Today();
        Date yesterday		= today.addDays(-1);
        Integer yr  		= yesterday.year();
        Integer mo  		= yesterday.month();
        Integer dy          = yesterday.day();
        String dispo 		= 'Travel';
        
        // Run submitTime method for multiple scenarios
        String submitResults5 = psTimesheetController.submitTime('account', accountId, accountId, dispo, 13, yr, mo, dy, 05, 00, 00, 0, 'comment');
        
        // Pull back entered times
        List<WorkIt2__Time_Entry__c> resultList5 = [Select Id, WorkIt2__Time_In_Minutes__c from WorkIt2__Time_Entry__c Where WorkIt2__Timing__r.Account__c = :accountId AND WorkIt2__Session_Type__r.Name = :dispo limit 1];
        
        // Test Results
        System.Assert(submitResults5 != null); // Test using an Account
        System.Assert(resultList5[0].WorkIt2__Time_In_Minutes__c  == 13);
    
        Test.stopTest();
    }
    static testMethod void submitTest2(){
        Test.startTest();
        
        // Set Test Data
        String accountId 	= [Select Id From Account limit 1].Id;
        String alloId 		= [Select Id From Project_Asset_Allocation__c limit 1].Id;
        Date today			= System.Today();
        Date yesterday		= today.addDays(-1);
        Integer yr  		= yesterday.year();
        Integer mo  		= yesterday.month();
        Integer dy          = yesterday.day();
        String dispo 		= 'Travel';
        
        // Run submitTime method for multiple scenarios
        String submitResults1 = psTimesheetController.submitTime('project', alloId, accountId, dispo, 5, yr, mo, dy, 01, 00, 00, 0, 'comment');
        
        // Pull back entered times
        List<WorkIt2__Time_Entry__c> resultList1 = [Select Id, WorkIt2__Time_In_Minutes__c from WorkIt2__Time_Entry__c Where WorkIt2__Timing__r.Project_Asset_Allocation__c = :alloId AND WorkIt2__Session_Type__r.Name = :dispo limit 1];
        
        // Test Results
        System.Assert(submitResults1 != null); // Test using an Allocation
        System.Assert(resultList1[0].WorkIt2__Time_In_Minutes__c  == 5);
    
        Test.stopTest();
    }
    static testMethod void submitTest3(){
        Test.startTest();
        
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        
        String uId = UserInfo.getUserId();
        String accountId = [Select Id from Account Where Name = 'ProjectTriggerHandlerTest Customer 1' limit 1].Id;
        caseList = new List<Case>();
        caseList.add(
                new Case(
                    Assigned_To__c = uId,
                    Subject = 'TriggerHandlerTest Case 1',
                    AccountId = accountId
                )
        );
        caseList[0].setOptions(dmo);
        insert caseList;
        
        // Set Test Data
        String caseId 		= [Select Id From Case Where Subject = 'TriggerHandlerTest Case 1' limit 1].Id;
        Date today			= System.Today();
        Date yesterday		= today.addDays(-1);
        Integer yr  		= yesterday.year();
        Integer mo  		= yesterday.month();
        Integer dy          = yesterday.day();
        String dispo 		= 'Travel';
        
        // Run submitTime method for multiple scenarios
        String submitResults2 = psTimesheetController.submitTime('case', caseId, accountId, dispo, 7, yr, mo, dy, 02, 00, 00, 0, 'comment');
        
        // Pull back entered times
        List<WorkIt2__Time_Entry__c> resultList2 = [Select Id, WorkIt2__Time_In_Minutes__c from WorkIt2__Time_Entry__c Where WorkIt2__Timing__r.WorkIt2__Case__c = :caseId AND WorkIt2__Session_Type__r.Name = :dispo limit 1];
        
        // Test Results
        System.Assert(submitResults2 != null); // Test using a Case
        System.Assert(resultList2[0].WorkIt2__Time_In_Minutes__c  == 7);

        Test.stopTest();
    }
    static testMethod void submitTest4(){
        Test.startTest();
        
        // Set Test Data
        String accountId 	= [Select Id From Account limit 1].Id;
        String projId 		= [Select Id From Project__c Where Summary__c = 'Test Project 2' limit 1].Id;
        Date today			= System.Today();
        Date yesterday		= today.addDays(-1);
        Integer yr  		= yesterday.year();
        Integer mo  		= yesterday.month();
        Integer dy          = yesterday.day();
        String dispo 		= 'Travel';
        
        // Run submitTime method for multiple scenarios
        String submitResults3 = psTimesheetController.submitTime('presale', projId, accountId, dispo, 9, yr, mo, dy, 03, 00, 00, 0, 'comment');
        
        // Pull back entered times
        List<WorkIt2__Time_Entry__c> resultList3 = [Select Id, WorkIt2__Time_In_Minutes__c from WorkIt2__Time_Entry__c Where WorkIt2__Timing__r.Project__c = :projId AND WorkIt2__Session_Type__r.Name = :dispo limit 1];
        
        // Test Results
        System.Assert(submitResults3 != null); // Test using a Pre-Sale Project
        System.Assert(resultList3[0].WorkIt2__Time_In_Minutes__c  == 9);

        Test.stopTest();
    }
    static testMethod void submitTest5(){
        Test.startTest();
        
        // Set Test Data
        String accountId 	= [Select Id From Account limit 1].Id;
        String riskId 		= [Select Id From Issues__c limit 1].Id;
        Date today			= System.Today();
        Date yesterday		= today.addDays(-1);
        Integer yr  		= yesterday.year();
        Integer mo  		= yesterday.month();
        Integer dy          = yesterday.day();
        String dispo 		= 'Travel';
        
        // Run submitTime method for multiple scenarios
        String submitResults4 = psTimesheetController.submitTime('risk', riskId, accountId, dispo, 11, yr, mo, dy, 04, 00, 00, 0, 'comment');
        
        // Pull back entered times
        List<WorkIt2__Time_Entry__c> resultList4 = [Select Id, WorkIt2__Time_In_Minutes__c from WorkIt2__Time_Entry__c Where WorkIt2__Timing__r.Risk_Escalation__c = :riskId AND WorkIt2__Session_Type__r.Name = :dispo limit 1];
        
        // Test Results

        System.Assert(submitResults4 != null); // Test using a Risk (Issues__c)
        System.Assert(resultList4[0].WorkIt2__Time_In_Minutes__c  == 11);

        Test.stopTest();
    }
    
    static testMethod void attachTest1(){
        Test.startTest();
        
        // Set Test Data
        String accountId 	= [Select Id From Account limit 1].Id;
        
        // Run submitTime method for multiple scenarios
        String attachResults1 = psTimesheetController.uploadNoteMethod('Note Title','Test note',accountId);
        
        // Pull back entered times
        List<note> attachList1 		 = [Select Id, title, body from Note Where ParentId = :accountId limit 1];

        // Test Results
        System.Assert(attachResults1 != null);
        System.Assert(attachList1[0].title == 'Note Title');
        System.Assert(attachList1[0].body  == 'Test note');

        Test.stopTest();
    }
    static testMethod void attachTest2(){
        Test.startTest();
        
        // Set Test Data
        String accountId 	= [Select Id From Account limit 1].Id;
        
        // Run submitTime method for multiple scenarios
        String attachResults2 = psTimesheetController.uploadFileMethod('testDoc.txt','text/plain','VGhpcyBpcyBhIHRleHQgZG9jLg==',accountId);
        
        // Pull back entered times
        List<Attachment> attachList2 = [Select Id, Name, Body from Attachment Where ParentId = :accountId limit 1];

        // Test Results
        System.Assert(attachResults2 != null);
        System.Assert(attachList2[0].Name  == 'testDoc.txt');
        System.Assert(attachList2[0].Body  == EncodingUtil.base64Decode('VGhpcyBpcyBhIHRleHQgZG9jLg=='));

        Test.stopTest();
    }
    static testMethod void attachTest3(){
        Test.startTest();
        
        // Set Test Data
        String accountId 	= [Select Id From Account limit 1].Id;
        String parentId		= [Select Id From Project__c Where Summary__c = 'Test Project 2' Limit 1].Id;
        System.debug(parentId);
        
        // Set Parent Project
        Project__c projUpdate = [Select Id From Project__c where Summary__c = 'Test Project 3' limit 1];
        String projectId = projUpdate.Id;
        projUpdate.ParentProject__c = parentId;
        update projUpdate;
        
        // Run submitTime method for multiple scenarios
        String attachResults3 = psTimesheetController.uploadNoteMethod('Note Title','Test note',projectId);
        
        // Pull back entered times
        List<note> attachList3 		 = [Select Id, title, body from Note Where ParentId = :parentId limit 1];

        // Test Results
        System.Assert(attachList3[0].title == 'Note Title');
        System.Assert(attachList3[0].body  == 'Test note');

        Test.stopTest();
    }
    static testMethod void attachTest4(){
        Test.startTest();
        
        // Set Test Data
        String accountId 	= [Select Id From Account limit 1].Id;
        String parentId		= [Select Id From Project__c Where Summary__c = 'Test Project 2' Limit 1].Id;
        
        // Set Parent Project
        Project__c projUpdate = [Select Id From Project__c where Summary__c = 'Test Project 3' limit 1];
        String projectId = projUpdate.Id;
        projUpdate.ParentProject__c = parentId;
        update projUpdate;
        
        // Run submitTime method for multiple scenarios
        String attachResults4 = psTimesheetController.uploadFileMethod('testDoc.txt','text/plain','VGhpcyBpcyBhIHRleHQgZG9jLg==',projectId);
        
        // Pull back entered times
        List<Attachment> attachList4 = [Select Id, Name, Body from Attachment Where ParentId = :parentId limit 1];

        // Test Results
        System.Assert(attachResults4 != null);
        System.Assert(attachList4[0].Name  == 'testDoc.txt');
        System.Assert(attachList4[0].Body  == EncodingUtil.base64Decode('VGhpcyBpcyBhIHRleHQgZG9jLg=='));

        Test.stopTest();
    }
    
    static testMethod void deleteTest(){
        Test.startTest();
        
        String uId = UserInfo.getUserId();
        
        String timingId = [Select Id From WorkIt2__Timing__c Where ownerId = :uId Limit 1].Id;
        String entryId 	= [Select Id From WorkIt2__Time_Entry__c Where WorkIt2__Timing__c = :timingId limit 1].Id;
        
        String deleteResult = psTimesheetController.deleteEntryMethod(entryId);
        
        List<WorkIt2__Time_Entry__c> entryList = [Select Id from WorkIt2__Time_Entry__c Where WorkIt2__Timing__c = :timingId];
        System.Assert(entryList.size() < 1);
        
        Test.stopTest();
    }
}