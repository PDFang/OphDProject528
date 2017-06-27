@isTest
Private class XMattersDeliveryWebServiceTest {

    static testMethod void testDeliveryNotification(){

        Test.setMock(HttpCalloutMock.class, new XMRestEventServiceHttpMock(200,'Complete','[{"Name": "sForceTest1"}]',null));

        createTestData();

        xmNotification__c[] notifications = [Select Id from xmNotification__c limit 1];

        xmPerson__c[] persons = [Select Id, xmPersonUID__c from xmPerson__c limit 1];

        test.starttest();

        RestRequest testRequest = new RestRequest();
        testRequest.addHeader('Content-Type', 'application/json');

        testRequest.httpMethod = 'POST';
        testRequest.requestURI = '/services/apexrest/DeliveryNotification';
        String requestJson = '{"deliveryReceipt":{"XMPersonId":"cd874706-1b8e-49e6-aad4-2c9b38f12e3e","XMNotificationId":"aFp3C000000GmiwSAC","Status":"Delivered","DeviceType":"Work Email","DeliveryDate":"26-06-19 20:34:59.625","Device":"testuser@incontact.com"}}';
        testRequest.requestBody = Blob.valueOf(requestJson);

        RestResponse testResponse = new RestResponse();
        RestContext.Request = testRequest;
        RestContext.Response = testResponse;

        XMDeliveryReceipt receipt = new XMDeliveryReceipt();
        receipt.XMNotificationId = notifications[0].Id;
        receipt.XMPersonId = persons[0].xmPersonUID__c;
        receipt.Status = 'Delivered';
        receipt.DeliveryDate = '26-06-19 20:34:59.625';
        receipt.DeviceType = 'Work Email';
        receipt.Device = 'testuser@incontact.com';
        receipt.Message = '';

        XMattersDeliveryWebService.DeliveryNotification(receipt);

        test.stopTest();

        xmDelivery__c[] deliveryList = [Select Id from xmDelivery__c where XMNotification__c = :notifications[0].Id];

        system.assert(deliveryList.size() > 0, 'Should create a delivery.');

    }

    static void createTestData(){

        SiteConfiguration__c siteConfig = new SiteConfiguration__c();
        siteConfig.Name = inContactBaseClass.OrgId15Digit; //UserInfo.getOrganizationId();
        siteConfig.AutoEventEmails__c = false;
        siteConfig.DaysToDisplayKnownIssues__c = 30;
        siteConfig.OrgId__c =  inContactBaseClass.OrgId15Digit; //UserInfo.getOrganizationId();
        siteConfig.EventResolvedPriorities__c = 'P1;P2;';
        siteConfig.EventResolvedEmails__c = false;

        insert siteConfig;

        ProductEventMap__c testProduct = new ProductEventMap__c();
        testProduct.Name = 'Test Product';
        testProduct.Product__c = 'Test Product';
        testProduct.ImplementedProduct__c = 'Test Product';
        testProduct.Platform__c = 'Cluster - inContact';
        testProduct.HasClusters__c = false;

        insert testProduct;


        Map<String,Schema.RecordTypeInfo> testIncidentTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testEvent = new Case(
                RecordTypeId = testIncidentTypeMap.get('Event').getRecordTypeId(),
                Subject = 'testEventInitialConfirmationNotification Event',
                Description = 'testEventInitialConfirmationNotification',
                Status = 'New',
                EventType__c = 'Service Disruption',
                PlatformsImpacted__c = 'C6 - inContact',
                ProductImpacted__c = 'Test Product',
                InternalEvent__c = false,
                Priority = 'P1'
        );

        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        testEvent.setOptions(dmo);

        insert testEvent;

        xmPerson__c person = new xmPerson__c(
                xmPersonUID__c = 'aefgh-1234-cdeft'
        );
        insert person;

        xmNotification__c xmNotification = new xmNotification__c(
                Case__c = testEvent.Id,
                Request_Date__c = system.now(),
                Request_Type__c = 'Event Initial Confirmation'
        );
        insert xmNotification;
    }

}