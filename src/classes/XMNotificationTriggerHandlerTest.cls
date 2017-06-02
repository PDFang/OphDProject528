/**
 * Created by mohandaas.rangaswamy on 6/1/2017.
 */

@IsTest
private class XMNotificationTriggerHandlerTest {

    // test callout to xMatters event service
    static testMethod void testBehavior() {
        
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

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new XMRestEventServiceHttpMock(200,'Complete','[{"Name": "sForceTest1"}]',null));

        xmNotification__c xmNotification = new xmNotification__c(
                Case__c = testEvent.Id,
                Request_Date__c = system.now(),
                Request_Type__c = 'Event Initial Confirmation'
        );
        insert xmNotification;

        test.stopTest();

        xmNotification = [Select Id, Status__c from xmNotification__c where Id = :xmNotification.Id];

        system.assertEquals('Processed', xmNotification.Status__c, 'xmNotification event service request failed.');

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

    }

}