@IsTest
private class XMPersonManagementControllerTest {

    static final String CUSTOMER_ACCOUNT = 'Customers';
    static final String CUSTOMER_CONTACT = 'Customer-Other';

    static Account testAccount;
    static xmGroupChangeRequest__c groupChangeRequest;

    static testMethod void testContactNoXmPerson() {

        createAccount();

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

        createAccount();

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
        system.assertEquals( true, testController.getIsValidContact(), 'Contact should be found.');
        system.assertEquals( true, testController.getIsXmPerson(), 'Contact should have an xmPerson.');
        system.assertEquals( false, testController.getIsDuplicate(), 'Contact should not have any duplicates.');
        system.assertEquals( false, testController.isPersonMatch, 'Contact should not have a matching xmPerson.');

        XMPersonWrapper personWrapper = testController.person;
        system.assertNotEquals( null, personWrapper, 'xMatters should return an XM Person.');

        testController.getTimezone();
        testController.getTimezoneDisplayName();

        test.stopTest();

    }

    static testMethod void testContactWithDuplicates() {

        createAccount();

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
        system.assertEquals( false, testController.getIsXmPerson(), 'Contact should not have an xmPerson.');
        system.assertEquals( true, testController.getIsDuplicate(), 'Contact should have a duplicate.');
        system.assertEquals( true, testController.isPersonMatch, 'Contact should have a matching xmPerson.');

        XMPersonWrapper personWrapper = testController.person;
        system.assertNotEquals( null, personWrapper, 'xMatters should return an XM Person.');

        Test.setCurrentPageReference(new PageReference('Page.XMPersonManagement'));
        ApexPages.currentPage().getParameters().put('rowId',testDuplicateContact.Id );
        testController.associateContact();

        testDuplicateContact = [Select xmPerson__c from Contact where Id = :testDuplicateContact.Id];
        system.assertEquals( person.Id, testDuplicateContact.xmPerson__c, 'Contact record should be associated with XmPerson.');

        test.stopTest();

    }

    // remove associateion
    static testMethod void testContactDissociation() {

        createAccount();

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

       insert contactList;

        test.startTest();

        XMRestPeopleMockHttpGenerator xmPersonMock = new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Name": "XMPersonManagementControllerTest"}]',null);
        Test.setMock(HttpCalloutMock.class, xmPersonMock);

        XMPersonManagementController testController = new XMPersonManagementController(new ApexPages.StandardController(contactList[0]));
        system.assertEquals( true, testController.getIsXmPerson(), 'Contact should have an xmPerson.');
        system.assertEquals( false, testController.isPersonMatch, 'Contact should not have a matching xmPerson.');

        XMPersonWrapper personWrapper = testController.person;
        system.assertNotEquals( null, personWrapper, 'xMatters should return an XM Person.');

        Test.setCurrentPageReference(new PageReference('Page.XMPersonManagement'));
        ApexPages.currentPage().getParameters().put('removeId',contactList[0].id );
        testController.dissociateContact();

        testContact = [Select xmPerson__c from Contact where Id = :testContact.Id];
        system.assertNotEquals( person.Id, testContact.xmPerson__c, 'Contact record should not be associated with XmPerson.');

        test.stopTest();

    }


    static testmethod void testDeviceCrud(){

        createAccount();

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

        XmTimezones__c mountainTimezone = new XmTimezones__c(
                Name = 'US/Mountain',
                Location__c = 'America/Denver'
        );
        insert mountainTimezone;

        XMRestDeviceServiceMock httpMockCallout = new XMRestDeviceServiceMock(200,'Complete','[{"Name": "sForceTest1"}]',null);
        Test.setMock(HttpCalloutMock.class, httpMockCallout);

        test.startTest();

        String devices = XMPersonManagementController.getUserDevices(testContact.Id);
        system.assert(devices.length() > 0, 'Should return one or more devices.');

        string addResult = XMPersonManagementController.addNewDevice(testContact.Id, 'Work Email', testContact.Email);
        system.assert(addResult.containsIgnoreCase('Success'), 'Should have added a new device.'+addResult);

        String deviceJson = '{"name":"Work Email","deviceValue":"testcontact@in.com","priorityThreshold":"Medium","deviceId":"59ac4f15-a7d0-44b0-9be4-007be83ebc18","timeframes":[{"timezone":"US/Mountain","startTime":"12:00 AM","name":"24x7","endTime":"12:00 AM","days":{"wednesday":true,"tuesday":true,"thursday":true,"sunday":true,"saturday":true,"monday":true,"friday":true}}]}';
        string updateResult = XMPersonManagementController.updateDevice(deviceJson);
        system.assert(updateResult.containsIgnoreCase('Success'), 'Should have updated the device.'+updateResult);

        string deleteResult = XMPersonManagementController.deleteDevice('59ac4f15-a7d0-44b0-9be4-007be83ebc18');
        system.assert(deleteResult.containsIgnoreCase('Success'), 'Should have deleted the device.');

        test.stopTest();

    }

    static testmethod void testProductGroups(){

        createAccount();
        createImplementedProduct();

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

        XMRestGroupMockHttpGenerator xmGroupMock = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        Test.setMock(HttpCalloutMock.class, xmGroupMock);

        string productGroups = XMPersonManagementController.getProductGroups(testContact.Id, 'MaintType');
        string productGroups1 = XMPersonManagementController.getProductGroups(testContact.Id, null);

        System.debug('productGroups -->' + ':' + productGroups);
        System.debug('productGroups1 -->' + ':' + productGroups1);

        XMGroupProductCluster[] xmGroupList = (XMGroupProductCluster[])JSON.deserialize(productGroups, List<XMGroupProductCluster>.class);
        XMGroupProductCluster[] xmGroupList1 = (XMGroupProductCluster[])JSON.deserialize(productGroups1, List<XMGroupProductCluster>.class);
        system.assertNotEquals(0, xmGroupList.size());
        system.assertNotEquals(0, xmGroupList1.size());

        xmGroupList[0].selected = true;
        xmGroupList1[0].selected = true;

        xmGroupList[0].Devices = new List<xmPersonMemberModel>();
        xmGroupList1[0].Devices = new List<xmPersonMemberModel>();
        xmPersonMemberModel testObj = new xmPersonMemberModel();
        testObj.id = 'cdcebcb4-8601-4dc7-b9cd-6a521914f37d';
        testObj.checked = true;
        testObj.targetName = 'Test01';

        xmPersonMemberModel testObj1 = new xmPersonMemberModel();
        testObj1.id = 'cdcebcb4-8601-4dc7-b9cd-6a521914f37d';
        testObj1.checked = false;
        testObj1.targetName = 'Test01';

        xmGroupList[0].Devices.add(testObj);
        xmGroupList1[0].Devices.add(testObj1);

        string result1 = XMPersonManagementController.updateGroupSubscription( JSON.Serialize(xmGroupList1), testContact.Id, null);
        string result = XMPersonManagementController.updateGroupSubscription( JSON.Serialize(xmGroupList), testContact.Id, 'MaintType');

        system.assertNotEquals(null, result);
        system.assertNotEquals(null, result1);

        system.assertNotEquals(0, xmGroupList.size());
        system.assertNotEquals(0, xmGroupList1.size());

        test.stopTest();


    }

    static testmethod void testGetProductGroups(){

        createAccount();
        createImplementedProduct();

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

        groupChangeRequest.NotificationProfile__c = person.Id;
        update  groupChangeRequest;

        test.startTest();

        XMRestGroupMockHttpGenerator xmGroupMock = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        Test.setMock(HttpCalloutMock.class, xmGroupMock);

        string productGroups = XMPersonManagementController.getProductGroups(testContact.Id, 'MaintType');
        string productGroups1 = XMPersonManagementController.getProductGroups(testContact.Id, null);

        XMGroupProductCluster[] xmGroupList = (XMGroupProductCluster[])JSON.deserialize(productGroups, List<XMGroupProductCluster>.class);
        XMGroupProductCluster[] xmGroupList1 = (XMGroupProductCluster[])JSON.deserialize(productGroups1, List<XMGroupProductCluster>.class);
        system.assertNotEquals(0, xmGroupList.size());
        system.assertNotEquals(0, xmGroupList1.size());

        test.stopTest();


    }

    static void createAccount(){

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();

        testAccount = new Account(
                Name = 'XMPersonManagementControllerTest Account',
                Type = 'Customer',
                CadebillAccountNo__c = 877124,
                RecordTypeId = accountRecordTypeMap.get(CUSTOMER_ACCOUNT).getRecordTypeId(),
                Cluster__c = 'C3'
        );
        insert testAccount;

    }

    static void createImplementedProduct(){

        Map<String, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = recordTypeMap.get('New Opportunity').getRecordTypeId();
        opp.Name = 'test';
        opp.CloseDate = system.today().addDays(30);
        opp.StageName = 'Open';
        opp.AccountId = testAccount.Id;

        insert opp;

        ImplementedProduct__c ip = new ImplementedProduct__c();
        ip.Account__c = testAccount.Id;
        ip.GoLiveDate__c = system.today() - 1;
        ip.Status__c = 'Implemented';
        ip.Product__c = 'inContact';
        ip.Opportunity__c = opp.Id;
        insert ip;

        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'inContact';
        pem.Product__c = 'inContact';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

        groupChangeRequest = new xmGroupChangeRequest__c();
        groupChangeRequest.Account__c = testAccount.Id;
        groupChangeRequest.Action__c = 'Add';
        groupChangeRequest.Device_Type__c = 'Work Email';
        groupChangeRequest.ImplementedProduct__c = ip.Id;
        groupChangeRequest.Maintenance__c = true;
        insert groupChangeRequest;

    }


}