@isTest
private class PartnerCaseRestServiceTest {

    static testMethod void updateIncidentTest(){

        Account verizonAccount = [Select Id from Account where Billing_Group__c = :PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON LIMIT 1];
        Contact verizonContact = [Select Id from Contact where AccountId = :verizonAccount.Id LIMIT 1];

        // create an incident
        Map<String,Schema.RecordTypeInfo> testIncidentTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testIncident = new Case(
                RecordTypeId = testIncidentTypeMap.get('Incident').getRecordTypeId(),
                Subject = 'Verizon Test',
                Status = 'New',
                AccountId = verizonAccount.Id,
                ContactId = verizonContact.Id,
                Request_Type__c = 'Connectivity',
                Product_or_Service__c = 'Local'
        );

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        testIncident.setOptions(dmo);
        insert testIncident;

        test.startTest();

        test.stopTest();

    }

    @TestSetup
    private static void createTestData(){

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
                Partner_Customer_Account_ID__c = null
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