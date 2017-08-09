/**
 * Created by ravish.chawla on 7/13/2017.
 */

@IsTest
private class ImplementedProductTriggerHandlerTest {
    static Account testAccount;
    static final String CUSTOMER_ACCOUNT = 'Customers';
    static final String CUSTOMER_CONTACT = 'Customer-Other';

    static testMethod void xmDeviceRemoveTest() {

        createAccount();

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        setUp();
        test.startTest();

        ImplementedProduct__c ip1 = [select Id, Status__c, DeactivatedDate__c from ImplementedProduct__c ];
        ip1.Status__c = 'Deactivated';
        ip1.DeactivatedDate__c = System.today();
        update ip1;

        test.stopTest();

        xmGroupChangeRequestHeader__c header = [select Id, Account__c from xmGroupChangeRequestHeader__c limit 1];
        xmGroupChangeRequest__c request = [select Id, Account__c from xmGroupChangeRequest__c limit 1];

        system.assertEquals(testAccount.Id, header.Account__c);
        system.assertEquals(testAccount.Id, request.Account__c);

        System.debug('header.Account__c =>' + header.Account__c);
        System.debug('request.Account__c =>' + request.Account__c);

    }


    static testMethod void xMGroupRequestHelperUpdateTest() {

        createAccount();

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);


        setUp();
        test.startTest();

        ImplementedProduct__c ip1 = [select Id, Status__c, DeactivatedDate__c from ImplementedProduct__c ];
        ip1.Status__c = 'Deactivated';
        ip1.DeactivatedDate__c = System.today();
        update ip1;

        xmGroupChangeRequestHeader__c header = [select Id, Account__c, Retry__c from xmGroupChangeRequestHeader__c limit 1];
        System.debug('header.Retry__c => ' + header.Retry__c);
        header.Retry__c = true;
        System.debug('header.Retry__c => ' + header.Retry__c);

        update header;

        test.stopTest();

        xmGroupChangeRequestHeader__c header1 = [select Id, Account__c from xmGroupChangeRequestHeader__c limit 1];
        xmGroupChangeRequest__c request = [select Id, Account__c from xmGroupChangeRequest__c limit 1];

        system.assertEquals(testAccount.Id, header1.Account__c);
        system.assertEquals(testAccount.Id, request.Account__c);

        System.debug('header.Account__c =>' + header1.Account__c);
        System.debug('request.Account__c =>' + request.Account__c);

    }


    static testMethod void xmGroupChangeRequestBatchTest() {

        createAccount();

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);


        setUp();

        test.startTest();



        ImplementedProduct__c ip1 = [select Id, Status__c, DeactivatedDate__c from ImplementedProduct__c ];
        ip1.Status__c = 'Deactivated';
        ip1.DeactivatedDate__c = System.today();
        update ip1;
        database.executeBatch(new xmGroupChangeRequestBatch());

        test.stopTest();

        xmGroupChangeRequest__c request = [select Id, Account__c, Status__c from xmGroupChangeRequest__c limit 1];
        system.assertEquals('Processed', request.Status__c);

        System.debug('request.Status__c =>' + request.Status__c);

    }


    static testMethod void xmGroupChangeRequestschedulerTest() {

        createAccount();

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        setUp();
        test.startTest();

        ImplementedProduct__c ip1 = [select Id, Status__c, DeactivatedDate__c from ImplementedProduct__c ];
        ip1.Status__c = 'Deactivated';
        ip1.DeactivatedDate__c = System.today();
        update ip1;
        xmGroupChangeRequestScheduler sh1 = new xmGroupChangeRequestScheduler();
        String sch = '0  00 1 3 * ?';
        system.schedule('Test', sch, sh1);
        test.stopTest();

        xmGroupChangeRequest__c request = [select Id, Account__c, Status__c from xmGroupChangeRequest__c limit 1];
        system.assertEquals('Processed', request.Status__c);

        System.debug('request.Status__c =>' + request.Status__c);

    }

    static void setUp(){

        xmPerson__c person = new xmPerson__c(
                xmPersonUID__c = 'aefgh-1234-cdeft'
        );
        insert person;

        Map<String, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact testContact = new Contact(
                FirstName = 'xmDeviceRemoveTest',
                LastName = 'Contact',
                Email = 'contact1@incontact.com',
                RecordTypeId = recordTypeMap.get(CUSTOMER_CONTACT).getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = person.Id
        );

        insert testContact;

        Opportunity o = new Opportunity();
        o.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Historical Products', 'Opportunity');
        o.Name = 'test';
        o.CloseDate = system.today().addDays(30);
        o.StageName = 'Open';
        o.AccountId = testAccount.Id;

        insert o;

        ImplementedProduct__c ip1 = new ImplementedProduct__c();
        ip1.Account__c = testAccount.Id;
        ip1.GoLiveDate__c = system.today() - 1;
        ip1.Status__c = 'Implemented';
        ip1.Product__c = 'inContact';
        ip1.Opportunity__c = o.Id;
        insert ip1;


        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'inContact';
        pem.Product__c = 'inContact';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

    }


    static void createAccount(){

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();

        testAccount = new Account(
                Name = 'xmDeviceRemoveTest Account',
                Type = 'Customer',
                CadebillAccountNo__c = 877124,
                RecordTypeId = accountRecordTypeMap.get(CUSTOMER_ACCOUNT).getRecordTypeId(),
                Cluster__c = 'C3',
                NICE_QM_Cluster__c = 'EN1',
                NICE_WFM_Cluster__c = 'NWFM 1-2',
                Verint_Cluster__c = 'V1',
                inContact_Cluster__c =  'C9'
        );
        insert testAccount;

    }

}