/**
 * Created by mohandaas.rangaswamy on 12/7/2017.
 */

@IsTest
private class ProjectAndOpportunityRollupTest {

    static testMethod void testBehavior() {

    }

    @TestSetup
    static void setupData(){

        Map<String, RecordTypeInfo> accountRecordTypes = Schema.sObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'ProjectAndOpportunityRollupTest Customer',
                Type = 'Customer',
                RecordTypeId = accountRecordTypes.get('Customers').getRecordTypeId()
        );

        insert testAccount;

        Map<String, RecordTypeInfo> opportunityRecordTypes = Schema.sObjectType.Opportunity.getRecordTypeInfosByName();

        Opportunity testOpp = new Opportunity(
                Name = 'ProjectAndOpportunityRollupTest',
                AccountId = testAccount.Id,
                Partner_Deal__c = 'NO',
                RecordTypeId = opportunityRecordTypes.get('Qualified Opportunity').getRecordTypeId(),
                StageName = '5 - Proposal / Negotiation',
                CloseDate = Date.today(),
                Contract_Type__c = 'New Customer'
        );
        insert testOpp;

        Map<String, RecordTypeInfo> projectRecordTypes = Schema.sObjectType.Project__c.getRecordTypeInfosByName();

        Project__c parentProject = new Project__c();
        parentProject.RecordTypeId = projectRecordTypes.get('PS Parent Project - SaaS').getRecordTypeId();
        parentProject.Opportunity__c = testOpp.Id;
        parentProject.Account__c = testAccount.Id;
        insert parentProject;

        List<Project__c> projectList = new List<Project__c>();
        Project__c phase1 = new Project__c();
        phase1.RecordTypeId = projectRecordTypes.get('PS Project Phase SaaS').getRecordTypeId();
        phase1.EstimatedProjectGoLiveDate__c = Date.today();
        phase1.Summary__c = 'Phase 1';
        phase1.Opportunity__c = testOpp.Id;
        phase1.Account__c = testAccount.Id;
        phase1.ParentProject__c = parentProject.Id;
        projectList.add(phase1);

        insert projectList;

    }
}