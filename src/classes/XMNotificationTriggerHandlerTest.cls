/**
 * Created by mohandaas.rangaswamy on 6/1/2017.
 */

@IsTest
private class XMNotificationTriggerHandlerTest {

    // test callout to xMatters event service for sending Event Notification
    static testMethod void testCalloutSuccess() {

        Case testEvent =[Select Id from Case where RecordType.Name = 'Event' Limit 1];

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new XMRestEventServiceHttpMock(200,'Complete','[{"Name": "sForceTest1"}]',null));

        xmNotification__c xmNotification = new xmNotification__c(
                Case__c = testEvent.Id,
                Request_Date__c = system.now(),
                Request_Type__c = 'Event Initial Confirmation',
                Status__c = 'New'
        );
        insert xmNotification;

        test.stopTest();

        xmNotification = [Select Id, Status__c from xmNotification__c where Id = :xmNotification.Id];

        system.assertEquals('Processed', xmNotification.Status__c, 'xmNotification status update failed.');

        xmNotification.Status__c = 'Completed';
        update xmNotification;

        system.assertEquals(true, [Select xmEvent_Notification_Sent__c from Case Where Id = :testEvent.Id].xmEvent_Notification_Sent__c, 'xmEvent Notification Sent flag not set to true.' );


    }

    // test callout to xMatters event service for sending Maintenance Notification
    static testMethod void testMaintenanceNotification() {

        Case testMaintenance =[Select Id from Case where RecordType.Name = 'Maintenance Notification' Limit 1];

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new XMRestEventServiceHttpMock(200,'Complete','[{"Name": "sForceTest1"}]',null));

        xmNotification__c xmNotification = new xmNotification__c(
                Case__c = testMaintenance.Id,
                Request_Date__c = system.now(),
                Request_Type__c = 'Maintenance Notification',
                Status__c = 'New'
        );
        insert xmNotification;

        test.stopTest();

        xmNotification = [Select Id, Status__c from xmNotification__c where Id = :xmNotification.Id];

        system.assertEquals('Processed', xmNotification.Status__c, 'xmNotification status update failed.');

        xmNotification.Status__c = 'Completed';
        update xmNotification;

        system.assertEquals('Notification Sent', [Select Status from Case Where Id = :testMaintenance.Id].Status, 'Maintenance Notification status update failed.' );
    }

    // test callout to xMatters event service
    static testMethod void testCalloutError() {

        Case testEvent =[Select Id from Case where RecordType.Name = 'Event' Limit 1];

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new XMRestEventServiceHttpMock(500,'Complete','[{"Name": "sForceTest1"}]',null));

        xmNotification__c xmNotification = new xmNotification__c(
                Case__c = testEvent.Id,
                Request_Date__c = system.now(),
                Request_Type__c = 'Event Initial Confirmation',
                Status__c = 'New'
        );
        insert xmNotification;

        test.stopTest();

        xmNotification = [Select Id, Status__c from xmNotification__c where Id = :xmNotification.Id];

        system.assertEquals('Failed', xmNotification.Status__c, 'xmNotification status update failed.');

    }


    @TestSetup
    static void createTestData(){

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

        AppConfiguration__c config = new AppConfiguration__c();
        insert config; // take default values

        Case[] cases = new Case[]{};

        Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testEvent = new Case(
                RecordTypeId = recordTypeMap.get('Event').getRecordTypeId(),
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
        cases.add(testEvent);

        Case testMaintenance = new Case(
                RecordTypeId = recordTypeMap.get('Maintenance Notification').getRecordTypeId(),
                Subject = 'Test Maintenance Notification',
                Description = 'Test Maintenance Notification',
                Status = 'New',
                EventType__c = 'Service Disruption',
                PlatformsImpacted__c = 'C6 - inContact',
                ProductImpacted__c = 'Test Product',
                InternalEvent__c = false,
                Priority = 'P1'
        );
        testMaintenance.setOptions(dmo);
        cases.add(testMaintenance);

        insert cases;

    }

}