@IsTest
private class CaseOpenEventsControllerTest {

    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String CASE_TYPE_INCIDENT = 'Incident';
    static final String CASE_TYPE_EVENT = 'Event';
    static final Set<String> recordTypeSet = new Set<String>{
            ACCOUNT_TYPE_CUSTOMERS,
            CASE_TYPE_INCIDENT,
            CASE_TYPE_EVENT
    };
    static final Set<String> sObjectSet = new Set<String>{
            'Account',
            'Case',
            'Contact'
    };

    static Map<String, Id> recordTypeMap = null;
    static Account testAccount = null;
    static List<Case> caseList = null;

    static testMethod void testController() {

        createTestData();
        test.startTest();
        test.setCurrentPage(Page.CaseOpenEvents);
        ApexPages.currentPage().getParameters().put('eventId', caseList[0].Id);
        ApexPages.currentPage().getParameters().put('pos', '0');

        CaseOpenEventsController testController = new CaseOpenEventsController();
        system.assertEquals(1, testController.cases.size());
        testController.ShowAllOpen();

        testController.selectedEvent = testController.caseList[0].Id;
        system.assertEquals(1, testController.openEvents);

        testController.searchString = 'test';
        testController.AccountSearch();
        testController.selectedAccount = testController.accounts[0].Id;
        system.assertEquals(1, testController.numberOfAccounts);

        testController.FindContacts();
        testController.selectedContact = testController.contacts[0].Id;
        system.assertEquals(1, testController.contacts.size());

        testController.FindChildCases();
        system.assertEquals(1, testController.childCases.size());
        system.assertEquals(1, testController.eventLogs.size());

        testController.CreateChildCase();
        testController.FindChildCases();
        system.assertEquals(2, testController.childCases.size());

        test.stopTest();
    }

    static void createTestData() {
        recordTypeMap = new Map<String, Id>();
        for (RecordType record : [
                Select Id, Name
                from RecordType
                where Name IN :recordTypeSet and SobjectType IN :sObjectSet
        ]) {
            recordTypeMap.put(record.Name, record.Id);
        }

        createSiteConfig();
        createAccount();
        createContacts();
        createCases();
        createCaseComment();
    }

    static void createSiteConfig() {
        SiteConfiguration__c siteConfig = new SiteConfiguration__c(
                Name = UserInfo.getOrganizationId().left(15),
                AutoEventEmails__c = false,
                DaysToDisplayKnownIssues__c = 30
        );
        insert siteConfig;
    }

    static void createAccount() {
        testAccount = new Account(
                Name = 'CaseOpenEventsControllerTest Account',
                RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS)
        );
        insert testAccount;
    }

    static void createContacts() {
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(
                AccountId = testAccount.Id,
                FirstName = 'firstName',
                LastName = 'lastName',
                Email = 'email@incontact.com',
                Deactivated__c = false,
                Contact_Role__c = 'Admin'
        ));

        insert contactList;

    }

    static void createCases() {

        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;

        caseList = new List<Case>();
        Case parentCase = new Case(
                RecordTypeId = recordTypeMap.get(CASE_TYPE_EVENT),
                Subject = 'CaseOpenEventsControllerTest',
                Status = 'New',
                EventType__c = 'Service Disruption'
        );
        parentCase.setOptions(dmo);
        insert parentCase;
        caseList.add(parentCase);

        Case childCase = new Case(
                ParentId = parentCase.Id,
                Subject = parentCase.Subject,
                AccountId = testAccount.Id,
                RecordTypeId = recordTypeMap.get(CASE_TYPE_INCIDENT)
        );
        childCase.setOptions(dmo);
        insert childCase;
        caseList.add(childCase);

    }

    static void createCaseComment()
    {
        CaseComment testComment = new CaseComment(
                CommentBody = 'New Comment',
                ParentId = caseList[0].Id
        );

        insert testComment;
    }

}