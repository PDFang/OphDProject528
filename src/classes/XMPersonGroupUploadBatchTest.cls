/**
 * Created by ravish.chawla on 8/17/2017.
 */

@IsTest
private class XMPersonGroupUploadBatchTest {

    static Account testAccount;
    static final String CUSTOMER_ACCOUNT = 'Customers';
    static final String CUSTOMER_CONTACT = 'Customer-Other';

    static xmGroupChangeRequest__c groupChangeRequest;

    static testMethod void xmPersonGroupUploadBatchTest() {

        createAccount();

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);


        setUp();

        test.startTest();

        database.executeBatch(new XMPersonGroupUploadBatch());

        test.stopTest();

        List<xmGroupChangeRequest__c> dataList = [select Id, Account__c, Status__c from xmGroupChangeRequest__c limit 5];
        System.debug('dataList' + dataList);
        system.assertNotEquals(0, dataList.size());
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
                xmPerson__c = person.Id,
                Contact_Role__c = 'Event Notification'
        );

        insert testContact;


        Contact testContact1 = new Contact(
                FirstName = 'xmDeviceNewTest',
                LastName = 'Contact1',
                Email = 'contact1@incontact.com',
                RecordTypeId = recordTypeMap.get(CUSTOMER_CONTACT).getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = person.Id,
                Contact_Role__c = 'Maintenance Notification'
        );

        insert testContact1;

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

//        groupChangeRequest = new xmGroupChangeRequest__c();
//        groupChangeRequest.Account__c = testAccount.Id;
//        groupChangeRequest.Action__c = 'Add';
//        groupChangeRequest.Device_Type__c = 'Work Email';
//        groupChangeRequest.ImplementedProduct__c = ip1.Id;
//        groupChangeRequest.Maintenance__c = true;
//        groupChangeRequest.NotificationProfile__c = person.Id;
//        groupChangeRequest.xMDeviceId__c = 'cdcebcb4-8601-4dc7-b9cd-6a521914f37d';
//
//        insert groupChangeRequest;

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