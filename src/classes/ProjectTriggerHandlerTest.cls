@IsTest
private class ProjectTriggerHandlerTest {

    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String ACCOUNT_TYPE_PARTNERS = 'Partners';
    static final String CONTACT_TYPE_PARTNER = 'Partner Contact';
    static final String ACCOUNT_PARTNER_TYPE_ACCOUNT = 'Partner Account';
    static final String ACCOUNT_PARTNER_TYPE_GROUP = 'Public Group';
    static final String PROJECT_TYPE_PHASE_SAAS = 'PS Project Phase SaaS';
    static final String PROJECT_TYPE_PARENT_SAAS = 'PS Parent Project - SaaS';
    static final String PROJECT_TYPE_PHASE_PREMISE = 'PS Project Phase Premise WFO';
    static final String PROJECT_TYPE_PARENT_PREMISE = 'PS Parent Project - Premise';
    static final String OPPORTUNITY_TYPE_NEW = 'New Opportunity';
    static final String OPPORTUNITY_TYPE_PM_STANDARD = 'PM-Standard';
    static final String PROJECT_TYPE_CONNECTIVITY_DESIGN = 'Connectivity Design';
    static final String PROJECT_TYPE_DEDICATED_PROVISIONING = 'Dedicated Provisioning';

    static final Set<String> recordTypeSet = new Set<String>
    {
            ACCOUNT_TYPE_CUSTOMERS,
            ACCOUNT_TYPE_PARTNERS,
            CONTACT_TYPE_PARTNER,
            ACCOUNT_PARTNER_TYPE_ACCOUNT,
            ACCOUNT_PARTNER_TYPE_GROUP,
            OPPORTUNITY_TYPE_NEW,
            OPPORTUNITY_TYPE_PM_STANDARD,
            PROJECT_TYPE_PHASE_SAAS,
            PROJECT_TYPE_PARENT_SAAS,
            PROJECT_TYPE_PARENT_PREMISE,
            PROJECT_TYPE_PHASE_PREMISE,
            PROJECT_TYPE_CONNECTIVITY_DESIGN,
            PROJECT_TYPE_DEDICATED_PROVISIONING
    };

    static Map<String, Id> recordTypeMap = null;
    static List<Account> accountList = null;
    static List<Contact> contactList = null;
    static List<Opportunity> oppList = null;
    static List<User> userList = null;

    /* Add a phase project and verify the "Go Live Date" for insertion */
    static testMethod void ProjectedGoLiveDateInsertTest() {

        createTestData();
        string phaseProjectSummary = 'GoLiveDateInsertTest Project';
        Date phaseProjectGoLiveDate = Date.today();

        Project__c parentProject = new Project__c();
        parentProject.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_SAAS);
        parentProject.Opportunity__c = oppList[0].Id;
        parentProject.Account__c = accountList[0].Id;
        parentProject.Projected_Deadline__c = system.today().addDays(7);
        insert parentProject;

        test.startTest();
        List<Project__c> projectList = new List<Project__c>();
        Project__c phase1 = new Project__c();
        phase1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_SAAS);
        phase1.EstimatedProjectGoLiveDate__c = phaseProjectGoLiveDate;
        phase1.ActualProjectGoLiveDate__c = phaseProjectGoLiveDate;
        phase1.Summary__c = phaseProjectSummary;
        phase1.Opportunity__c = oppList[1].Id;
        phase1.Account__c = accountList[1].Id;
        phase1.Projected_Deadline__c = system.today().addMonths(1);
        phase1.ParentProject__c = parentProject.Id;
        projectList.add(phase1);
        insert projectList;
        test.stopTest();

        parentProject = [SELECT Id, Original_Forecasted_Initial_Go_Live_Date__c, Estimated_Project_Initial_Go_Live_Date__c, Estimated_Project_End__c, Times_All_Phases_Go_Live_Date_Changed__c, Actual_Initial_Phase_Go_Live__c, Actual_Latest_Go_Live_Date__c FROM Project__c WHERE Id = :parentProject.Id];
        Project__c[] phaseProjects = [SELECT Id, EstimatedProjectGoLiveDate__c, Original_Phase_Forecasted_Go_Live_Date__c, Times_Go_Live_Date_Changed__c, ActualProjectGoLiveDate__c FROM Project__c WHERE Summary__c = :phaseProjectSummary];

        system.assertEquals((Date)phaseProjects[0].get('Original_Phase_Forecasted_Go_Live_Date__c'), phaseProjectGoLiveDate);
        system.assertEquals(phaseProjects[0].get('Times_Go_Live_Date_Changed__c'), 0);

        system.assertEquals((Date)parentProject.get('Original_Forecasted_Initial_Go_Live_Date__c'), (Date)phaseProjects[0].get('Original_Phase_Forecasted_Go_Live_Date__c'));
        system.assertEquals((Date)parentProject.get('Estimated_Project_Initial_Go_Live_Date__c'), (Date)phaseProjects[0].get('EstimatedProjectGoLiveDate__c'));
        system.assertEquals((Date)parentProject.get('Estimated_Project_End__c'), (Date)phaseProjects[0].get('EstimatedProjectGoLiveDate__c'));
        system.assertEquals(parentProject.get('Times_All_Phases_Go_Live_Date_Changed__c'), phaseProjects[0].get('Times_Go_Live_Date_Changed__c'));

        system.assertEquals(parentProject.get('Actual_Initial_Phase_Go_Live__c'), phaseProjects[0].get('ActualProjectGoLiveDate__c'));
        system.assertEquals(parentProject.get('Actual_Latest_Go_Live_Date__c'), phaseProjects[0].get('ActualProjectGoLiveDate__c'));

    } // end of ProjectedGoLiveDateInsertTest()

    /* Add a phase project and verify the "Go Live Date" for updating */
    static testMethod void ProjectedGoLiveDateUpdateTest() {

        createTestData();
        string phaseProjectSummary = 'GoLiveDateInsertTest Project';
        Date phaseProjectGoLiveDate = Date.today();

        Project__c parentProject = new Project__c();
        parentProject.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_SAAS);
        parentProject.Opportunity__c = oppList[0].Id;
        parentProject.Account__c = accountList[0].Id;
        parentProject.Projected_Deadline__c = system.today().addDays(7);
        insert parentProject;

        List<Project__c> projectList = new List<Project__c>();
        Project__c phase1 = new Project__c();
        phase1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_SAAS);
        phase1.EstimatedProjectGoLiveDate__c = phaseProjectGoLiveDate = Date.today();
        phase1.Summary__c = phaseProjectSummary;
        phase1.Opportunity__c = oppList[1].Id;
        phase1.Account__c = accountList[1].Id;
        phase1.Projected_Deadline__c = system.today().addMonths(1);
        phase1.ParentProject__c = parentProject.Id;
        projectList.add(phase1);

        Project__c phase2 = new Project__c();
        phase2.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_SAAS);
        phase2.Summary__c = phaseProjectSummary;
        phase2.Opportunity__c = oppList[1].Id;
        phase2.Account__c = accountList[1].Id;
        phase2.Projected_Deadline__c = system.today().addMonths(1);
        phase2.ParentProject__c = parentProject.Id;
        projectList.add(phase2);
        insert projectList;

        test.startTest();
        phase1.EstimatedProjectGoLiveDate__c = phaseProjectGoLiveDate.addDays(1);
        phase2.EstimatedProjectGoLiveDate__c = phaseProjectGoLiveDate;
        update projectList;
        test.stopTest();

        Project__c[] phaseProjects = [SELECT Id, Original_Phase_Forecasted_Go_Live_Date__c, Times_Go_Live_Date_Changed__c FROM Project__c WHERE Summary__c = :phaseProjectSummary];
        system.assertEquals((Date)phaseProjects[0].get('Original_Phase_Forecasted_Go_Live_Date__c'), phaseProjectGoLiveDate);
        system.assertEquals(phaseProjects[0].get('Times_Go_Live_Date_Changed__c'), 1);

        system.assertEquals((Date)phaseProjects[1].get('Original_Phase_Forecasted_Go_Live_Date__c'), phaseProjectGoLiveDate);
        system.assertEquals(phaseProjects[1].get('Times_Go_Live_Date_Changed__c'), 0);

    } // end of ProjectedGoLiveDateUpdateTest()

     /* Add a phase project and verify the "projected deadline" on the parent project record is equal to most recent "projected deadline" on any project phase records */
    static testMethod void ProjectedDeadlineInsertTest() {

        createTestData();

        Project__c parentProject = new Project__c();
        parentProject.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_PREMISE);
        parentProject.Opportunity__c = oppList[0].Id;
        parentProject.Account__c = accountList[0].Id;
        parentProject.Projected_Deadline__c = system.today().addDays(7);
        insert parentProject;

        test.startTest();
        List<Project__c> projectList = new List<Project__c>();
        Project__c phase1 = new Project__c();
        phase1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_PREMISE);
        phase1.Opportunity__c = oppList[1].Id;
        phase1.Account__c = accountList[1].Id;
        phase1.Projected_Deadline__c = system.today().addMonths(1);
        phase1.ParentProject__c = parentProject.Id;
        projectList.add(phase1);

        Project__c phase2 = new Project__c();
        phase2.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_PREMISE);
        phase2.Opportunity__c = oppList[1].Id;
        phase2.Account__c = accountList[1].Id;
        phase2.Projected_Deadline__c = system.today().addYears(1);
        phase2.ParentProject__c = parentProject.Id;
        projectList.add(phase2);

        insert projectList;
        test.stopTest();

        parentProject = [SELECT Id, Projected_Deadline__c FROM Project__c WHERE Id = :parentProject.Id];
        AggregateResult[] aggregateList = [
                SELECT ParentProject__c, MAX(Projected_Deadline__c) maxDate FROM Project__c
                WHERE ParentProject__c = :parentProject.Id and Projected_Deadline__c != null
                GROUP BY ParentProject__c
        ];

        system.assertEquals((Date)aggregateList[0].get('maxDate'), parentProject.Projected_Deadline__c, 'Parent Projected Deadline is not equal to most recent project phase Projected Deadline.');

        // delete a phase project
        delete phase2;
        parentProject = [SELECT Id, Projected_Deadline__c FROM Project__c WHERE Id = :parentProject.Id];
        aggregateList = [
                SELECT ParentProject__c, MAX(Projected_Deadline__c) maxDate FROM Project__c
                WHERE ParentProject__c = :parentProject.Id and Projected_Deadline__c != null
                GROUP BY ParentProject__c
        ];
        system.assertEquals((Date)aggregateList[0].get('maxDate'), parentProject.Projected_Deadline__c, 'Parent Projected Deadline is not equal to most recent project phase Projected Deadline.');

    } // end of ProjectedDeadlineInsertTest()

    /* Update a phase project and verify the "projected deadline" on the parent project record is equal to most recent "projected deadline" on any project phase records */
    static testMethod void ProjectedDeadlineUpdateTest() {

        createTestData();

        Project__c parentProject = new Project__c();
        parentProject.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_PREMISE);
        parentProject.Opportunity__c = oppList[0].Id;
        parentProject.Account__c = accountList[0].Id;
        parentProject.Projected_Deadline__c = system.today().addDays(7);
        insert parentProject;

        Project__c phase1 = new Project__c();
        phase1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_PREMISE);
        phase1.Opportunity__c = oppList[1].Id;
        phase1.Account__c = accountList[1].Id;
        phase1.Projected_Deadline__c = system.today().addMonths(1);
        phase1.ParentProject__c = parentProject.Id;
        insert phase1;

        Project__c phase2 = new Project__c();
        phase2.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_CONNECTIVITY_DESIGN);
        phase2.Opportunity__c = oppList[1].Id;
        phase2.Account__c = accountList[1].Id;
        phase2.Projected_Deadline__c = system.today().addMonths(1);
        phase2.ParentProject__c = parentProject.Id;
        insert phase2;

        test.startTest();
        phase1.Projected_Deadline__c = system.today().addYears(1);
        update phase1;
        test.stopTest();

        parentProject = [SELECT Id, Projected_Deadline__c FROM Project__c WHERE Id = :parentProject.Id];
        AggregateResult[] aggregateList = [
                SELECT ParentProject__c, MAX(Projected_Deadline__c) maxDate FROM Project__c
                WHERE ParentProject__c = :parentProject.Id and Projected_Deadline__c != null
                GROUP BY ParentProject__c
        ];

        system.assertEquals((Date)aggregateList[0].get('maxDate'), parentProject.Projected_Deadline__c, 'Parent Projected Deadline is not equal to most recent project phase Projected Deadline.');

    } // end of ProjectedDeadlineUpdateTest()

    static testMethod void ProjectRollupSchedulableTest() {

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

        Set<String> projectRecordTypes = new Set<String>{
                'PS Parent Project - SaaS'
        };

        test.startTest();
        String scheduledJobId = system.schedule('testProjectRollupSchedulable', scheduledTime, new ProjectRollupSchedulable(5));
        String scheduledJobId2 = system.schedule('test2ProjectRollupSchedulable', scheduledTime, new ProjectRollupSchedulable(projectRecordTypes, 5));
        test.stopTest();

        CronTrigger job = [Select Id, State, NextFireTime, CronExpression From CronTrigger where Id = :scheduledJobId];
        CronTrigger job2 = [Select Id, State, NextFireTime, CronExpression From CronTrigger where Id = :scheduledJobId];
        system.assertEquals(scheduledTime, job.CronExpression);
        system.assertEquals(scheduledTime, job2.CronExpression);

    } // end of ProjectRollupSchedulableTest()

    static testMethod void OpportunityRollupSchedulableTest() {

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

        Set<String> projectRecordTypes = new Set<String>{
                'PM-Standard'
        };

        test.startTest();
        String scheduledJobId = system.schedule('testOpportunityRollupSchedulable', scheduledTime, new OpportunityRollupSchedulable(5));
        String scheduledJobId2 = system.schedule('test2OpportunityRollupSchedulable', scheduledTime, new OpportunityRollupSchedulable(projectRecordTypes, 5));
        test.stopTest();

        CronTrigger job = [Select Id, State, NextFireTime, CronExpression From CronTrigger where Id = :scheduledJobId];
        CronTrigger job2 = [Select Id, State, NextFireTime, CronExpression From CronTrigger where Id = :scheduledJobId];
        system.assertEquals(scheduledTime, job.CronExpression);
        system.assertEquals(scheduledTime, job2.CronExpression);
    } // end of OpportunityRollupSchedulableTest()

    // Add a new project and verify portal users and public group members are granted access
    static testMethod void insertProjectTest() {

        createTestData();

        test.startTest();

        List<Project__c> projectList = new List<Project__c>();
        Project__c project1 = new Project__c();
        project1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_SAAS);
        project1.Opportunity__c = oppList[0].Id;
        project1.Account__c = accountList[0].Id;
        projectList.add(project1);

        Project__c project2 = new Project__c();
        project2.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_PREMISE);
        project2.Opportunity__c = oppList[1].Id;
        project2.Account__c = accountList[1].Id;
        project2.ImplementationPartner__c = accountList[3].Id;
        projectList.add(project2);

        insert projectList;

        test.stopTest();

        // partner 1
        system.runAs(userList[0]){
            // SaaS project
            List<Project__c> saasProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_SAAS
                    and Id = :projectList[0].Id
            ];
            system.assertEquals(1, saasProjects.size());
            // Premise project
            List<Project__c> premiseProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_PREMISE
                    and Id = :projectList[1].Id
            ];
            system.assertEquals(0, premiseProjects.size());
        }
        // partner 2
        system.runAs(userList[1]){
            // SaaS project
            List<Project__c> saasProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_SAAS
                    and Id = :projectList[0].Id
            ];
            system.assertEquals(0, saasProjects.size());
            // Premise project
            List<Project__c> premiseProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_PREMISE
                    and Id = :projectList[1].Id
            ];
            system.assertEquals(1, premiseProjects.size());
        }
        // public group member
        system.runAs(userList[2]){
            // SaaS project
            List<Project__c> saasProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_SAAS
                    and Id = :projectList[0].Id
            ];
            system.assertEquals(1, saasProjects.size());
            // Premise project
            List<Project__c> premiseProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_PREMISE
                    and Id = :projectList[1].Id
            ];
            system.assertEquals(0, premiseProjects.size());
        }

    } // end of insertProjectTest()

    // Update the account on an existing project and verify portal users and public group members are granted or revoked access accordingly
    static testMethod void updateProjectTest() {

        createTestData();

        List<Project__c> projectList = new List<Project__c>();
        Project__c project1 = new Project__c();
        project1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_SAAS);
        project1.Opportunity__c = oppList[0].Id;
        project1.Account__c = accountList[0].Id;
        projectList.add(project1);

        Project__c project2 = new Project__c();
        project2.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_PREMISE);
        project2.Opportunity__c = oppList[1].Id;
        project2.Account__c = accountList[1].Id;
        project2.ImplementationPartner__c = accountList[3].Id;
        projectList.add(project2);

        insert projectList;

        test.startTest();

        // change customer account
        project1.Opportunity__c = oppList[1].Id;
        project1.Account__c = accountList[1].Id;
        // change implementation partner
        project2.ImplementationPartner__c = accountList[2].Id;
        update projectList;

        test.stopTest();

        // partner 1
        system.runAs(userList[0]){
            // SaaS project
            List<Project__c> saasProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_SAAS
                    and Id = :projectList[0].Id
            ];
            system.assertEquals(0, saasProjects.size());
            // Premise project
            List<Project__c> premiseProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_PREMISE
                    and Id = :projectList[1].Id
            ];
            system.assertEquals(1, premiseProjects.size());
        }
        // partner 2
        system.runAs(userList[1]){
            // SaaS project
            List<Project__c> saasProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_SAAS
                    and Id = :projectList[0].Id
            ];
            system.assertEquals(1, saasProjects.size());
            // Premise project
            List<Project__c> premiseProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_PREMISE
                    and Id = :projectList[1].Id
            ];
            system.assertEquals(0, premiseProjects.size());
        }
        // public group member
        system.runAs(userList[2]){
            // SaaS project
            List<Project__c> saasProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_SAAS
                    and Id = :projectList[0].Id
            ];
            system.assertEquals(0, saasProjects.size());
            // Premise project
            List<Project__c> premiseProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_PREMISE
                    and Id = :projectList[1].Id
            ];
            system.assertEquals(0, premiseProjects.size());
        }

    } // end of updateProjectTest()


    /* Create all the test data required to execute the tests successfully */
    static void createTestData(){

        recordTypeMap = new Map<String, Id>();
        for(RecordType record : [
                Select Id, Name from RecordType
                where Name IN :recordTypeSet
        ])
        {
            recordTypeMap.put(record.Name, record.Id);
        }

        createAccounts();
        createContacts();
        createOpportunities();
        CreatePortalUsers();
        CreatePublicGroup();
        createPartners();

    } // end of createTestData()

    static void createAccounts()
    {
        accountList = new List<Account>();
        accountList.add(
                new Account(
                        Name = 'ProjectTriggerHandlerTest Customer 1',
                        Type = 'Customer',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS)
                )
        );
        accountList.add(
                new Account(
                        Name = 'ProjectTriggerHandlerTest Customer 2',
                        Type = 'Customer',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS)
                )
        );
        accountList.add(
                new Account(
                        Name = 'ProjectTriggerHandlerTest Partner 1',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_PARTNERS)
                )
        );
        accountList.add(
                new Account(
                        Name = 'ProjectTriggerHandlerTest Partner 2',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_PARTNERS)
                )
        );
        accountList.add(
                new Account(
                        Name = 'ProjectTriggerHandlerTest Partner 3',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_PARTNERS)
                )
        );

        insert accountList;
    } // end of createAccounts()

    static void createPartners()
    {
        List<Account_Partner__c> partnerList = new List<Account_Partner__c>();

        partnerList.add(
                new Account_Partner__c(
                        Customer__c = accountList[0].Id,
                        Partner__c = accountList[2].Id,
                        RecordTypeId = recordTypeMap.get(ACCOUNT_PARTNER_TYPE_ACCOUNT),
                        Partner_Type__c = AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER
                )
        );
        partnerList.add(
                new Account_Partner__c(
                        Customer__c = accountList[1].Id,
                        Partner__c = accountList[3].Id,
                        RecordTypeId = recordTypeMap.get(ACCOUNT_PARTNER_TYPE_ACCOUNT),
                        Partner_Type__c = AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER
                )
        );
        partnerList.add(
                new Account_Partner__c(
                        Customer__c = accountList[0].Id,
                        Public_Group__c = 'Test Group',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_PARTNER_TYPE_GROUP),
                        Partner_Type__c = AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER
                )
        );
        insert partnerList;
    } // end of createPartners()

    static void createContacts() {

        contactList = new List<Contact>();
        contactList.add(
                new Contact(
                        LastName = 'ProjectTriggerHandlerTest Contact 1',
                        Email = 'contact1@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[0].Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'ProjectTriggerHandlerTest Contact 2',
                        Email = 'contact2@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[1].Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'ProjectTriggerHandlerTest Contact 3',
                        Email = 'contact3@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[2].Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'ProjectTriggerHandlerTest Contact 4',
                        Email = 'contact4@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[3].Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'ProjectTriggerHandlerTest Contact 5',
                        Email = 'contact5@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[4].Id
                )
        );

        insert contactList;
    } // end of createContacts()

    static void createOpportunities(){

        oppList = new List<Opportunity>();
        oppList.add(
                new Opportunity(
                        Name = 'ProjectTriggerHandlerTest Opp 1',
                        AccountId = accountList[0].Id,
                        RecordTypeId = recordTypeMap.get(OPPORTUNITY_TYPE_PM_STANDARD),
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

        oppList.add(
                new Opportunity(
                        Name = 'ProjectTriggerHandlerTest Opp 2',
                        AccountId = accountList[1].Id,
                        RecordTypeId = recordTypeMap.get(OPPORTUNITY_TYPE_PM_STANDARD),
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

    static void CreatePortalUsers() {

        userList = new List<User>();
        Profile profile = [SELECT Id from Profile where Name = 'Partner Community User'];

        userList.add(
                new User(
                        FirstName = 'Partner',
                        LastName = 'User1',
                        ContactId = contactList[2].Id,
                        Email = 'partner1@incontact.com',
                        Username = 'partner1@incontact.com',
                        Alias = 'test',
                        profileId = profile.Id,
                        EmailEncodingKey = 'UTF-8',
                        TimeZoneSidKey = 'America/Los_Angeles',
                        LocaleSidKey = 'en_US',
                        LanguageLocaleKey = 'en_US'
                )
        );
        userList.add(
                new User(
                        FirstName = 'Partner',
                        LastName = 'User2',
                        ContactId = contactList[3].Id,
                        Email = 'partner2@incontact.com',
                        Username = 'partner2@incontact.com',
                        Alias = 'test',
                        profileId = profile.Id,
                        EmailEncodingKey = 'UTF-8',
                        TimeZoneSidKey = 'America/Los_Angeles',
                        LocaleSidKey = 'en_US',
                        LanguageLocaleKey = 'en_US'
                )
        );

        userList.add(
                new User(
                        FirstName = 'Partner',
                        LastName = 'User3',
                        ContactId = contactList[4].Id,
                        Email = 'partner3@incontact.com',
                        Username = 'partner3@incontact.com',
                        Alias = 'test',
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

    } // end of CreatePortalUsers()

    static void CreatePublicGroup() {

        Group newGroup = new Group(
                Name = 'Test Group',
                DeveloperName = 'Test_Group'
        );
        insert newGroup;

        GroupMember newMember = new GroupMember(
                UserOrGroupId = userList[2].Id,
                GroupId = newGroup.Id
        );

        system.runAs( new user( Id = UserInfo.getUserID() ) ) {
            insert newMember;
        }

    } // end of CreatePublicGroup()

}