@IsTest
private class XMPersonManagementControllerTest {

    static final String CUSTOMER_ACCOUNT = 'Customers';
    static final String CUSTOMER_CONTACT = 'Customer-Other';

    static testMethod void testContactNoXmPerson() {

        Account testAccount = createAccount();

        Map<String, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact testContact = new Contact(
                FirstName = 'XMPersonManagementControllerTest',
                LastName = 'Contact',
                Email = 'contact1@incontact.com',
                RecordTypeId = recordTypeMap.get(CUSTOMER_CONTACT).getRecordTypeId(),
                AccountId = testAccount.Id
        );

        insert testContact;

        test.startTest();

        XMRestPeopleMockHttpGenerator xmPersonMock = new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Name": "XMPersonManagementControllerTest"}]',null);
        Test.setMock(HttpCalloutMock.class, xmPersonMock);

        XMPersonManagementController testController = new XMPersonManagementController(new ApexPages.StandardController(testContact));
        system.assertEquals( false, testController.getIsXmPerson(), 'Contact should not have an xmPerson.');
        system.assertEquals( false, testController.getIsDuplicate(), 'Contact should not have any duplicates.');
        system.assertEquals( false, testController.isPersonMatch, 'Contact should not have a matching xmPerson.');

        XMPersonWrapper person = testController.person;
        system.assertEquals( testContact.FirstName, person.firstName, 'First name should be defaulted to contact first name.');
        system.assertEquals( testContact.LastName, person.lastName, 'Last name should be defaulted to contact last name.');

        system.assertEquals( testContact.id, testController.currentContact.Id, 'Current contact should match test contact.');
        system.assertEquals( 0, testController.contactList.size(), 'Contact list should be empty.');

        testController.getTimezones();
        testController.getDeviceTypes();

        testController.addPerson();

        test.stopTest();

        XMPerson__c[] personList = [Select Id from XMPerson__c where PrimaryContact__c = :testContact.Id];
        system.assertNotEquals( 0, personList.size(), 'XmPerson record should be created.');

        testContact = [Select xmPerson__c from Contact where Id = :testContact.Id];
        system.assertEquals( personList[0].Id, testContact.xmPerson__c, 'Contact record should be associated with XmPerson.');

    }

    static testMethod void testContactWithXmPerson() {

        Account testAccount = createAccount();

        xmPerson__c person = new xmPerson__c(
                xmPersonUID__c = 'aefgh-1234-cdeft'
        );
        insert person;

        Map<String, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact testContact = new Contact(
                FirstName = 'XMPersonManagementControllerTest',
                LastName = 'Contact',
                Email = 'contact1@incontact.com',
                RecordTypeId = recordTypeMap.get(CUSTOMER_CONTACT).getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = person.Id
        );

        insert testContact;

        test.startTest();

        XMRestPeopleMockHttpGenerator xmPersonMock = new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Name": "XMPersonManagementControllerTest"}]',null);
        Test.setMock(HttpCalloutMock.class, xmPersonMock);

        XMPersonManagementController testController = new XMPersonManagementController(new ApexPages.StandardController(testContact));
        system.assertEquals( true, testController.getIsXmPerson(), 'Contact should have an xmPerson.');
        system.assertEquals( false, testController.getIsDuplicate(), 'Contact should not have any duplicates.');
        system.assertEquals( false, testController.isPersonMatch, 'Contact should not have a matching xmPerson.');

        XMPersonWrapper personWrapper = testController.person;
        system.assertNotEquals( null, personWrapper, 'xMatters should return an XM Person.');

        test.stopTest();

    }

    static testMethod void testContactWithDuplicates() {

        Account testAccount = createAccount();

        xmPerson__c person = new xmPerson__c(
                xmPersonUID__c = 'aefgh-1234-cdeft'
        );
        insert person;

        Map<String, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact[] contactList = new Contact[]{};
        Contact testContact = new Contact(
                FirstName = 'XMPersonManagementControllerTest',
                LastName = 'Contact',
                Email = 'contact1@incontact.com',
                RecordTypeId = recordTypeMap.get(CUSTOMER_CONTACT).getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = person.Id
        );
        contactList.add(testContact);

        Contact testDuplicateContact = new Contact(
                FirstName = 'XMPersonManagementControllerTest',
                LastName = 'Duplicate',
                Email = 'contact1@incontact.com',
                RecordTypeId = recordTypeMap.get(CUSTOMER_CONTACT).getRecordTypeId(),
                AccountId = testAccount.Id
        );
        contactList.add(testDuplicateContact);

        insert contactList;

        test.startTest();

        XMRestPeopleMockHttpGenerator xmPersonMock = new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Name": "XMPersonManagementControllerTest"}]',null);
        Test.setMock(HttpCalloutMock.class, xmPersonMock);

        XMPersonManagementController testController = new XMPersonManagementController(new ApexPages.StandardController(testDuplicateContact));
        system.assertEquals( false, testController.getIsXmPerson(), 'Contact should have an xmPerson.');
        system.assertEquals( true, testController.getIsDuplicate(), 'Contact should have a duplicate.');
        system.assertEquals( true, testController.isPersonMatch, 'Contact should have a matching xmPerson.');

        XMPersonWrapper personWrapper = testController.person;
        system.assertNotEquals( null, personWrapper, 'xMatters should return an XM Person.');

        testController.associateContact();

        testDuplicateContact = [Select xmPerson__c from Contact where Id = :testDuplicateContact.Id];
        system.assertEquals( person.Id, testDuplicateContact.xmPerson__c, 'Contact record should be associated with XmPerson.');

        test.stopTest();

    }



    static Account createAccount(){

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();

        Account testAccount = new Account(
                Name = 'XMPersonManagementControllerTest Account',
                Type = 'Customer',
                CadebillAccountNo__c = 877124,
                RecordTypeId = accountRecordTypeMap.get(CUSTOMER_ACCOUNT).getRecordTypeId()
        );
        insert testAccount;

        return testAccount;

    }


}