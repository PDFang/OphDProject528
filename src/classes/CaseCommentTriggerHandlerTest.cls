/**
 * Created by mohandaas.rangaswamy on 3/7/2017.
 */

@IsTest
private class CaseCommentTriggerHandlerTest {

    static testMethod void testCallPartnerCaseProxyService() {

        Case testIncident = [Select Id from Case where RecordType.Name = 'Incident' LIMIT 1];

        // Performing DML Before Mock Callouts to avoid uncommitted work pending error
        CaseComment newComment = new CaseComment(
                ParentId = testIncident.Id,
                commentBody = 'New comment added',
                isPublished = true
        );
        insert newComment;

        test.startTest();
        Test.setMock(WebServiceMock.class, new PartnerCaseProxyServiceMockTest());
        test.stopTest();
        // make sure the trigger makes a callout to proxy service
        system.assertEquals(true, PartnerCaseProxyServiceHelper.isCaseCommentPushed);

    } // end of testCallPartnerCaseProxyService()

    @IsTest static void testSendBulkComments() {

        Case testIncident = [Select Id, ParentId from Case where RecordType.Name = 'Incident' LIMIT 1];
        // create an event
        Case testEvent = [Select Id from Case where RecordType.Name = 'Event' LIMIT 1];

        testIncident.ParentId = testEvent.Id;
        update testIncident;

        // Performing DML Before Mock Callouts to avoid uncommitted work pending error
        CaseComment testEventComment = new CaseComment(
                ParentId = testEvent.Id,
                commentBody = 'New comment added',
                isPublished = true
        );

        insert testEventComment;

        test.startTest();

        Test.setMock(WebServiceMock.class, new PartnerCaseProxyServiceMockTest());
        test.stopTest();
        // make sure the trigger makes a callout to proxy service
        system.assertEquals(true, PartnerCaseProxyServiceHelper.isCaseCommentPushed);

    } // end of testCallPartnerCaseProxyService()

    // test XMNotification record is created when a public comment is added
    static testMethod void testPublicCommentNotification() {

        // create an event
        Case testEvent = [Select Id from Case where RecordType.Name = 'Event' LIMIT 1];

        // confirm event
        testEvent.status = 'Confirmed';
        testEvent.InternalEvent__c = false;
        testEvent.IgnoreEventStatusLock__c = true;
        update testEvent;

        test.startTest();

        CaseComment newComment = new CaseComment(
                ParentId = testEvent.Id,
                commentBody = 'New comment added',
                isPublished = true
        );

        insert newComment;

        test.stopTest();

        xmNotification__c[] notifications = [
                Select Request_Type__c, Public_Comment__c
                from xmNotification__c
                where Case__c = :testEvent.Id
                and Request_Type__c = :XMNotificationTriggerHandler.REQUEST_TYPE_COMMENT
        ];

        system.assertEquals(1, notifications.size(), 'One xmNotification record should be created.');
        system.assertEquals(newComment.CommentBody, notifications[0].Public_Comment__c);

    }

    @TestSetup
    private static void createTestData(){

        ETMS_Codes__c etmsCode = new ETMS_Codes__c(
                Name = 'Test ETMS',
                Request_Type__c = 'WFO',
                Reason__c = 'WFO Issue',
                Reason_Detail__c = 'Scheduling Issues',
                ETMS_Trouble_Type__c = '0010',
                ETMS_Trouble_Type_Description__c = 'Unit Test'
        );
        insert etmsCode;

        SiteConfiguration__c siteConfig = new SiteConfiguration__c();
        siteConfig.Name = inContactBaseClass.OrgId15Digit; //UserInfo.getOrganizationId();
        siteConfig.AutoEventEmails__c = false;
        siteConfig.DaysToDisplayKnownIssues__c = 30;
        siteConfig.OrgId__c =  inContactBaseClass.OrgId15Digit; //UserInfo.getOrganizationId();
        siteConfig.EventResolvedPriorities__c = 'P1;P2;';
        siteConfig.EventResolvedEmails__c = false;

        insert siteConfig;


        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account verizonAccount = new Account(
                Name = 'Verizon Test Account',
                Billing_Group__c = PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON,
                Type = 'Partner',
                RecordTypeId = accountRecordTypeMap.get('Partners').getRecordTypeId()
        );

        insert verizonAccount;

        Map<String,Schema.RecordTypeInfo> contactRecordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact verizonContact = new Contact(
                LastName = 'Test Contact',
                FirstName = 'Verizon',
                Email = 'contact1@test.com',
                RecordTypeId = contactRecordTypeMap.get('Partner Contact').getRecordTypeId(),
                AccountId = verizonAccount.Id
        );

        insert verizonContact;

        Case[] cases = new Case[]{};

        // create an incident
        Map<String,Schema.RecordTypeInfo> caseRecordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testIncident = new Case(
                RecordTypeId = caseRecordTypeMap.get('Incident').getRecordTypeId(),
                Subject = 'Verizon Test',
                Status = 'New',
                AccountId = verizonAccount.Id,
                ContactId = verizonContact.Id,
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = etmsCode.Request_Type__c,
                Database__c = etmsCode.Reason__c,
                Releases__c = etmsCode.Reason_Detail__c,
                X3rdPartyVendorTicket__c = '20170307'
        );
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        testIncident.setOptions(dmo);
        cases.add(testIncident);

        Case testEvent = new Case(
                RecordTypeId = caseRecordTypeMap.get('Event').getRecordTypeId(),
                Subject = 'testPublicCommentNotification Event',
                Description = 'testPublicCommentNotification',
                Status = 'New',
                EventType__c = 'Service Disruption',
                PlatformsImpacted__c = 'C6 - inContact',
                ProductImpacted__c = 'Test Product',
                InternalEvent__c = false,
                Priority = 'P1'
        );

        dmo.assignmentRuleHeader.useDefaultRule = true;
        testEvent.setOptions(dmo);
        cases.add(testEvent);

        insert cases;

    } // createTestData()

}