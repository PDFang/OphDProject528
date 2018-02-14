@IsTest
private class xmNotificationAccountQueueableTests {
    private static List<Account> testAccounts;

    static testMethod void testExecuteWithAccountList() {
        String testCaseId = setupTestData();

        XMRestEventServiceHttpMock httpMockCallout = new XMRestEventServiceHttpMock(200,'Complete','[{"Name": "sForceTest1"}]',null);

        xmNotificationGroups__c notificationGroup = new xmNotificationGroups__c(
                Case__c = testCaseId,
                Name = 'TestGroup',
                Status__c = 'New',
                xmGroupUID__c = 'testGroup'
        );

        insert notificationGroup;

        xmNotificationAccountQueueable queueable = new xmNotificationAccountQueueable(notificationGroup);

        test.startTest();

        test.setMock(HttpCalloutMock.class, httpMockCallout);

        Id queueableId = System.enqueueJob(queueable);

        test.stopTest();

        //check the assertions
        notificationGroup = [select Status__c from xmNotificationGroups__c where Id = :notificationGroup.Id][0];

        system.assertEquals('Accounts Associated', notificationGroup.Status__c, 'xmNotificationGroups__c.Status__c was not set correctly');

        List<xmNotificationAccounts__c> notificationAccounts = [select Account__c from xmNotificationAccounts__c where Notification_Group__c = :notificationGroup.Id];
        system.debug('notificationAccounts ' + notificationAccounts.size());
        system.debug(notificationAccounts);

        Map<Id, Boolean> addedAccounts = new Map<Id, Boolean>();
        for(Account acct : testAccounts) {
            addedAccounts.put(acct.Id, false);
        }

        for(xmNotificationAccounts__c acct : notificationAccounts) {
            if(addedAccounts.containsKey(acct.Account__c)) {
                system.debug(acct.Account__c + ' was added');
                addedAccounts.put(acct.Account__c, true);
            }
        }

        system.debug(addedAccounts);

        //the first account should be added
        system.assert(addedAccounts.get(testAccounts[0].Id), 'the first test account was not included');
        //the second account should not  be added
        system.assert(!addedAccounts.get(testAccounts[1].Id), 'the second test account was included');
        //the third account should be added
        system.assert(addedAccounts.get(testAccounts[2].Id), 'the third test account was not included');
    }

    static testMethod void testExecuteWithNoAccountList() {
        String testCaseId = setupTestWithNoAccounts();

        XMRestEventServiceHttpMock httpMockCallout = new XMRestEventServiceHttpMock(200,'Complete','[{"Name": "sForceTest1"}]',null);

        xmNotificationGroups__c notificationGroup = new xmNotificationGroups__c(
                Case__c = testCaseId,
                Name = 'TestGroup',
                Status__c = 'New',
                xmGroupUID__c = 'testGroup'
        );

        insert notificationGroup;

        xmNotificationAccountQueueable queueable = new xmNotificationAccountQueueable(notificationGroup);

        test.startTest();

        test.setMock(HttpCalloutMock.class, httpMockCallout);

        Id queueableId = System.enqueueJob(queueable);

        test.stopTest();

        //the status of the notificationGroup should be Failed
        //because there were no accounts to associate
        notificationGroup = [select Status__c, Id from xmNotificationGroups__c where Id = :notificationGroup.Id][0];

        system.assertEquals('Failed', notificationGroup.Status__c);

        //no Notification Accounts should have been created for this notification
        List<xmNotificationAccounts__c> notificationAccounts = [Select Id from xmNotificationAccounts__c where Notification_Group__c = :notificationGroup.Id];
        system.assert(notificationAccounts.size() == 0);
    }

    private static String setupTestWithNoAccounts() {
        //create two test accounts
        testAccounts = new List<Account>();

        testAccounts.add(new Account(
                Name = 'Account Included One',
                inContact_Cluster__c = 'C30'
        ));
        testAccounts.add(new Account(
                Name = 'Account Not Included Two',
                inContact_Cluster__c = 'C30'
        ));
        testAccounts.add(new Account(
                Name = 'Account Added Three',
                inContact_Cluster__c = 'C31'
        ));

        insert testAccounts;

        RecordType maintenanceRecordType = [Select Id From RecordType Where Name = 'Maintenance Notification'][0];

        Case testCase = new Case(
                RecordTypeId = maintenanceRecordType.Id,
                ProductImpacted__c = 'TestProduct',
                PlatformsImpacted__c = 'Test1;Test2'
        );

        insert testCase;

        return testCase.Id;
    }

    private static String setupTestData() {
        //create two test accounts
        testAccounts = new List<Account>();

        testAccounts.add(new Account(
                Name = 'Account Included One',
                inContact_Cluster__c = 'C30'
        ));
        testAccounts.add(new Account(
                Name = 'Account Not Included Two',
                inContact_Cluster__c = 'C30'
        ));
        testAccounts.add(new Account(
                Name = 'Account Added Three',
                inContact_Cluster__c = 'C31'
        ));

        insert testAccounts;

        List<xmPerson__c> xmPersons = new List<xmPerson__c>();
        xmPersons.add(new xmPerson__c(
                xmPersonUID__c = 'test 1'

        ));
        xmPersons.add(new xmPerson__c(
                xmPersonUID__c = 'test 2'
        ));

        insert xmPersons;

        List<Contact> testContacts = new List<Contact>();
        testContacts.add(new Contact(
                FirstName = 'Test',
                LastName = '1',
                Email = 'test1@test.com',
                AccountId = testAccounts[0].Id,
                xmPerson__c = xmPersons[0].Id
        ));
        testContacts.add(new Contact(
                FirstName = 'Test',
                LastName = '2',
                Email = 'test2@test.com',
                AccountId = testAccounts[1].Id,
                xmPerson__c = xmPersons[1].Id
        ));

        insert testContacts;

        //insert values into ProductEventMap__c to be able to load the list of accounts
        ProductEventMap__c eventMap = new ProductEventMap__c(
                AllCustomers__c = true,
                HasClusters__c = true,
                ImplementedProduct__c = 'TestProduct',
                Name = 'TestProduct',
                Platform__c = 'Test1',
                Product__c = 'TestProduct'
        );

        insert eventMap;

        RecordType maintenanceRecordType = [Select Id From RecordType Where Name = 'Maintenance Notification'][0];

        Case testCase = new Case(
                RecordTypeId = maintenanceRecordType.Id,
                ProductImpacted__c = 'TestProduct',
                PlatformsImpacted__c = 'Test1;Test2'
        );

        insert testCase;

        //insert the accounts the first one is auto-included, the second is excluded and the third is added
        List<EventAccount__c> eventAccounts = new List<EventAccount__c>();
        eventAccounts.add(new EventAccount__c(
                Account__c = testAccounts[1].Id,
                Event__c = testCase.Id,
                Excluded__c = true
        ));

        eventAccounts.add(new EventAccount__c(
                Account__c = testAccounts[2].Id,
                Event__c = testCase.Id,
                Excluded__c = false
        ));

        insert eventAccounts;

        //add an Opportunity for each account
        Date oppDate = Date.today().addDays(-10);
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(
                Account = testAccounts[0],
                AccountId = testAccounts[0].Id,
                Name = 'test 1',
                CloseDate = oppDate,
                StageName = 'Completed'
        ));
        opportunities.add(new Opportunity(
                Account = testAccounts[1],
                AccountId = testAccounts[1].Id,
                Name = 'test 2',
                CloseDate = oppDate,
                StageName = 'Completed'
        ));
        opportunities.add(new Opportunity(
                Account = testAccounts[2],
                AccountId = testAccounts[2].Id,
                Name = 'test 3',
                CloseDate = oppDate,
                StageName = 'Completed'
        ));

        insert opportunities;

        // add implemented products for the accounts
        Date productDate = Date.today().addDays(-2);
        List<ImplementedProduct__c> implementedProducts = new List<ImplementedProduct__c>();
        implementedProducts.add(new ImplementedProduct__c(
                GoLiveDate__c = productDate,
                Account__c = testAccounts[0].Id,
                Product__c = 'TestProduct',
                Opportunity__c = opportunities[0].Id,
                Status__c = 'Implemented'
        ));
        implementedProducts.add(new ImplementedProduct__c(
                GoLiveDate__c = productDate,
                Account__c = testAccounts[1].Id,
                Product__c = 'TestProduct',
                Opportunity__c = opportunities[1].Id,
                Status__c = 'Implemented'
        ));
        implementedProducts.add(new ImplementedProduct__c(
                GoLiveDate__c = productDate,
                Account__c = testAccounts[2].Id,
                Product__c = 'TestProduct',
                Opportunity__c = opportunities[2].Id,
                Status__c = 'Implemented'
        ));

        insert implementedProducts;

        return testCase.Id;
    }
}