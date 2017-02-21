
@IsTest
private class AccountPartnerTriggerHandlerTest {

    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String ACCOUNT_TYPE_PARTNERS = 'Partners';
    static final String CONTACT_TYPE_PARTNER = 'Partner Contact';
    static final String PROJECT_TYPE_PARENT_SAAS = 'PS Parent Project - SaaS';
    static final String PROJECT_TYPE_PARENT_PREMISE = 'PS Parent Project - Premise';
    static final String OPPORTUNITY_TYPE_NEW = 'New Opportunity';
    static final String CASE_TYPE_INCIDENT = 'Incident';
    static final String CASE_TYPE_EVENT = 'Event';

    static final Set<String> recordTypeSet = new Set<String>
    {
            ACCOUNT_TYPE_CUSTOMERS,
            ACCOUNT_TYPE_PARTNERS,
            CONTACT_TYPE_PARTNER,
            OPPORTUNITY_TYPE_NEW,
            PROJECT_TYPE_PARENT_SAAS,
            PROJECT_TYPE_PARENT_PREMISE,
            CASE_TYPE_EVENT
    };

    static Map<String, Id> recordTypeMap = null;
    static List<Account> accountList = null;
    static List<Contact> contactList = null;
    static List<Opportunity> oppList = null;
    static List<User> userList = null;

    /* Affiliate public group and partner account to a customer account and verify 
    1. group members and portal users on the partner account have access to customer account and it's related records 
	2. group members and portal users on the partner account are assigned permission sets corresponding to the partner type 
	*/
    static testMethod void addPartnerTest() {

        createTestData();
        
        test.startTest();
        List<Account_Partner__c> partnerList = new List<Account_Partner__c>();
        partnerList.add(
                new Account_Partner__c(
                        Customer__c = accountList[0].Id,
                        Partner__c = accountList[2].Id,
                    	Partner_Type__c = AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER
                )
        );

        partnerList.add(
                new Account_Partner__c(
                        Customer__c = accountList[0].Id,
                        Partner__c = accountList[3].Id,
                        Partner_Type__c = AccountPartnerTriggerHandler.PREMISE_IMPLEMENTATION_PARTNER
                )
        );

        partnerList.add(
                new Account_Partner__c(
                        Customer__c = accountList[1].Id,
                        Partner__c = accountList[3].Id,
                    	Partner_Type__c = AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER
                )
        );
        partnerList.add(
                new Account_Partner__c(
                        Customer__c = accountList[1].Id,
                        Public_Group__c = 'Test Group',
                    	Partner_Type__c = AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER
                )
        );
        insert partnerList;
        test.stopTest();

        // partner 1
        system.runAs(userList[0]){
            List<Account> accounts = [SELECT Id from Account where RecordType.Name = :ACCOUNT_TYPE_CUSTOMERS];
            system.assertEquals(1, accounts.size());

            List<Contact> Contacts = [SELECT Id from Contact where AccountId = :accounts[0].Id];
            system.assertEquals(1, Contacts.size());

            List<Case> cases = [SELECT Id from Case where AccountId = :accounts[0].Id];
            system.assertEquals(1, cases.size());

            List<Opportunity> opportunities = [SELECT Id from Opportunity where AccountId = :accounts[0].Id];
            system.assertEquals(0, opportunities.size());

            // SaaS project
            List<Project__c> saasProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_SAAS
            ];
            system.assertEquals(1, saasProjects.size());
            // Premise project
            List<Project__c> premiseProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_PREMISE
            ];
            system.assertEquals(1, premiseProjects.size());

        }
        // partner 2
        system.runAs(userList[1]){
            List<Account> accounts = [SELECT Id from Account where RecordType.Name = :ACCOUNT_TYPE_CUSTOMERS];
            system.assertEquals(2, accounts.size());

            List<Contact> Contacts = [SELECT Id from Contact where AccountId IN :accounts];
            system.assertEquals(2, Contacts.size());

            List<Case> cases = [SELECT Id from Case where AccountId IN :accounts];
            system.assertEquals(2, cases.size());

            List<Opportunity> opportunities = [SELECT Id from Opportunity where AccountId IN :accounts];
            system.assertEquals(0, opportunities.size());

            // SaaS project
            List<Project__c> saasProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_SAAS
            ];
            system.assertEquals(1, saasProjects.size());
            // Premise project
            List<Project__c> premiseProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_PREMISE
            ];
            system.assertEquals(1, premiseProjects.size());
        }
        // public group member
        system.runAs(userList[2]){
            List<Account> accounts = [SELECT Id, Name from Account where RecordType.Name = :ACCOUNT_TYPE_CUSTOMERS];
            system.assertEquals(1, accounts.size());

            List<Contact> Contacts = [SELECT Id from Contact where AccountId = :accounts[0].Id];
            system.assertEquals(1, Contacts.size());

            List<Case> cases = [SELECT Id from Case where AccountId = :accounts[0].Id];
            system.assertEquals(1, cases.size());

            List<Opportunity> opportunities = [SELECT Id from Opportunity where AccountId = :accounts[0].Id];
            system.assertEquals(0, opportunities.size());

            // SaaS project
            List<Project__c> saasProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_SAAS
            ];
            system.assertEquals(1, saasProjects.size());
            // Premise project
            List<Project__c> premiseProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_PREMISE
            ];
            system.assertEquals(0, premiseProjects.size());
        }
		
        // verify permission set assignments
        Map<String, String> partnerPermissionMap = new Map<String, String>();
        for(Partner_Permission_Sets__c ps : [
                Select Permission_Set__c, Partner_Type__c from Partner_Permission_Sets__c
        ])
        {
            partnerPermissionMap.put(ps.Partner_Type__c, ps.Permission_Set__c);
        }

        if(partnerPermissionMap.size() > 0){
            Set<Id> assigneeIdSet = new Set<Id>();
            for(PermissionSetAssignment psa :[
                Select PermissionSetId, AssigneeId from PermissionSetAssignment where PermissionSet.Name IN :partnerPermissionMap.values()
            ]){
                assigneeIdSet.add(psa.AssigneeId);
            }
            system.assertEquals(partnerPermissionMap.containsKey(AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER),assigneeIdSet.contains(userList[0].Id), 'Permission set assignment failed.');
        	system.assertEquals(partnerPermissionMap.containsKey(AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER),assigneeIdSet.contains(userList[1].Id), 'Permission set assignment failed.');
            system.assertEquals(partnerPermissionMap.containsKey(AccountPartnerTriggerHandler.PREMISE_IMPLEMENTATION_PARTNER),assigneeIdSet.contains(userList[1].Id), 'Permission set assignment failed.');
        	system.assertEquals(partnerPermissionMap.containsKey(AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER),assigneeIdSet.contains(userList[2].Id), 'Permission set assignment failed.');
            system.assertEquals(partnerPermissionMap.containsKey(AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER),!assigneeIdSet.contains(userList[3].Id), 'Contact has Do Not Assign Permission Set flag checked.');
        }
        
    } // end of addPartnerTest()

    /* Remove customer partner affiliation and verify 
    1. group members and portal users on the partner account no longer have access to customer account and it's related records
	2. group members and portal users on the partner account permission set assignments are removed
	*/
    static testMethod void deletePartnerTest() {

        createTestData();

        List<Account_Partner__c> partnerList = new List<Account_Partner__c>();
        partnerList.add(
                new Account_Partner__c(
                        Customer__c = accountList[0].Id,
                        Partner__c = accountList[2].Id,
                        Partner_Type__c = AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER
                )
        );
        partnerList.add(
                new Account_Partner__c(
                        Customer__c = accountList[1].Id,
                        Partner__c = accountList[3].Id,
                        Partner_Type__c = AccountPartnerTriggerHandler.PREMISE_IMPLEMENTATION_PARTNER
                )
        );
        partnerList.add(
                new Account_Partner__c(
                        Customer__c = accountList[1].Id,
                        Public_Group__c = 'Test Group',
                        Partner_Type__c = AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER
                )
        );
        insert partnerList;

        test.startTest();
        delete new List<Account_Partner__c>{partnerList[0], partnerList[1], partnerList[2]};
        test.stopTest();

        system.runAs(userList[0]){
            List<Account> accounts = [SELECT Id from Account where RecordType.Name = :ACCOUNT_TYPE_CUSTOMERS];
            system.assertEquals(0, accounts.size());

            List<Contact> Contacts = [SELECT Id, Name from Contact where Account.RecordType.Name = :ACCOUNT_TYPE_CUSTOMERS];
            system.assertEquals(0, Contacts.size(), Contacts);

            List<Case> cases = [SELECT Id from Case];
            system.assertEquals(0, cases.size());

            List<Opportunity> opportunities = [SELECT Id from Opportunity];
            system.assertEquals(0, opportunities.size());

            // SaaS project
            List<Project__c> saasProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_SAAS
            ];
            system.assertEquals(0, saasProjects.size());
            // Premise project
            List<Project__c> premiseProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_PREMISE
            ];
            system.assertEquals(1, premiseProjects.size());
        }

        system.runAs(userList[1]){
            List<Account> accounts = [SELECT Id from Account where RecordType.Name = :ACCOUNT_TYPE_CUSTOMERS];
            system.assertEquals(0, accounts.size());

            List<Contact> Contacts = [SELECT Id from Contact where Account.RecordType.Name = :ACCOUNT_TYPE_CUSTOMERS];
            system.assertEquals(0, Contacts.size());

            List<Case> cases = [SELECT Id from Case];
            system.assertEquals(0, cases.size());

            List<Opportunity> opportunities = [SELECT Id from Opportunity];
            system.assertEquals(0, opportunities.size());

            // SaaS project
            List<Project__c> saasProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_SAAS
            ];
            system.assertEquals(0, saasProjects.size());
            // Premise project
            List<Project__c> premiseProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_PREMISE
            ];
            system.assertEquals(1, premiseProjects.size());
        }

        system.runAs(userList[2]){
            List<Account> accounts = [SELECT Id from Account where RecordType.Name = :ACCOUNT_TYPE_CUSTOMERS];
            system.assertEquals(0, accounts.size());
            
            List<Contact> Contacts = [SELECT Id from Contact where Account.RecordType.Name = :ACCOUNT_TYPE_CUSTOMERS];
            system.assertEquals(0, Contacts.size());

            List<Case> cases = [SELECT Id from Case];
            system.assertEquals(0, cases.size());

            List<Opportunity> opportunities = [SELECT Id from Opportunity];
            system.assertEquals(0, opportunities.size());

            // SaaS project
            List<Project__c> saasProjects = [
                    SELECT Id from Project__c
                    where RecordType.Name = :PROJECT_TYPE_PARENT_SAAS
            ];
            system.assertEquals(0, saasProjects.size());
        }
		
        // verify permission set assignments are removed
        Map<String, String> partnerPermissionMap = new Map<String, String>();
        for(Partner_Permission_Sets__c ps : [
                Select Permission_Set__c, Partner_Type__c from Partner_Permission_Sets__c
        ])
        {
            partnerPermissionMap.put(ps.Partner_Type__c, ps.Permission_Set__c);
        }

        if(partnerPermissionMap.size() > 0){
            Set<Id> assigneeIdSet = new Set<Id>();
            for(PermissionSetAssignment psa :[
                Select PermissionSetId, AssigneeId from PermissionSetAssignment where PermissionSet.Name IN :partnerPermissionMap.values()
            ]){
                assigneeIdSet.add(psa.AssigneeId);
            }
            system.assert(!assigneeIdSet.contains(userList[0].Id), 'Permission set assignment failed.');
        	system.assert(!assigneeIdSet.contains(userList[2].Id), 'Permission set assignment failed.');
        }
        
    } // deletePartnerTest()

    /* Verify the Account_Partner__c.Partner__c field cannot be edited after initial save */
    static testmethod void updatePartnerTest(){

        createTestData();
        Account_Partner__c partner = new Account_Partner__c(
                Customer__c = accountList[0].Id,
                Partner__c = accountList[2].Id,
                Partner_Type__c = 'iCE'
        );

        insert partner;

        test.startTest();
        partner.Partner__c = accountList[3].Id;
        Database.SaveResult result = Database.update(partner, false);
        test.stopTest();

        system.assertEquals(false, result.isSuccess(), 'Partner field should not be editable.');

    } // end of updatePartnerTest()
    
    /* Verify the Account_Partner__c.Partner_Type__c field cannot be edited after initial save */
    static testmethod void updatePartnerTypeTest(){

        createTestData();
        Account_Partner__c partner = new Account_Partner__c(
                Customer__c = accountList[0].Id,
                Partner__c = accountList[2].Id,
                Partner_Type__c = 'iCE'
        );

        insert partner;

        test.startTest();
        partner.Partner_Type__c = 'ReSell Partner';
        Database.SaveResult result = Database.update(partner, false);
        test.stopTest();

        system.assertEquals(false, result.isSuccess(), 'Partner type field should not be editable.');

    } // end of updatePartnerTypeTest()
    
    /* Verify the Account_Partner__c.Public_Group__c field cannot be edited after initial save */
    static testmethod void updatePublicGroupTest(){

        createTestData();
        Account_Partner__c partner = new Account_Partner__c(
                Customer__c = accountList[0].Id,
                Public_Group__c = 'Test Group',
                Partner_Type__c = 'iCE'
        );

        insert partner;

        test.startTest();
        partner.Public_Group__c = 'New Group';
        Database.SaveResult result = Database.update(partner, false);
        test.stopTest();

        system.assertEquals(false, result.isSuccess(), 'Public group field should not be editable.');

    } // end of updatePublicGroupTest()

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

        // create permission set for SaaS and Premise Partner
        PermissionSet[] permissionSets = new PermissionSet[]{};
        PermissionSet saasPs = new PermissionSet(
                Name = 'SAAS_Permission_Set',
                Label = 'SAAS_Permission_Set'
        );
        permissionSets.add(saasPs);
        PermissionSet premisePs = new PermissionSet(
                Name = 'PREMISE_Permission_Set',
                Label = 'PREMISE_Permission_Set'
        );
        permissionSets.add(premisePs);
        system.runAs(new User(Id = userInfo.getUserId())){
            insert permissionSets;
        }

        // Create permission set mapping
        Partner_Permission_Sets__c[] settings = new Partner_Permission_Sets__c[]{};
        Partner_Permission_Sets__c saasPartner = new Partner_Permission_Sets__c(
                Name ='SAAS_IMPLEMENTATION_PARTNER',
                Permission_Set__c = permissionSets[0].Name,
                Partner_Type__c = AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER
        );
        settings.add(saasPartner);
        Partner_Permission_Sets__c premisePartner = new Partner_Permission_Sets__c(
                Name ='PREMISE_IMPLEMENTATION_PARTNER',
                Permission_Set__c = permissionSets[1].Name,
                Partner_Type__c = AccountPartnerTriggerHandler.PREMISE_IMPLEMENTATION_PARTNER
        );
        settings.add(premisePartner);

        insert settings;


        createAccounts();
        createContacts();
        createCases();
        createOpportunities();
        createProjects();
        CreatePortalUsers();
        CreatePublicGroup();

    } // end of createTestData()

    static void createAccounts()
    {
        accountList = new List<Account>();
        accountList.add(
                new Account(
                        Name = 'AccountPartnerTriggerHandlerTest Customer 1',
                        Type = 'Customer',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS)
                )
        );
        accountList.add(
                new Account(
                        Name = 'AccountPartnerTriggerHandlerTest Customer 2',
                        Type = 'Customer',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS)
                )
        );
        accountList.add(
                new Account(
                        Name = 'AccountPartnerTriggerHandlerTest Partner 1',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_PARTNERS)
                )
        );
        accountList.add(
                new Account(
                        Name = 'AccountPartnerTriggerHandlerTest Partner 2',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_PARTNERS)
                )
        );
        accountList.add(
                new Account(
                        Name = 'AccountPartnerTriggerHandlerTest Partner 3',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_PARTNERS)
                )
        );

        insert accountList;
    } // end of createAccounts()

    static void createContacts() {

        contactList = new List<Contact>();
        contactList.add(
                new Contact(
                        LastName = 'AccountPartnerTriggerHandlerTest Contact 1',
                        Email = 'contact1@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[0].Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'AccountPartnerTriggerHandlerTest Contact 2',
                        Email = 'contact2@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[1].Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'AccountPartnerTriggerHandlerTest Contact 3',
                        Email = 'contact3@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[2].Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'AccountPartnerTriggerHandlerTest Contact 4',
                        Email = 'contact4@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[3].Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'AccountPartnerTriggerHandlerTest Contact 5',
                        Email = 'contact4@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[4].Id
                )
        );

        contactList.add(
                new Contact(
                        LastName = 'AccountPartnerTriggerHandlerTest Contact 6',
                        Email = 'contact4@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[2].Id,
                        Do_Not_Assign_Partner_Permission_Set__c = true
                )
        );

        insert contactList;
    } // end of createContacts()

    static void createCases() {

        SiteConfiguration__c siteConfig = new SiteConfiguration__c(
                Name = UserInfo.getOrganizationId().left(15),
                AutoEventEmails__c = false,
                DaysToDisplayKnownIssues__c = 30
        );
        insert siteConfig;

        List<Case> caseList = new List<Case>();
        Case case1 = new Case(
                RecordTypeId = recordTypeMap.get(CASE_TYPE_EVENT),
                Subject = 'AccountPartnerTriggerHandlerTest',
                Status = 'New',
                AccountId = accountList[0].Id,
                EventType__c = 'Service Disruption'
        );
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        case1.setOptions(dmo);
        caseList.add(case1);

        Case case2 = new Case(
                RecordTypeId = recordTypeMap.get(CASE_TYPE_EVENT),
                Subject = 'AccountPartnerTriggerHandlerTest',
                Status = 'New',
                AccountId = accountList[1].Id,
                EventType__c = 'Service Disruption'
        );
        case2.setOptions(dmo);
        caseList.add(case2);

        insert caseList;

    } // end of createCases()

    static void createOpportunities(){

        oppList = new List<Opportunity>();
        oppList.add(
                new Opportunity(
                        Name = 'AccountPartnerTriggerHandlerTest Opp 1',
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

        oppList.add(
                new Opportunity(
                        Name = 'AccountPartnerTriggerHandlerTest Opp 2',
                        AccountId = accountList[1].Id,
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

    static void createProjects(){

        List<Project__c> projectList = new List<Project__c>();
        Project__c project1 = new Project__c();
        project1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_SAAS);
        project1.Opportunity__c = oppList[0].Id;
        project1.Account__c = accountList[0].Id;
        projectList.add(project1);

        Project__c project2 = new Project__c();
        project2.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_SAAS);
        project2.Opportunity__c = oppList[1].Id;
        project2.Account__c = accountList[1].Id;
        projectList.add(project2);

        Project__c project3 = new Project__c();
        project3.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_PREMISE);
        project3.Opportunity__c = oppList[0].Id;
        project3.Account__c = accountList[0].Id;
        project3.ImplementationPartner__c = accountList[2].Id;
        projectList.add(project3);

        Project__c project4 = new Project__c();
        project4.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_PREMISE);
        project4.Opportunity__c = oppList[1].Id;
        project4.Account__c = accountList[1].Id;
        project4.ImplementationPartner__c = accountList[3].Id;
        projectList.add(project4);

        insert projectList;

    } // end of createProjects()

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

        userList.add(
                new User(
                        FirstName = 'Partner',
                        LastName = 'User4',
                        ContactId = contactList[5].Id,
                        Email = 'partner4@incontact.com',
                        Username = 'partner4@incontact.com',
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