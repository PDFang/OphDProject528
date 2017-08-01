/**
 * Created by william.nelson on 8/1/2017.
 */
@isTest
public with sharing class XMPersonDeviceUploadBatchTest {
    private static Account testAccount;

    private static void SetupData(){

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        //setup the reference account
        testAccount = new Account(
                Name = 'ContactTriggerHandlerTest Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId()
        );

        insert testAccount;

        //setup the reference xmperson
        xmPerson__c person = new xmPerson__c(
                xmPersonUID__c = 'efrd-sqaw-123e-deft'
        );
        insert person;

        //setup scenario 1 with 1 xmperson and two duplicates

        Map<String,Schema.RecordTypeInfo> contactRecordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact testContact = new Contact(
                LastName = 'Contact1',
                FirstName = 'ContactTriggerHandlerTest',
                Email = 'contact1@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = person.Id
        );

        insert testContact;

        testContact = new Contact(
                LastName = 'Contact1',
                FirstName = 'ContactTriggerHandlerTest',
                Email = 'contact1@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = null
        );

        insert testContact;
        testContact = new Contact(
                LastName = 'Contact1',
                FirstName = 'ContactTriggerHandlerTest',
                Email = 'contact1@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = null
        );

        insert testContact;
        //scnario 2  no duplicates
        testContact = new Contact(
                LastName = 'Contact2',
                FirstName = 'ContactTriggerHandlerTest',
                Email = 'contact2@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = null
        );
        insert testContact;
        testContact = new Contact(
                LastName = 'Contact2',
                FirstName = 'ContactTriggerHandlerTest',
                Email = 'contact3@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = null
        );
        insert testContact;

        //scnario 3  duplicats no xm person
        testContact = new Contact(
                LastName = 'Contact3',
                FirstName = 'ContactTriggerHandlerTest',
                Email = 'contact4@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = null
        );
        insert testContact;
        //scnario 2  no duplicates
        testContact = new Contact(
                LastName = 'Contact3',
                FirstName = 'ContactTriggerHandlerTest',
                Email = 'contact4@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = null
        );
        insert testContact;
    }
    static void TestContactLoad(){
        SetupData();
        test.startTest();
        //call batch
        //XMPersonDeviceUploadBatch

        test.stopTest();
    }


}

