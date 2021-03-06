/**
 * Created by mohandaas.rangaswamy on 3/23/2017.
 */

@IsTest
private class ImpactScoreCalculationBatchTest {
    static testMethod void testAccountNetScoreCalculationBatch() {

        createAccounts();
        test.startTest();
        Id asyncJobId = Database.executeBatch(new ImpactScoreCalculationBatch(ImpactCalculationConstants.ImpactScoreType.AccountNetScore));
        test.stopTest();
        AsyncApexJob job = [Select Id, Status From AsyncApexJob where Id = :asyncJobId];
        system.assertEquals('Completed', job.Status);

    }

    static testMethod void testIncidentNetScoreCalculationBatch() {

        createIncidents();
        test.startTest();
        Id asyncJobId = Database.executeBatch(new ImpactScoreCalculationBatch(ImpactCalculationConstants.ImpactScoreType.IncidentNetScore));
        test.stopTest();
        AsyncApexJob job = [Select Id, Status From AsyncApexJob where Id = :asyncJobId];
        system.assertEquals('Completed', job.Status);

    }

    static testMethod void testGainsightNetScoreCalculationBatch() {

        createCustomerInfo();
        test.startTest();
        Id asyncJobId = Database.executeBatch(new ImpactScoreCalculationBatch(ImpactCalculationConstants.ImpactScoreType.GainsightNetScore));
        test.stopTest();
        AsyncApexJob job = [Select Id, Status From AsyncApexJob where Id = :asyncJobId];
        system.assertEquals('Completed', job.Status);

    }

    private static Account[] createAccounts() {
        // create accounts
        Map<String, Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account[] accountList = new Account[]{
        };
        for (Integer i = 0; i < 100; i++) {
            Account testAccount = new Account(
                    Name = 'ImpactScoreCalculationBatchTest Account ' + i,
                    Type = 'Customer',
                    RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                    IsPartner__c = false,
                    CustomerSegment__c = 'Strategic',
                    Brand_Visibility__c = 'No',
                    Industry_Leadership_Vocality__c = 'Yes',
                    Social_Media_Presence__c = 'Yes',
                    Risk_of_Leaving__c = 'Low',
                    Referenceable__c = false
            );
            accountList.add(testAccount);
        }
        insert accountList;
        return accountList;
    }

    private static void createCustomerInfo() {

        Account[] accountList = createAccounts();
                // create customer info
        JBCXM__ScoringScheme__c scoringScheme = new JBCXM__ScoringScheme__c(
                Name = 'test'
        );
        insert scoringScheme;

        JBCXM__ScoringSchemeDefinition__c scoringSchemeDefinition = new JBCXM__ScoringSchemeDefinition__c(
                JBCXM__Score__c = 2.0,
                JBCXM__SchemeId__c = scoringScheme.Id
        );
        insert scoringSchemeDefinition;

        JBCXM__CustomerInfo__c[] customerInfoList = new JBCXM__CustomerInfo__c[]{};
        for(Integer i=0; i<accountList.size(); i++){
            JBCXM__CustomerInfo__c customerInfo = new JBCXM__CustomerInfo__c(
                    JBCXM__Account__c = accountList[i].Id,
                    JBCXM__CurScoreId__c = scoringSchemeDefinition.Id,
                    JBCXM_Credits__c = 2500,
                    JBCXM__MRR__c = 5004
            );
            customerInfoList.add(customerInfo);
        }
        insert customerInfoList;

    }


    private static void createIncidents(){

        Account[] accountList = createAccounts();
        // create contacts
        Map<String,Schema.RecordTypeInfo> contactRecordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact[] contactList = new Contact[]{};
        for(Integer i=0; i<accountList.size(); i++){
            Contact testContact = new Contact(
                    LastName = 'Contact '+ i,
                    FirstName = 'Test',
                    Email = 'contact' + i + '@test.com',
                    RecordTypeId = contactRecordTypeMap.get('Partner Contact').getRecordTypeId(),
                    AccountId = accountList[i].Id
            );
            contactList.add(testContact);
        }
        insert contactList;

        // create incidents
        Map<String,Schema.RecordTypeInfo> caseRecordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case[] caseList = new Case[]{};
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        for(Integer i=0; i<10; i++){
            Case testIncident = new Case(
                    RecordTypeId = caseRecordTypeMap.get('Incident').getRecordTypeId(),
                    Subject = 'CalculateIncidentNetScore Test',
                    Description = 'CalculateIncidentNetScore Test',
                    Status = 'New',
                    AccountId = accountList[i].Id,
                    ContactId = contactList[i].Id,
                    Severity__c = 'S2',
                    Business_Impacted__c = '25-50%',
                    Quality_of_Workaround__c = 'Medium',
                    Related_to_Previous_Known_Issue__c = 'No',
                    Security_Issue__c = 'No',
                    Workaround_Available__c = 'Yes',
                    Product_or_Service__c = 'Service Disruption',
                    Request_Type__c = 'Dialer'
            );
            testIncident.setOptions(dmo);
            caseList.add(testIncident);
        }
        insert caseList;

    }

}