/**
 * Created by ravish.chawla on 3/20/2017.
 */

@isTest
public class KnownIssueImpactCalculationClassTests {

    static testMethod void CalculateKnownIssueScore_ReturnsSetScoreCorrectly(){



        // Set stub methods to always return the same value
        list<case> knownIssueList = new list<Case>();
        knownIssueList = GetListOfCases();

        KnownIssuesImpactCalcStub knownIssueCalculationStub = new KnownIssuesImpactCalcStub();
        knownIssueCalculationStub.NumberIncidentsTiedToIssue = 1;
        knownIssueCalculationStub.DaysIssuePresent = 1;
        knownIssueCalculationStub.Priority = 1;
        knownIssueCalculationStub.RecentReleaseBreak = 1;
        knownIssueCalculationStub.SecurityIssue = 1;
        // incident
        test.startTest();
        KnownIssueImpactCalculationClass knownIssueImpactCalculation = new KnownIssueImpactCalculationClass(knownIssueCalculationStub);

        knownIssueImpactCalculation.CalculateKnownIssueScore(new list<Case>());
        knownIssueImpactCalculation.CalculateKnownIssueScore(knownIssueList);

        KnownIssueImpactCalculationClass.SendEmail('Test', 'Test');


        test.stopTest();
        //for(Case KnownIssuCase : knownIssueList){
        Case[] newCase = [Select KIImpactScore__c, Priority from Case where Id = : knownIssueList[0].Id limit 1];
        system.assertEquals(6.0, newCase[0].KIImpactScore__c);
        //}

    }

    public static list<Case> GetListOfCases()
    {
        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'testCalculateAccountNetScore Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                IsPartner__c = false,
                CustomerSegment__c = 'Strategic',
                Brand_Visibility__c = 'Yes',
                Industry_Leadership_Vocality__c = 'Yes',
                Social_Media_Presence__c = 'Yes',
                Risk_of_Leaving__c = 'Low',
                Referenceable__c = false,
                GYRStatus__c = 'Green'
        );

        insert testAccount;
        Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SobjectType.Case.getRecordTypeInfosByName();
        // known issue
        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;

        list<Case> knownIssueList = new list<Case>{
                new Case(
                        //AccountId = testAccount.Id,
                        RecordTypeId = recordTypeMap.get('Known Issue').getRecordTypeId(),
                        Type = 'Known Issue',
                        Status = 'New',
                        KB_Attached__c = false,
                        Subject = 'KnowIssueImpactCalculationTest',
                        Description = 'Known Issue Calculation Test',
                        Origin = 'Web',
                        KIImpactScore__c = 1000

                )
        };

        for(Case c : knownIssueList){
            c.setOptions(dmo);
        }

        insert knownIssueList;


        list<Case> incidentList = new list<Case>{
                new Case(
                        AccountId = testAccount.Id,
                        RecordTypeId = recordTypeMap.get('Incident').getRecordTypeId(),
                        Type = 'Incident',
                        Status = 'New',
                        KB_Attached__c = false,
                        Subject = 'KnowIssueImpactCalculationTest',
                        Description = 'Known Issue Calculation Test',
                        Origin = 'Web',
                        Priority = 'P1',
                        KnownIssue__c = knownIssueList[0].Id,
                        KIImpactScore__c = knownIssueList[0].KIImpactScore__c



                )
        };

        for(Case c : incidentList){
            c.setOptions(dmo);
        }

        insert incidentList;

        list<JBCXM__CustomerInfo__c> customerInfoList = new list<JBCXM__CustomerInfo__c>{
                new JBCXM__CustomerInfo__c(
                        JBCXM__Account__c = testAccount.Id,
                        JBCXM__ASV__c = 2345678
                )
        };

        insert customerInfoList;

        SiteConfiguration__c sbx = new SiteConfiguration__c();
        sbx.Name = inContactBaseClass.OrgId15Digit;
        sbx.AutoEventEmails__c = false;
        sbx.DaysToDisplayKnownIssues__c = 30;
        sbx.OrgId__c = inContactBaseClass.OrgId15Digit;
        sbx.EventResolvedPriorities__c = 'P1;P2;';
        sbx.EventResolvedEmails__c = false;
        sbx.DeveloperErrorEmail__c = 'test@Arnabtest.com';
        insert sbx;


        return knownIssueList;

    }

    static testMethod void KnownIssuesImpactScoreCalcBatchTests ()
    {
        list<case> knownIssueList = new list<Case>();
        knownIssueList = GetListOfCases();

        // incident
        test.startTest();
        string knownIssueQuery = 'select Broken_by_Recent_Release__c,Status, Subject, Priority, KIImpactScore__c from Case '
                + 'WHERE RecordType.Name = \'Known Issue\' ';
        database.executeBatch(new KnownIssuesImpactScoreCalcBatch(knownIssueQuery), 500);

        test.stopTest();
        //for(Case KnownIssuCase : knownIssueList){
        Case[] newCase = [Select KIImpactScore__c, KIImpactScoreHistorical__c from Case where Id = : knownIssueList[0].Id limit 1];
        system.assertEquals(11.0, newCase[0].KIImpactScore__c);
        system.assertEquals(1000, newCase[0].KIImpactScoreHistorical__c);
        //}
    }

    static testMethod void KnownIssuesImpactScoreSchedulerTests ()
    {
        Test.startTest();
        KnownIssuesImpactScoreScheduler knownIssuesImpactScoreSchTest = new KnownIssuesImpactScoreScheduler();
        String sch = '0 0 1 * * ?';

        System.schedule('Test', sch, knownIssuesImpactScoreSchTest);


        Test.stopTest();
    }
}