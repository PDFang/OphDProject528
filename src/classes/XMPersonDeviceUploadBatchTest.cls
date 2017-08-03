/**
 * Created by william.nelson on 8/1/2017.
 */
@isTest
public with sharing class XMPersonDeviceUploadBatchTest {

    testMethod static void personDeviceUploadBatchTest(){

        SetupData();
        test.startTest();
        Database.executeBatch(new XMPersonDeviceUploadBatch(), 20);
        test.stopTest();

    }

    private static void SetupData(){

        // create two accounts
        Account[] testAccounts = new Account[]{};

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
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

        //setup the reference xmperson
        xmPerson__c person = new xmPerson__c(
                xmPersonUID__c = 'efrd-sqaw-123e-deft'
        );
        insert person;

        // create contacts
        Contact[] testContacts = new Contact[]{};

        Map<String,Schema.RecordTypeInfo> contactRecordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();

        //setup scenario 1 with 1 xmperson
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

        // setup duplicate contacts
        Contact testContact2 = new Contact(
                LastName = 'Contact2',
                FirstName = 'XMPersonDeviceUploadBatchTest',
                Email = 'contact2@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccounts[0].Id,
                xmPerson__c = null,
                Contact_Role__c = 'Maintenance Notification'
        );

        testContacts.add(testContact2);

        Contact testContact3 = new Contact(
                LastName = 'Contact2',
                FirstName = 'XMPersonDeviceUploadBatchTest',
                Email = 'contact2@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccounts[1].Id,
                xmPerson__c = null,
                Contact_Role__c = 'Event Notification'
        );

        testContacts.add(testContact3);

        //scenario - contact with distinct email
        Contact testContact4 = new Contact(
                LastName = 'Contact4',
                FirstName = 'XMPersonDeviceUploadBatchTest',
                Email = 'contact4@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccounts[1].Id,
                xmPerson__c = null,
                Contact_Role__c = 'Maintenance Notification'
        );

        testContacts.add(testContact4);

        Contact testContact5 = new Contact(
                LastName = 'Contact5',
                FirstName = 'XMPersonDeviceUploadBatchTest',
                Email = 'contact5@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccounts[1].Id,
                xmPerson__c = null,
                Contact_Role__c = 'Maintenance Notification'
        );

        testContacts.add(testContact5);

        //scenario - contact without notification role
        Contact testContact6 = new Contact(
                LastName = 'Contact6',
                FirstName = 'ContactTriggerHandlerTest',
                Email = 'contact6@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccounts[0].Id,
                xmPerson__c = null,
                Contact_Role__c = 'Main;Billing'
        );
        testContacts.add(testContact6);

        //scenario - deactivated contact
        Contact testContact7 = new Contact(
                LastName = 'Contact7',
                FirstName = 'ContactTriggerHandlerTest',
                Email = 'contact7@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccounts[1].Id,
                xmPerson__c = null,
                Deactivated__c = true,
                Contact_Role__c = 'Event Notification'
        );
        testContacts.add(testContact7);

        insert testContacts;

    }

}

