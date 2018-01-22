@IsTest
private class XMNotificationGroupBatchTests {

    static testMethod void testExecuteBatch() {
        xmNotificationGroups__c notificationGroup = [Select Case__c, Name, Status__c, xmGroupUID__c From xmNotificationGroups__c limit 1];

        XMNotificationGroupBatchRestCallMock httpMockCallout = new XMNotificationGroupBatchRestCallMock(200);

        XMNotificationGroupBatch batch = new XMNotificationGroupBatch(notificationGroup);

        test.startTest();

        test.setMock(HttpCalloutMock.class, httpMockCallout);

        Database.executeBatch(batch, 50);

        test.stopTest();

        //validate that it worked
        //3 devices should have been added to the group
        system.assertEquals(3, httpMockCallout.devicesAddedToGroup.size(), 'Wrong number of devices added by the Batch');

        //ensure that the devices added were correct
        for(String device : httpMockCallout.devicesAddedToGroup) {
            system.assert(device.startsWith('workemail_'), 'Wrong device was added to the group');
        }
    }

    @testSetup
    private static void setupTestData() {
        //create Account
        List<Account> testAccounts = new List<Account>();

        testAccounts.add(new Account(
                Name = 'Account Included One',
                inContact_Cluster__c = 'C30'
        ));
        testAccounts.add(new Account(
                Name = 'Account Included Two',
                inContact_Cluster__c = 'C30'
        ));
        testAccounts.add(new Account(
                Name = 'Account Included Three',
                inContact_Cluster__c = 'C31'
        ));

        insert testAccounts;

        //create xmPersons
        List<xmPerson__c> xmPersons = new List<xmPerson__c>();
        xmPersons.add(new xmPerson__c(
                xmPersonUID__c = 'test 1'
        ));
        xmPersons.add(new xmPerson__c(
                xmPersonUID__c = 'test 2'
        ));
        xmPersons.add(new xmPerson__c(
                xmPersonUID__c = 'test 3'
        ));

        insert xmPersons;


        //create Contacts
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
        testContacts.add(new Contact(
                FirstName = 'Test',
                LastName = '3',
                Email = 'test3@test.com',
                AccountId = testAccounts[2].Id,
                xmPerson__c = xmPersons[2].Id
        ));

        insert testContacts;

        //insert a Case
        RecordType maintenanceRecordType = [Select Id From RecordType Where Name = 'Maintenance Notification'][0];

        Case testCase = new Case(
                RecordTypeId = maintenanceRecordType.Id,
                ProductImpacted__c = 'TestProduct',
                PlatformsImpacted__c = 'Test1;Test2'
        );

        insert testCase;

        //create notification group
        xmNotificationGroups__c notificationGroup = new xmNotificationGroups__c(
                Case__c = testCase.Id,
                Name = 'TestGroup',
                Status__c = 'Accounts Associated',
                xmGroupUID__c = 'testGroup'
        );

        insert notificationGroup;

        //create notification accounts
        List<xmNotificationAccounts__c> notificationAccounts = new List<xmNotificationAccounts__c>();
        notificationAccounts.add(new xmNotificationAccounts__c(
                Account__c = testAccounts[0].Id,
                Notification_Group__c = notificationGroup.Id
        ));
        notificationAccounts.add(new xmNotificationAccounts__c(
                Account__c = testAccounts[1].Id,
                Notification_Group__c = notificationGroup.Id
        ));
        notificationAccounts.add(new xmNotificationAccounts__c(
                Account__c = testAccounts[2].Id,
                Notification_Group__c = notificationGroup.Id
        ));

        insert notificationAccounts;
    }
}