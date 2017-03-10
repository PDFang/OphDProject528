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
        insert testIncident;

    } // createTestData()

}