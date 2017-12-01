/**
 * Created by mohandaas.rangaswamy on 7/10/2017.
 */

@IsTest
private class XMNotificationRetryControllerTest {

    static testMethod void testWithoutCaseIdParameter() {

        Test.startTest();

        Test.setCurrentPage(Page.XMNotificationRetry);
        ApexPages.currentPage().getParameters().put('caseId', null);

        Case c = new Case();
        XMNotificationRetryController controller = new XMNotificationRetryController(new ApexPages.StandardController(c));

        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Should error if Case ID is missing in the URL.');

        Test.stopTest();

    }

    static testMethod void testInvalidCaseId() {

        Test.startTest();

        Test.setCurrentPage(Page.XMNotificationRetry);
        ApexPages.currentPage().getParameters().put('caseId', '005');

        Case c = new Case();
        XMNotificationRetryController controller = new XMNotificationRetryController(new ApexPages.StandardController(c));

        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Should error if Case details could not be retrieved.');

        Test.stopTest();

    }

    static testMethod void testWithNoFailedNotifications() {

        Case testEvent = createEvent();

        xmNotification__c testNotification = createNotification(testEvent, 'Completed');

        Test.startTest();

        Test.setCurrentPage(Page.XMNotificationRetry);
        ApexPages.currentPage().getParameters().put('caseId', testEvent.Id);

        XMNotificationRetryController controller = new XMNotificationRetryController(new ApexPages.StandardController(testEvent));

        system.assert(ApexPages.hasMessages(ApexPages.Severity.INFO), 'Should alert if there are no failed notifications.');

        Test.stopTest();

    }

    static testMethod void testRetryNotifications() {

        Case testEvent = createEvent();

        xmNotification__c testNotification = createNotification(testEvent, 'Failed');

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new XMRestEventServiceHttpMock(200,'Complete','[{"Name": "sForceTest1"}]',null));

        Test.setCurrentPage(Page.XMNotificationRetry);
        ApexPages.currentPage().getParameters().put('caseId', testEvent.Id);

        XMNotificationRetryController controller = new XMNotificationRetryController(new ApexPages.StandardController(testEvent));

        system.assertEquals(1, controller.notificationList.size(), 'Failed notification record was not retrieved.');

        controller.retry();
        system.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Should error if no notification is selected.');

        ApexPages.currentPage().getParameters().put('notificationId', testNotification.Id);

        controller.retry();
        controller.cancel();

        Test.stopTest();

        xmNotification__c[] newNotifications = [
                Select Id, Request_Type__c, Case__c, Related_Notification__r.Status__c
                from xmNotification__c
                where Related_Notification__c = :testNotification.Id
        ];

        system.assertEquals(1, newNotifications.size(), 'Should create a new notification on retry.');
        system.assertEquals(testNotification.Request_Type__c, newNotifications[0].Request_Type__c);
        system.assertEquals(testNotification.Case__c, newNotifications[0].Case__c);
        system.assertEquals('Retried', newNotifications[0].Related_Notification__r.Status__c);

    }


    static Case createEvent(){

        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'Test Product';
        pem.Product__c = 'Test Product';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;
        insert pem;

        SiteConfiguration__c siteConfig = new SiteConfiguration__c();
        siteConfig.Name = inContactBaseClass.OrgId15Digit; //UserInfo.getOrganizationId();
        siteConfig.AutoEventEmails__c = false;
        siteConfig.DaysToDisplayKnownIssues__c = 30;
        siteConfig.OrgId__c =  inContactBaseClass.OrgId15Digit; //UserInfo.getOrganizationId();
        siteConfig.EventResolvedPriorities__c = 'P1;P2;';
        siteConfig.EventResolvedEmails__c = false;

        insert siteConfig;

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

        return testEvent;

    }

    static xmNotification__c createNotification(Case testEvent, String status){

        xmNotification__c xmNotification = new xmNotification__c(
                Case__c = testEvent.Id,
                Request_Date__c = system.now(),
                Request_Type__c = 'Event Initial Confirmation',
                Status__c = status
        );
        insert xmNotification;

        return xmNotification;
    }


}