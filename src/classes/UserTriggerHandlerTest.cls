@IsTest
private class UserTriggerHandlerTest {

    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String ACCOUNT_TYPE_PARTNERS = 'Partners';
    static final String CONTACT_TYPE_PARTNER = 'Partner Contact';
    static final String PROJECT_TYPE_PARENT_SAAS = 'PS Parent Project - SaaS';
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
            CASE_TYPE_INCIDENT,
            CASE_TYPE_EVENT
    };

    static Map<String, Id> recordTypeMap = null;
    static List<Account> accountList = null;
    static List<Contact> contactList = null;
    static List<Opportunity> oppList = null;
	static Map<String, String> partnerPermissionMap = null;
    
    /* Create a new portal user and verify 
	1. user has access to the customer account and it's related records 
	2. user is assigned permission set corresponding to the partner type */
    static testMethod void testNewUser() {

        createTestData();
        test.startTest();

        Profile profile = [SELECT Id from Profile where Name = 'Partner Community User'];

        user portalUser = new User(
                FirstName = 'Partner',
                LastName = 'User1',
                ContactId = contactList[1].Id,
                Email = 'partner1@incontact.com',
                Username = 'partner1@incontact.com',
                Alias = 'test',
                profileId = profile.Id,
                EmailEncodingKey = 'UTF-8',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
        );
        insert portalUser;

        test.stopTest();

        system.runAs(portalUser){
            List<Account> accounts = [SELECT Id from Account where Type = 'Customer'];
            system.assertEquals(1, accounts.size());

            List<Contact> Contacts = [SELECT Id from Contact where AccountId = :accounts[0].Id];
            system.assertEquals(1, Contacts.size());

            List<Case> cases = [SELECT Id from Case where AccountId = :accounts[0].Id];
            system.assertEquals(2, cases.size());

            List<Opportunity> opportunities = [SELECT Id from Opportunity where AccountId = :accounts[0].Id];
            system.assertEquals(2, opportunities.size());

            List<Project__c> projects = [SELECT Id from Project__c where Account__c = :accounts[0].Id];
            system.assertEquals(2, projects.size());

        }
        
        // verify permission set assignments
        if(partnerPermissionMap.size() > 0){
            Set<Id> assigneeIdSet = new Set<Id>();
            for(PermissionSetAssignment psa :[
                Select PermissionSetId, AssigneeId from PermissionSetAssignment where PermissionSet.Name IN :partnerPermissionMap.values()
            ]){
                assigneeIdSet.add(psa.AssigneeId);
            }
            system.assert(assigneeIdSet.contains(portalUser.Id), 'Permission set assignment failed.');
        }
        
    } // end of testNewUser()

    /* Activate a portal user and verify the same user has access to the customer account and it's related records */
    static testMethod void testDisabledUser() {

        createTestData();
        User portalUser = null;

        // avoid mixed dml operation
        system.runAs( new user( Id = UserInfo.getUserID() ) ) {
            // create a new portal user
            Profile profile = [SELECT Id from Profile where Name = 'Partner Community User'];

            portalUser = new User(
                    FirstName = 'Partner',
                    LastName = 'User1',
                    ContactId = contactList[1].Id,
                    Email = 'partner1@incontact.com',
                    Username = 'partner1@incontact.com',
                    Alias = 'test',
                    profileId = profile.Id,
                    EmailEncodingKey = 'UTF-8',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    LocaleSidKey = 'en_US',
                    LanguageLocaleKey = 'en_US'
            );
            insert portalUser;

            // deactivate user
            portalUser.isActive = false;
            update portalUser;

        }

        test.startTest();
        system.runAs( new user( Id = UserInfo.getUserID() ) ) {
            // activate user
            portalUser.isActive = true;
            update portalUser;
        }
        test.stopTest();

        system.runAs(portalUser){
            List<Account> accounts = [SELECT Id from Account where Type = 'Customer'];
            system.assertEquals(1, accounts.size());

            List<Contact> Contacts = [SELECT Id from Contact where AccountId = :accounts[0].Id];
            system.assertEquals(1, Contacts.size());

            List<Case> cases = [SELECT Id from Case where AccountId = :accounts[0].Id];
            system.assertEquals(2, cases.size());

            List<Opportunity> opportunities = [SELECT Id from Opportunity where AccountId = :accounts[0].Id];
            system.assertEquals(2, opportunities.size());

            List<Project__c> projects = [SELECT Id from Project__c where Account__c = :accounts[0].Id];
            system.assertEquals(2, projects.size());

        }

    } // end of testDisabledUser()

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
        createPartners();
        createContacts();
        createCases();
        createOpportunities();
        createProjects();
    } // end of createTestData()

    static void createAccounts()
    {
        accountList = new List<Account>();
        accountList.add(
                new Account(
                        Name = 'UserTriggerHandlerTest Customer 1',
                        Type = 'Customer',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS)
                )
        );
        accountList.add(
                new Account(
                        Name = 'UserTriggerHandlerTest Partner 1',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_PARTNERS)
                )
        );
        accountList.add(
                new Account(
                        Name = 'UserTriggerHandlerTest Partner 2',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_PARTNERS)
                )
        );

        insert accountList;
    } // end of createAccounts()

    static void createPartners()
    {
        partnerPermissionMap = new Map<String, String>();
        for(Partner_Permission_Set__mdt mdt : [
            Select Permission_Set__c, Partner_Type__c from Partner_Permission_Set__mdt
        ])
        {
            partnerPermissionMap.put(mdt.Partner_Type__c, mdt.Permission_Set__c);
        }
        List<String> typeList = new List<String>(partnerPermissionMap.keySet());
        
        List<Account_Partner__c> partnerList = new List<Account_Partner__c>();
        partnerList.add(
                new Account_Partner__c(
                        Customer__c = accountList[0].Id,
                        Partner__c = accountList[1].Id,
                        Partner_Type__c = typeList.size() > 0 ? typeList[0] : 'iCE'
                )
        );
        partnerList.add(
                new Account_Partner__c(
                        Customer__c = accountList[0].Id,
                        Partner__c = accountList[2].Id,
                        Partner_Type__c = 'iCE'
                )
        );
        insert partnerList;
    } // end of createPartners()

    static void createContacts() {

        contactList = new List<Contact>();
        contactList.add(
                new Contact(
                        LastName = 'UserTriggerHandlerTest Contact 1',
                        Email = 'contact1@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[0].Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'UserTriggerHandlerTest Contact 2',
                        Email = 'contact2@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[1].Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'UserTriggerHandlerTest Contact 3',
                        Email = 'contact3@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[1].Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'UserTriggerHandlerTest Contact 4',
                        Email = 'contact4@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                        AccountId = accountList[2].Id
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
        Case parentCase = new Case(
                RecordTypeId = recordTypeMap.get(CASE_TYPE_EVENT),
                Subject = 'UserTriggerHandlerTest',
                Status = 'New',
                AccountId = accountList[0].Id,
                EventType__c = 'Service Disruption'
        );
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        parentCase.setOptions(dmo);
        insert parentCase;
        caseList.add(parentCase);

        Case childCase = new Case(
                ParentId = parentCase.Id,
                Subject = parentCase.Subject,
                AccountId = accountList[0].Id,
                RecordTypeId = recordTypeMap.get(CASE_TYPE_INCIDENT)
        );
        childCase.setOptions(dmo);
        insert childCase;
        caseList.add(childCase);

    } // end of createCases()

    static void createOpportunities(){

        oppList = new List<Opportunity>();
        oppList.add(
                new Opportunity(
                        Name = 'UserTriggerHandlerTest Opp 1',
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
                        Name = 'UserTriggerHandlerTest Opp 2',
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
        project2.Account__c = accountList[0].Id;
        projectList.add(project2);

        insert projectList;

    } // end of createProjects()

}