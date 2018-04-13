/**
 * Created by mohandaas.rangaswamy on 2/13/2017.
 */

@IsTest
private class CaseTriggerHandlerTest {

    // test priority, severity assignment
    static testMethod void testIncidentPriorityAssignment(){

        SiteConfiguration__c sbx = new SiteConfiguration__c();
        sbx.Name = inContactBaseClass.OrgId15Digit;
        sbx.AutoEventEmails__c = false;
        sbx.DaysToDisplayKnownIssues__c = 30;
        sbx.OrgId__c = inContactBaseClass.OrgId15Digit;
        sbx.EventResolvedPriorities__c = 'P1;P2;';
        sbx.EventResolvedEmails__c = false;
        insert sbx;

        AppConfiguration__c config = new AppConfiguration__c(
                Turn_Off_Partner_Case_Proxy_Service__c = true,
                XM_Maintenance_Notifications_Internal__c = 'test',
                XM_Event_Notifications_Internal__c = 'test'
        );
        insert config;

        Account testAccount = [Select Id from Account LIMIT 1]; // from setup method
        Contact testContact = [Select Id from Contact where AccountId = :testAccount.Id LIMIT 1]; // from setup method

        // create an incident
        Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case[] caseList = new Case[]{};
        Case testIncident = new Case(
                RecordTypeId = recordTypeMap.get('Incident').getRecordTypeId(),
                Subject = 'testIncidentPriorityAssignment Test',
                Description = 'testIncidentPriorityAssignment Test',
                Status = 'New',
                AccountId = testAccount.Id,
                ContactId = testContact.Id,
                Severity__c = 'S2',
                Related_to_Previous_Known_Issue__c = 'No',
                Security_Issue__c = 'No',
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = 'Dialer'
        );
        caseList.add(testIncident);

        Case testEvent = new Case(
                RecordTypeId = recordTypeMap.get('Event').getRecordTypeId(),
                Subject = 'testIncidentPriorityAssignment Event',
                Description = 'testIncidentPriorityAssignment Event',
                Status = 'New',
                EventType__c = 'Service Disruption',
                PlatformsImpacted__c = 'C6 - inContact',
                ProductImpacted__c = 'ACD',
                InternalEvent__c = true,
                Priority = 'P1'
        );
        caseList.add(testEvent);

        test.startTest();
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        testIncident.setOptions(dmo);
        testEvent.setOptions(dmo);
        insert caseList;
        test.stopTest();

        // verify Priority value is set to match Severity
        Case incident = [Select Priority from Case where Id = :testIncident.Id];
        system.assertEquals(testIncident.Severity__c.replace('S', 'P'), incident.Priority, 'Priority is not assigned correctly.');

        // attach to an event
        testIncident.ParentId = testEvent.Id;
        testIncident.Status = 'Assigned';
        update testIncident;
        // verify incident inherits the Event priority
        incident = [Select Priority from Case where Id = :testIncident.Id];
        system.assertEquals(testEvent.Priority, incident.Priority, 'Incident priority does not match Event priority.');


    }

    // initial score
    static testMethod void testCalculateIncidentNetScore(){

        Account testAccount = [Select Id from Account LIMIT 1]; // from setup method
        Contact testContact = [Select Id from Contact where AccountId = :testAccount.Id LIMIT 1]; // from setup method

        // create an incident
        Map<String,Schema.RecordTypeInfo> testIncidentTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testIncident = new Case(
                RecordTypeId = testIncidentTypeMap.get('Incident').getRecordTypeId(),
                Subject = 'CalculateIncidentNetScore Test',
                Description = 'CalculateIncidentNetScore Test',
                Status = 'New',
                AccountId = testAccount.Id,
                ContactId = testContact.Id,
                Severity__c = 'S2',
                Priority = 'P2',
                Related_to_Previous_Known_Issue__c = 'No',
                Security_Issue__c = 'No',
                RepeatIssue__c = 'Yes',
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = 'Dialer'
        );

        // create impact score multiplier
        IncidentImpactCalculationInterface impactCalculator = new IncidentImpactCalculationImplementation();
        Impact_Score_Multiplier__c[] multipliers = new Impact_Score_Multiplier__c[]{};
        Impact_Score_Multiplier__c severity = new Impact_Score_Multiplier__c(
                Name = 'Severity',
                Multiplier__c = 4.0
        );
        multipliers.add(severity);
        Double severityScore = impactCalculator.CalculateIncidentSeverityScore(testIncident.Severity__c, (Double)severity.Multiplier__c);

        Impact_Score_Multiplier__c incidentPriority = new Impact_Score_Multiplier__c(
                Name = 'Incident Priority',
                Multiplier__c = 4.0
        );
        multipliers.add(incidentPriority);
        Double priorityScore = impactCalculator.CalculateIncidentPriorityScore(testIncident.Priority, (Double)incidentPriority.Multiplier__c);

        Impact_Score_Multiplier__c securityIssue = new Impact_Score_Multiplier__c(
                Name = 'is security issue',
                Multiplier__c = 5.0
        );
        multipliers.add(securityIssue);
        Double securityScore = impactCalculator.CalculateSecurityIssueScore(testIncident.Security_Issue__c, (Double)securityIssue.Multiplier__c);

        Impact_Score_Multiplier__c knownIssue = new Impact_Score_Multiplier__c(
                Name = 'is known issue',
                Multiplier__c = 3.0
        );
        multipliers.add(knownIssue);
        Double knownIssueScore = impactCalculator.CalculateRelatedKnownIssueScore(testIncident.Related_to_Previous_Known_Issue__c, (Double)knownIssue.Multiplier__c);

        Impact_Score_Multiplier__c repeatIssue = new Impact_Score_Multiplier__c(
                Name = 'Repeat Issue',
                Multiplier__c = 4.0
        );
        multipliers.add(repeatIssue);
        Double repeatIssueScore = impactCalculator.CalculateRepeatIssueScore(testIncident.RepeatIssue__c, (Double)repeatIssue.Multiplier__c);

        // expected result
        Double netScore = severityScore + priorityScore + securityScore + knownIssueScore + repeatIssueScore;
        system.debug('CalculateIncidentNetScore(): netScore - ' + netScore);

        insert multipliers;
        test.startTest();
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        testIncident.setOptions(dmo);
        insert testIncident;
        test.stopTest();

        // get actual
        testIncident = [Select Incident_Net_Score__c from Case where Id = :testIncident.Id];
        system.assertEquals(netScore, testIncident.Incident_Net_Score__c, 'Incident net score calculation is incorrect.');


    }

    // score re-calculation
    static testMethod void testIncidentNetScoreRecalculation(){

        Account testAccount = [Select Id from Account LIMIT 1]; // from setup method
        Contact testContact = [Select Id from Contact where AccountId = :testAccount.Id LIMIT 1]; // from setup method

        // create an incident
        Map<String,Schema.RecordTypeInfo> testIncidentTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testIncident = new Case(
                RecordTypeId = testIncidentTypeMap.get('Incident').getRecordTypeId(),
                Subject = 'CalculateIncidentNetScore Test',
                Description = 'CalculateIncidentNetScore Test',
                Status = 'New',
                AccountId = testAccount.Id,
                ContactId = testContact.Id,
                Severity__c = 'S2',
                Priority = 'P2',
                RepeatIssue__c = 'No',
                Related_to_Previous_Known_Issue__c = 'No',
                Security_Issue__c = 'No',
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = 'Dialer'
        );
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        testIncident.setOptions(dmo);
        insert testIncident;

        // update severity, business impacted and security issue
        testIncident = [Select Severity__c, RepeatIssue__c, Priority, Security_Issue__c, Related_to_Previous_Known_Issue__c from Case
                where Id = :testIncident.Id

        ];
        testIncident.Severity__c = 'S1';
        testIncident.Priority = 'P1';
        testIncident.Security_Issue__c = 'Yes';

        // create impact score multiplier
        IncidentImpactCalculationInterface impactCalculator = new IncidentImpactCalculationImplementation();
        Impact_Score_Multiplier__c[] multipliers = new Impact_Score_Multiplier__c[]{};
        Impact_Score_Multiplier__c severity = new Impact_Score_Multiplier__c(
                Name = 'Severity',
                Multiplier__c = 4.0
        );
        multipliers.add(severity);
        Double severityScore = impactCalculator.CalculateIncidentSeverityScore(testIncident.Severity__c, (Double)severity.Multiplier__c);

        Impact_Score_Multiplier__c incidentPriority = new Impact_Score_Multiplier__c(
                Name = 'Incident Priority',
                Multiplier__c = 4.0
        );
        multipliers.add(incidentPriority);
        Double priorityScore = impactCalculator.CalculateIncidentPriorityScore(testIncident.Priority, (Double)incidentPriority.Multiplier__c);

        Impact_Score_Multiplier__c securityIssue = new Impact_Score_Multiplier__c(
                Name = 'is security issue',
                Multiplier__c = 5.0
        );
        multipliers.add(securityIssue);
        Double securityScore = impactCalculator.CalculateSecurityIssueScore(testIncident.Security_Issue__c, (Double)securityIssue.Multiplier__c);

        Impact_Score_Multiplier__c knownIssue = new Impact_Score_Multiplier__c(
                Name = 'is known issue',
                Multiplier__c = 3.0
        );
        multipliers.add(knownIssue);
        Double knownIssueScore = impactCalculator.CalculateRelatedKnownIssueScore(testIncident.Related_to_Previous_Known_Issue__c, (Double)knownIssue.Multiplier__c);

        Impact_Score_Multiplier__c repeatIssue = new Impact_Score_Multiplier__c(
                Name = 'Repeat Issue',
                Multiplier__c = 4.0
        );
        multipliers.add(repeatIssue);
        Double repeatIssueScore = impactCalculator.CalculateRepeatIssueScore(testIncident.RepeatIssue__c, (Double)repeatIssue.Multiplier__c);

        // expected result
        Double netScore = severityScore + priorityScore + securityScore + knownIssueScore + repeatIssueScore;
        system.debug('CalculateIncidentNetScore(): netScore - ' + netScore);

        insert multipliers;
        test.startTest();
        update testIncident;
        test.stopTest();

        // get actual
        testIncident = [Select Incident_Net_Score__c from Case where Id = :testIncident.Id];
        system.assertEquals(netScore, testIncident.Incident_Net_Score__c, 'Re-calculated incident net score is incorrect.');


    }


    static testMethod void testPartnerCaseProxyServiceCreate() {

        Account verizonAccount = [
                Select Id, CadebillAccountNo__c, Partner_Customer_Account_ID__c
                from Account where Billing_Group__c = :PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON LIMIT 1
        ];
        Contact verizonContact = [Select Id from Contact where AccountId = :verizonAccount.Id LIMIT 1];

        ETMS_Codes__c[] testEtmsCode = ETMS_Codes__c.getAll().values();

        // create an incident
        Map<String,Schema.RecordTypeInfo> testIncidentTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testIncident = new Case(
                RecordTypeId = testIncidentTypeMap.get('Incident').getRecordTypeId(),
                Subject = 'Verizon Test',
                Status = 'New',
                AccountId = verizonAccount.Id,
                ContactId = verizonContact.Id,
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = testEtmsCode[0].Request_Type__c,
                Database__c = testEtmsCode[0].Reason__c,
                Releases__c = testEtmsCode[0].Reason_Detail__c
        );

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        testIncident.setOptions(dmo);
        insert testIncident;
        // Performing DML Before Mock Callouts to avoid uncommitted work pending error
        test.startTest();
        PartnerCaseProxyServiceMockTest proxyServiceMock = new PartnerCaseProxyServiceMockTest();
        Test.setMock(WebServiceMock.class, proxyServiceMock);
        test.stopTest();

        PartnerCaseProxyService.CreatePartnerCase_element request = (PartnerCaseProxyService.CreatePartnerCase_element)proxyServiceMock.request;
        // make sure the trigger makes a callout to proxy service
        system.assertEquals(true, PartnerCaseProxyServiceHelper.isCasePushed);
        system.assertEquals(PartnerCaseProxyServiceHelper.PRODUCT_GENERAL, request.newCases.SalesforceCase[0].Product);
        system.assertEquals(PartnerCaseProxyServiceHelper.DEFAULT_COUNTRY_USA, request.newCases.SalesforceCase[0].Country);
        system.assertEquals(
                verizonAccount.CadebillAccountNo__c.format().remove(','),
                request.newCases.SalesforceCase[0].NEID
        );
        system.assertEquals(
                verizonAccount.Partner_Customer_Account_ID__c.removeStartIgnoreCase(PartnerCaseProxyServiceHelper.PARTNER_CUSTOMER_ID_PREFIX),
                request.newCases.SalesforceCase[0].ServiceId
        );

    } // end of testPartnerCaseProxyServiceCreate()

    static testMethod void testPartnerCaseProxyServiceSecondCreate() {

        Account verizonAccount = [Select Id from Account where Billing_Group__c = :PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON LIMIT 1];
        Contact verizonContact = [Select Id from Contact where AccountId = :verizonAccount.Id LIMIT 1];

        ETMS_Codes__c[] testEtmsCode = ETMS_Codes__c.getAll().values();

        // create an incident
        Map<String,Schema.RecordTypeInfo> testIncidentTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testIncident = new Case(
                RecordTypeId = testIncidentTypeMap.get('Incident').getRecordTypeId(),
                Subject = 'Verizon Test',
                Status = 'New',
                AccountId = verizonAccount.Id,
                ContactId = verizonContact.Id,
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = testEtmsCode[0].Request_Type__c,
                Database__c = testEtmsCode[0].Reason__c,
                Releases__c = testEtmsCode[0].Reason_Detail__c
        );

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        testIncident.setOptions(dmo);
        insert testIncident;

        CaseTriggerHandler.noOfProxyServiceCallouts = 0;
        testIncident.Status = 'Work in Progress';
        testIncident.Request_Type__c = 'Connectivity';
        testIncident.Product_or_Service__c = 'Toll Free';
        testIncident.Dial_From_ANI__c = '8008772525';
        testIncident.Dial_To_DNIS__c = '8002115252';
        testIncident.Customer_s_Toll_Free_POC__c = '8775253636';
        testIncident.Incident_Location__c = 'United States';
        update testIncident;

        // Performing DML Before Mock Callouts to avoid uncommitted work pending error
        test.startTest();
        PartnerCaseProxyServiceMockTest proxyServiceMock = new PartnerCaseProxyServiceMockTest();
        Test.setMock(WebServiceMock.class, proxyServiceMock);
        test.stopTest();

        ETMS_Incident_Location_To_Country__mdt[] mdt = [
                Select Incident_Location__c, Country__c from ETMS_Incident_Location_To_Country__mdt
                where Incident_Location__c = :testIncident.Incident_Location__c
        ];

        system.assertNotEquals(0, mdt.size(), 'Incident location to country mapping not found.');

        PartnerCaseProxyService.CreatePartnerCase_element request = (PartnerCaseProxyService.CreatePartnerCase_element)proxyServiceMock.request;

        // make sure the trigger makes a callout to proxy service
        system.assertEquals(true, PartnerCaseProxyServiceHelper.isCasePushed);
        system.assertEquals(PartnerCaseProxyServiceHelper.PRODUCT_DIALTF, request.newCases.SalesforceCase[0].Product);
        system.assertEquals(mdt[0].Country__c, request.newCases.SalesforceCase[0].Country);
        system.assertEquals(
                testIncident.Customer_s_Toll_Free_POC__c,
                request.newCases.SalesforceCase[0].NEID
        );
        system.assertEquals(
                testIncident.Customer_s_Toll_Free_POC__c,
                request.newCases.SalesforceCase[0].ServiceId
        );

    } // end of testPartnerCaseProxyServiceSecondCreate()

    static testMethod void testPartnerCaseProxyServiceUpdate() {

        Account verizonAccount = [Select Id from Account where Billing_Group__c = :PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON LIMIT 1];
        Contact verizonContact = [Select Id from Contact where AccountId = :verizonAccount.Id LIMIT 1];
        ETMS_Codes__c[] testEtmsCode = ETMS_Codes__c.getAll().values();

        // create an incident
        Map<String,Schema.RecordTypeInfo> testIncidentTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testIncident = new Case(
                RecordTypeId = testIncidentTypeMap.get('Incident').getRecordTypeId(),
                Subject = 'Verizon Test',
                Status = 'New',
                AccountId = verizonAccount.Id,
                ContactId = verizonContact.Id,
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = testEtmsCode[0].Request_Type__c,
                Database__c = testEtmsCode[0].Reason__c,
                Releases__c = testEtmsCode[0].Reason_Detail__c,
                X3rdPartyVendorTicket__c = '20170821',
                Origin = 'Chat'
        );
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        testIncident.setOptions(dmo);
        insert testIncident;

        test.startTest();
        Test.setMock(WebServiceMock.class, new PartnerCaseProxyServiceMockTest());

        CaseTriggerHandler.noOfProxyServiceCallouts = 0;
        testIncident.Reason__c = 'Access/Login';
        testIncident.Status = 'Waiting on Customer';
        update testIncident;

        ETMS_Trouble_Report_State_Status__mdt[] mdt = [
                Select Case_Status__c, Trouble_Report_State__c, Trouble_Report_Status__c
                From ETMS_Trouble_Report_State_Status__mdt
                where Case_Status__c = :testIncident.Status
        ];

        system.assertNotEquals(0, mdt.size(), 'Case Status and ETMS Trouble Report State/Status mapping not found.');

        Case incident = [SELECT Status, ETMS_Trouble_Report_State__c, ETMS_Trouble_Report_Status__c from Case where Id = :testIncident.Id LIMIT 1];
        system.assertEquals(testIncident.Status, incident.Status, incident);
        system.assertEquals(mdt[0].Trouble_Report_State__c, incident.ETMS_Trouble_Report_State__c);
        system.assertEquals(mdt[0].Trouble_Report_Status__c, incident.ETMS_Trouble_Report_Status__c);

        test.stopTest();

        // make sure the trigger makes a callout to proxy service
        system.assertEquals(true, PartnerCaseProxyServiceHelper.isCasePushed);

    } // end of testPartnerCaseProxyServiceUpdate()

    static testMethod void testPartnerCaseProxyServiceRetry() {

        Account verizonAccount = [Select Id from Account where Billing_Group__c = :PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON LIMIT 1];
        Contact verizonContact = [Select Id from Contact where AccountId = :verizonAccount.Id LIMIT 1];
        ETMS_Codes__c[] testEtmsCode = ETMS_Codes__c.getAll().values();

        // create an incident
        Map<String,Schema.RecordTypeInfo> testIncidentTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testIncident = new Case(
                RecordTypeId = testIncidentTypeMap.get('Incident').getRecordTypeId(),
                Subject = 'Verizon Test',
                Status = 'New',
                AccountId = verizonAccount.Id,
                ContactId = verizonContact.Id,
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = testEtmsCode[0].Request_Type__c,
                Database__c = testEtmsCode[0].Reason__c,
                Releases__c = testEtmsCode[0].Reason_Detail__c
        );
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        testIncident.setOptions(dmo);
        insert testIncident;

        CaseTriggerHandler.noOfProxyServiceCallouts = 0;
        testIncident.Status = 'Assigned';
        testIncident.Push_To_Partner__c = true;
        update testIncident;

        // Performing DML Before Mock Callouts to avoid uncommitted work pending error
        test.startTest();
        Test.setMock(WebServiceMock.class, new PartnerCaseProxyServiceMockTest());
        test.stopTest();

        Case incident = [SELECT Push_To_Partner__c from Case where Id = :testIncident.Id LIMIT 1];
        system.assertEquals(false, incident.Push_To_Partner__c, 'The field should be set to false after calling the Proxy Service.');
        // make sure the trigger makes a callout to proxy service
        system.assertEquals(true, PartnerCaseProxyServiceHelper.isCasePushed);

    } // end of testPartnerCaseProxyServiceRetry()

    // test XMNotification record is created when an Event is confirmed
    static testMethod void testEventInitialConfirmationNotification() {

        AppConfiguration__c appConfig = new AppConfiguration__c(
                XM_Turn_Off_Comment_Notifications__c = true
        );
        insert appConfig;

        // create an event
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

        // confirm event
        test.startTest();
        testEvent.status = 'Confirmed';
        testEvent.IgnoreEventStatusLock__c = true;
        update testEvent;
        test.stopTest();

        xmNotification__c[] notifications = [
                Select Request_Type__c
                from xmNotification__c
                where Case__c = :testEvent.Id
        ];

        system.assertEquals(1, notifications.size(), 'One xmNotification record should be created.');
        system.assertEquals( new CaseTriggerHandler().getXmNotificationRequestType(testEvent), notifications[0].Request_Type__c, 'Request type is incorrect.');

    }

    // test XMNotification record is not created when an Event is confirmed if the xMatters notifications is turned off
    static testMethod void testxMattersEventNotificationTurnedOff() {

        AppConfiguration__c appConfig = new AppConfiguration__c(
                XM_Turn_Off_Event_Notifications__c = true,
                XM_Turn_Off_Comment_Notifications__c = true,
                XM_Maintenance_Notifications_Internal__c = 'test',
                XM_Event_Notifications_Internal__c = 'test'
        );
        insert appConfig;

        // create an event
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

        // confirm event
        test.startTest();
        testEvent.status = 'Confirmed';
        testEvent.IgnoreEventStatusLock__c = true;
        update testEvent;
        test.stopTest();

        xmNotification__c[] notifications = [
                Select Request_Type__c
                from xmNotification__c
                where Case__c = :testEvent.Id
        ];

        system.assertEquals(0, notifications.size(), 'One xmNotification record should not be created.');

    }

    // test XMNotification record is created when an Event is Resolved
    static testMethod void testEventResolvedNotification() {

        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'Test Product';
        pem.Product__c = 'Test Product';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;
        insert pem;

        // create an event
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
                xmEvent_Notification_Sent__c = true,
                Priority = 'P1'
        );

        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        testEvent.setOptions(dmo);

        insert testEvent;

        // resolve event
        test.startTest();

        testEvent.status = 'Resolved';
        testEvent.Database__c = 'Duplicate';
        testEvent.Reason__c = 'Duplicate';
        testEvent.Releases__c = 'Duplicate';
        testEvent.IgnoreEventStatusLock__c = true;

        update testEvent;

        test.stopTest();

        xmNotification__c[] notifications = [
                Select Request_Type__c
                from xmNotification__c
                where Case__c = :testEvent.Id
        ];

        system.assertEquals(1, notifications.size(), 'One xmNotification record should be created.');
        system.assertEquals( new CaseTriggerHandler().getXmNotificationRequestType(testEvent), notifications[0].Request_Type__c, 'Request type is incorrect.');

        system.assertEquals(true, [Select EventHasBeenResolvedOrClosed__c from Case Where Id = :testEvent.Id].EventHasBeenResolvedOrClosed__c, 'EventHasBeenResolvedOrClosed flag not set to true.' );

        testEvent.status = 'Closed';
        testEvent.IgnoreEventStatusLock__c = true;
        update testEvent;

        notifications = [
                Select Request_Type__c
                from xmNotification__c
                where Case__c = :testEvent.Id
        ];

        system.assertEquals(1, notifications.size(), 'There should not be more than one xmNotification record but actual '+ notifications.size());

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
                RecordTypeId = accountRecordTypeMap.get('Partners').getRecordTypeId(),
                CadebillAccountNo__c = 877121,
                Partner_Customer_Account_ID__c = 'IC-877121'
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

    }
}