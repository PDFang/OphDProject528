/**
 * Created by mohandaas.rangaswamy on 2/13/2017.
 */

@IsTest
private class CaseTriggerHandlerTest {

    static testMethod void testPartnerCaseProxyServiceCreate() {

        createTestData();
        Account verizonAccount = [Select Id from Account where Billing_Group__c = :CaseTriggerHandler.BILLING_GROUP_VERIZON LIMIT 1];
        Contact verizonContact = [Select Id from Contact where AccountId = :verizonAccount.Id LIMIT 1];

        test.startTest();
        Test.setMock(WebServiceMock.class, new PartnerCaseProxyServiceMockTest());
        ETMS_Codes__c[] testEtmsCode = ETMS_Codes__c.getAll().values();

        // create an incident
        Map<String,Schema.RecordTypeInfo> caseRecordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testIncident = new Case(
                RecordTypeId = caseRecordTypeMap.get('Incident').getRecordTypeId(),
                Subject = 'Verizon Test',
                Status = 'New',
                AccountId = verizonAccount.Id,
                ContactId = verizonContact.Id,
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = testEtmsCode[0].Request_Type__c,
                Database__c = testEtmsCode[0].Reason__c,
                Releases__c = testEtmsCode[0].Reason_Detail__c
        );
        insert testIncident;

        test.stopTest();

    } // end of testPartnerCaseProxyServiceCreate()

    static testMethod void testPartnerCaseProxyServiceUpdate() {

        createTestData();
        Account verizonAccount = [Select Id from Account where Billing_Group__c = :CaseTriggerHandler.BILLING_GROUP_VERIZON LIMIT 1];
        Contact verizonContact = [Select Id from Contact where AccountId = :verizonAccount.Id LIMIT 1];
        ETMS_Codes__c[] testEtmsCode = ETMS_Codes__c.getAll().values();

        // create an incident
        Map<String,Schema.RecordTypeInfo> caseRecordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testIncident = new Case(
                RecordTypeId = caseRecordTypeMap.get('Incident').getRecordTypeId(),
                Subject = 'Verizon Test',
                Status = 'New',
                AccountId = verizonAccount.Id,
                ContactId = verizonContact.Id,
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = testEtmsCode[0].Request_Type__c,
                Database__c = testEtmsCode[0].Reason__c,
                Releases__c = testEtmsCode[0].Reason_Detail__c
        );

        insert testIncident;

        test.startTest();
        Test.setMock(WebServiceMock.class, new PartnerCaseProxyServiceMockTest());
        testIncident.Status = 'Assigned';
        testIncident.Push_To_Partner__c = true;
        update testIncident;

        test.stopTest();

    } // end of testPartnerCaseProxyServiceUpdate()

    //@TestSetup
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
                Billing_Group__c = CaseTriggerHandler.BILLING_GROUP_VERIZON,
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