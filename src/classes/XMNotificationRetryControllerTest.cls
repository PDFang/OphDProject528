/**
 * Created by mohandaas.rangaswamy on 7/10/2017.
 */

@IsTest
private class XMNotificationRetryControllerTest {

    static testMethod void testWithoutCaseIdParameter() {

        Test.startTest();

        Test.setCurrentPage(Page.XMNotificationRetry);
        ApexPages.currentPage().getParameters().put('caseId', null);

        XMNotificationRetryController controller = new XMNotificationRetryController();

        ApexPages.hasMessages(ApexPages.Severity.ERROR);

        Test.stopTest();

    }

    static testMethod void testInvalidCaseId() {

        Test.startTest();

        Test.setCurrentPage(Page.XMNotificationRetry);
        ApexPages.currentPage().getParameters().put('caseId', '005');

        XMNotificationRetryController controller = new XMNotificationRetryController();

        ApexPages.hasMessages(ApexPages.Severity.ERROR);

        Test.stopTest();

    }

    static testMethod void testWithNoFailedNotifications() {

        Case testEvent = createEvent();

        xmNotification__c testNotification = createNotification(testEvent, 'Completed');

        Test.startTest();

        Test.setCurrentPage(Page.XMNotificationRetry);
        ApexPages.currentPage().getParameters().put('caseId', testEvent.Id);

        XMNotificationRetryController controller = new XMNotificationRetryController();

        ApexPages.hasMessages(ApexPages.Severity.INFO);

        Test.stopTest();

    }

    static Case createEvent(){

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