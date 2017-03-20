/**
 * Created by mohandaas.rangaswamy on 2/13/2017.
 */

@IsTest
private class CaseTriggerHandlerTest {

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
                Business_Impacted__c = '25-50%',
                Quality_of_Workaround__c = 'Medium',
                Related_to_Previous_Known_Issue__c = 'No',
                Security_Issue__c = 'No',
                Workaround_Available__c = 'Yes',
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = 'Dialer'
        );

        // create impact score multiplier
        IncidentImpactCalculationInterface impactCalculator = new IncidentImpactCalculationImplementation();
        Impact_Score_Multiplier__c[] multipliers = new Impact_Score_Multiplier__c[]{};
        Impact_Score_Multiplier__c severity = new Impact_Score_Multiplier__c(
                Name = 'Severity',
                Multiplier__c = 3.0
        );
        multipliers.add(severity);
        Double severityScore = impactCalculator.CalculateIncidentSeverityScore(testIncident.Severity__c, (Double)severity.Multiplier__c);

        Impact_Score_Multiplier__c businessImpacted = new Impact_Score_Multiplier__c(
                Name = 'Business Impacted',
                Multiplier__c = 2.0
        );
        multipliers.add(businessImpacted);
        Double businessImpactScore = impactCalculator.CalculatePercentBusinessImpactedScore(testIncident.Business_Impacted__c, (Double)businessImpacted.Multiplier__c);

        Impact_Score_Multiplier__c workaround = new Impact_Score_Multiplier__c(
                Name = 'workaround',
                Multiplier__c = 1.0
        );
        multipliers.add(workaround);
        Double workaroundScore = impactCalculator.CalculateWorkaroundAvailablePointsScore(testIncident.Workaround_Available__c, (Double)workaround.Multiplier__c);

        Impact_Score_Multiplier__c workaroundQuality = new Impact_Score_Multiplier__c(
                Name = 'workaround Quality',
                Multiplier__c = 1.0
        );
        multipliers.add(workaroundQuality);
        Double workaroundQualityScore = impactCalculator.CalculateWorkaroundQualityPointsScore(testIncident.Quality_of_Workaround__c, (Double)workaroundQuality.Multiplier__c);

        Impact_Score_Multiplier__c securityIssue = new Impact_Score_Multiplier__c(
                Name = 'is security issue',
                Multiplier__c = 1.0
        );
        multipliers.add(securityIssue);
        Double securityScore = impactCalculator.CalculateSecurityIssueScore(testIncident.Security_Issue__c, (Double)securityIssue.Multiplier__c);

        Impact_Score_Multiplier__c knownIssue = new Impact_Score_Multiplier__c(
                Name = 'is known issue',
                Multiplier__c = 1.0
        );
        multipliers.add(knownIssue);
        Double knownIssueScore = impactCalculator.CalculateRelatedKnownIssueScore(testIncident.Related_to_Previous_Known_Issue__c, (Double)knownIssue.Multiplier__c);

        // expected result
        Double netScore = severityScore + businessImpactScore + workaroundScore + workaroundQualityScore + securityScore + knownIssueScore;
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
                Business_Impacted__c = '25-50%',
                Quality_of_Workaround__c = 'Medium',
                Related_to_Previous_Known_Issue__c = 'No',
                Security_Issue__c = 'No',
                Workaround_Available__c = 'Yes',
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = 'Dialer'
        );
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        testIncident.setOptions(dmo);
        insert testIncident;

        // update severity, business impacted and security issue
        testIncident = [Select Severity__c, Business_Impacted__c, Security_Issue__c, Workaround_Available__c,
                Quality_of_Workaround__c, Related_to_Previous_Known_Issue__c from Case
                where Id = :testIncident.Id

        ];
        testIncident.Severity__c = 'S1';
        testIncident.Business_Impacted__c = '>75%';
        testIncident.Security_Issue__c = 'Yes';

        // create impact score multiplier
        IncidentImpactCalculationInterface impactCalculator = new IncidentImpactCalculationImplementation();
        Impact_Score_Multiplier__c[] multipliers = new Impact_Score_Multiplier__c[]{};
        Impact_Score_Multiplier__c severity = new Impact_Score_Multiplier__c(
                Name = 'Severity',
                Multiplier__c = 3.0
        );
        multipliers.add(severity);
        Double severityScore = impactCalculator.CalculateIncidentSeverityScore(testIncident.Severity__c, (Double)severity.Multiplier__c);

        Impact_Score_Multiplier__c businessImpacted = new Impact_Score_Multiplier__c(
                Name = 'Business Impacted',
                Multiplier__c = 2.0
        );
        multipliers.add(businessImpacted);
        Double businessImpactScore = impactCalculator.CalculatePercentBusinessImpactedScore(testIncident.Business_Impacted__c, (Double)businessImpacted.Multiplier__c);

        Impact_Score_Multiplier__c workaround = new Impact_Score_Multiplier__c(
                Name = 'workaround',
                Multiplier__c = 1.0
        );
        multipliers.add(workaround);
        Double workaroundScore = impactCalculator.CalculateWorkaroundAvailablePointsScore(testIncident.Workaround_Available__c, (Double)workaround.Multiplier__c);

        Impact_Score_Multiplier__c workaroundQuality = new Impact_Score_Multiplier__c(
                Name = 'workaround Quality',
                Multiplier__c = 1.0
        );
        multipliers.add(workaroundQuality);
        Double workaroundQualityScore = impactCalculator.CalculateWorkaroundQualityPointsScore(testIncident.Quality_of_Workaround__c, (Double)workaroundQuality.Multiplier__c);

        Impact_Score_Multiplier__c securityIssue = new Impact_Score_Multiplier__c(
                Name = 'is security issue',
                Multiplier__c = 1.0
        );
        multipliers.add(securityIssue);
        Double securityScore = impactCalculator.CalculateSecurityIssueScore(testIncident.Security_Issue__c, (Double)securityIssue.Multiplier__c);

        Impact_Score_Multiplier__c knownIssue = new Impact_Score_Multiplier__c(
                Name = 'is known issue',
                Multiplier__c = 1.0
        );
        multipliers.add(knownIssue);
        Double knownIssueScore = impactCalculator.CalculateRelatedKnownIssueScore(testIncident.Related_to_Previous_Known_Issue__c, (Double)knownIssue.Multiplier__c);

        // expected result
        Double netScore = severityScore + businessImpactScore + workaroundScore + workaroundQualityScore + securityScore + knownIssueScore;
        system.debug('CalculateIncidentNetScore(): netScore - ' + netScore);

        insert multipliers;
        test.startTest();
        update testIncident;
        test.stopTest();

        // get actual
        testIncident = [Select Incident_Net_Score__c from Case where Id = :testIncident.Id];
        system.assertEquals(netScore, testIncident.Incident_Net_Score__c, 'Re-calculated incident net score is incorrect.');


    }


//    static testMethod void testPartnerCaseProxyServiceCreate() {
//
//        Account verizonAccount = [Select Id from Account where Billing_Group__c = :PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON LIMIT 1];
//        Contact verizonContact = [Select Id from Contact where AccountId = :verizonAccount.Id LIMIT 1];
//
//        ETMS_Codes__c[] testEtmsCode = ETMS_Codes__c.getAll().values();
//
//        // create an incident
//        Map<String,Schema.RecordTypeInfo> testIncidentTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
//        Case testIncident = new Case(
//                RecordTypeId = testIncidentTypeMap.get('Incident').getRecordTypeId(),
//                Subject = 'Verizon Test',
//                Status = 'New',
//                AccountId = verizonAccount.Id,
//                ContactId = verizonContact.Id,
//                Product_or_Service__c = 'Service Disruption',
//                Request_Type__c = testEtmsCode[0].Request_Type__c,
//                Database__c = testEtmsCode[0].Reason__c,
//                Releases__c = testEtmsCode[0].Reason_Detail__c
//        );
//
//        Database.DMLOptions dmo = new Database.DMLOptions();
//        dmo.AssignmentRuleHeader.useDefaultRule = true;
//        testIncident.setOptions(dmo);
//        insert testIncident;
//        // Performing DML Before Mock Callouts to avoid uncommitted work pending error
//        test.startTest();
//        Test.setMock(WebServiceMock.class, new PartnerCaseProxyServiceMockTest());
//        test.stopTest();
//        // make sure the trigger makes a callout to proxy service
//        system.assertEquals(true, PartnerCaseProxyServiceHelper.isCasePushed);
//
//    } // end of testPartnerCaseProxyServiceCreate()
//
//    static testMethod void testPartnerCaseProxyServiceUpdate() {
//
//        Account verizonAccount = [Select Id from Account where Billing_Group__c = :PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON LIMIT 1];
//        Contact verizonContact = [Select Id from Contact where AccountId = :verizonAccount.Id LIMIT 1];
//        ETMS_Codes__c[] testEtmsCode = ETMS_Codes__c.getAll().values();
//
//        // create an incident
//        Map<String,Schema.RecordTypeInfo> testIncidentTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
//        Case testIncident = new Case(
//                RecordTypeId = testIncidentTypeMap.get('Incident').getRecordTypeId(),
//                Subject = 'Verizon Test',
//                Status = 'New',
//                AccountId = verizonAccount.Id,
//                ContactId = verizonContact.Id,
//                Product_or_Service__c = 'Service Disruption',
//                Request_Type__c = testEtmsCode[0].Request_Type__c,
//                Database__c = testEtmsCode[0].Reason__c,
//                Releases__c = testEtmsCode[0].Reason_Detail__c
//        );
//        Database.DMLOptions dmo = new Database.DMLOptions();
//        dmo.AssignmentRuleHeader.useDefaultRule = true;
//        testIncident.setOptions(dmo);
//        insert testIncident;
//
//        testIncident.Status = 'Assigned';
//        testIncident.Push_To_Partner__c = true;
//        update testIncident;
//        // Performing DML Before Mock Callouts to avoid uncommitted work pending error
//        test.startTest();
//        Test.setMock(WebServiceMock.class, new PartnerCaseProxyServiceMockTest());
//        test.stopTest();
//
//        Case incident = [SELECT Push_To_Partner__c from Case where Id = :testIncident.Id LIMIT 1];
//        system.assertEquals(false, incident.Push_To_Partner__c, 'The field should be set to false after calling the Proxy Service.');
//        // make sure the trigger makes a callout to proxy service
//        system.assertEquals(true, PartnerCaseProxyServiceHelper.isCasePushed);
//
//    } // end of testPartnerCaseProxyServiceUpdate()
//
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

    }
}