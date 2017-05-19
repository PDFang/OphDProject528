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

        test.stopTest();

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
        XMPersonManagementController testController = new XMPersonManagementController(new ApexPages.StandardController(testContact));
        system.assertEquals( true, testController.getIsXmPerson(), 'Contact should have an xmPerson.');
        system.assertEquals( false, testController.getIsDuplicate(), 'Contact should not have any duplicates.');
        system.assertEquals( false, testController.isPersonMatch, 'Contact should not have a matching xmPerson.');

        XMPersonWrapper personWrapper = testController.person;
        system.assertNotEquals( null, personWrapper, 'xMatters should return an XM Person.');

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