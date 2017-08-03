/**
 * Created by william.nelson on 8/1/2017.
 */
@isTest
public with sharing class XMPersonDeviceUploadBatchTest{

    testMethod static void personDeviceUploadBatchTest(){

        Account[] testAccounts = [Select Id from Account];

        //setup the reference xmperson
        xmPerson__c person = new xmPerson__c(
                xmPersonUID__c = 'efrd-sqaw-123e-deft'
        );
        insert person;

        // create contacts
        Contact[] testContacts = new Contact[]{};

        Map<String,Schema.RecordTypeInfo> contactRecordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();

        //setup contact with xmperson
        Contact testContact1 = new Contact(
                LastName = 'Contact1',
                FirstName = 'XMPersonDeviceUploadBatchTest',
                Email = 'contact1@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccounts[0].Id,
                xmPerson__c = person.Id,
                Contact_Role__c = 'Event Notification;Maintenance Notification'
        );

        testContacts.add(testContact1);

        // setup duplicate contact
        Contact testContact2 = new Contact(
                LastName = 'Contact2',
                FirstName = 'XMPersonDeviceUploadBatchTest',
                Email = 'contact1@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccounts[1].Id,
                xmPerson__c = null,
                Contact_Role__c = 'Maintenance Notification'
        );

        testContacts.add(testContact2);

        //scenario - contact with distinct email
        Contact testContact3 = new Contact(
                LastName = 'Contact3',
                FirstName = 'XMPersonDeviceUploadBatchTest',
                Email = 'contact3@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccounts[1].Id,
                xmPerson__c = null,
                Contact_Role__c = 'Maintenance Notification'
        );

        testContacts.add(testContact3);

        //scenario - contact without notification role
        Contact testContact4 = new Contact(
                LastName = 'Contact4',
                FirstName = 'ContactTriggerHandlerTest',
                Email = 'contact4@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccounts[0].Id,
                xmPerson__c = null,
                Contact_Role__c = 'Main;Billing'
        );
        testContacts.add(testContact4);

        //scenario - deactivated contact
        Contact testContact5 = new Contact(
                LastName = 'Contact5',
                FirstName = 'ContactTriggerHandlerTest',
                Email = 'contact5@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccounts[1].Id,
                xmPerson__c = null,
                Deactivated__c = true,
                Contact_Role__c = 'Event Notification'
        );
        testContacts.add(testContact5);

        insert testContacts;

        XMRestPeopleMockHttpGenerator httpMock = new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        Test.setMock(HttpCalloutMock.class, httpMock);

        test.startTest();

        Database.executeBatch(new XMPersonDeviceUploadBatch(), 20);
        test.stopTest();

        Contact[] contacts = [Select Id, xmPerson__c from Contact where Id IN :testContacts];

        system.assertEquals(contacts[0].xmPerson__c, contacts[1].xmPerson__c, 'Contacts should be associated with same XM Person.');

        system.assertNotEquals(null, contacts[2].xmPerson__c, 'Contacts should be associated a new XM Person.');

        system.assertEquals(null, contacts[3].xmPerson__c, 'Contacts should not be associated with XM Person if it has no notification roles.');

        system.assertEquals(null, contacts[4].xmPerson__c, 'Contacts should not be associated with XM Person if it is deactivated.');


    }

    testMethod static void personDeviceUploadBatchErrorTest(){

        Account[] testAccounts = [Select Id from Account limit 1];

        // create contacts
        Contact[] testContacts = new Contact[]{};

        Map<String,Schema.RecordTypeInfo> contactRecordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();

        //scenario - contacts with distinct email
        for(Integer i=1; i <= 20; i++){
            Contact testContact = new Contact(
                    LastName = 'Contact' + i,
                    FirstName = 'XMPersonDeviceUploadBatchTest',
                    Email = 'contact' + i + '@test.com',
                    RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                    AccountId = testAccounts[0].Id,
                    xmPerson__c = null,
                    Contact_Role__c = 'Event Notification'
            );

            testContacts.add(testContact);
        }


        insert testContacts;

        test.startTest();

        // mock http callout not set

        Database.executeBatch(new XMPersonDeviceUploadBatch(), 20);
        test.stopTest();

    }

    @TestSetup
    private static void SetupData() {

        // create two accounts
        Account[] testAccounts = new Account[]{
        };

        Map<String, Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        //setup the reference account
        Account testAccount1 = new Account(
                Name = 'XMPersonDeviceUploadBatchTest Account 1',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId()
        );
        testAccounts.add(testAccount1);

        Account testAccount2 = new Account(
                Name = 'XMPersonDeviceUploadBatchTest Account 2',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId()
        );
        testAccounts.add(testAccount2);

        insert testAccounts;

    }

}

