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
        knownIssueCalculationStub.DollarAmountTiedToIssue = 1;
        knownIssueCalculationStub.RecentReleaseBreak = 1;
        // incident
        test.startTest();
        KnownIssueImpactCalculationClass knownIssueImpactCalculation = new KnownIssueImpactCalculationClass(knownIssueCalculationStub);

        knownIssueImpactCalculation.CalculateKnownIssueScore(new list<Case>());
        knownIssueImpactCalculation.CalculateKnownIssueScore(knownIssueList);


        test.stopTest();
        //for(Case KnownIssuCase : knownIssueList){
        Case[] newCase = [Select KIImpactScore__c from Case where Id = : knownIssueList[0].Id limit 1];
        system.assertEquals(4.0, newCase[0].KIImpactScore__c);
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
                Risk_of_Leaving__c = '1',
                Referenceable__c = false,
                GYRStatus__c = 'Green'
        );

        insert testAccount;
        Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SobjectType.Case.getRecordTypeInfosByName();
        // known issue
        list<Case> knownIssueList = new list<Case>{
                new Case(
                        //AccountId = testAccount.Id,
                        RecordTypeId = recordTypeMap.get('Known Issue').getRecordTypeId(),
                        Type = 'Known Issue',
                        Status = 'New',
                        KB_Attached__c = false,
                        Subject = 'KnowIssueImpactCalculationTest',
                        Description = 'Known Issue Calculation Test',
                        Origin = 'Web'


                )
        };
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

        insert incidentList;

        list<JBCXM__CustomerInfo__c> customerInfoList = new list<JBCXM__CustomerInfo__c>{
                new JBCXM__CustomerInfo__c(
                        JBCXM__Account__c = testAccount.Id,
                        JBCXM__ASV__c = 2345678
                )
        };

        insert customerInfoList;

        return knownIssueList;

    }

    static testMethod void KnownIssuesImpactScoreCalcBatchTests ()
    {
        list<case> knownIssueList = new list<Case>();
        knownIssueList = GetListOfCases();

        // incident
        test.startTest();
        string knownIssueQuery = 'select Id,Broken_by_Recent_Release__c,Status, Subject from Case '
                + 'WHERE RecordType.Name = \'Known Issue\' '
                + 'AND isClosed = false and Status not in (\'Released - Confirm Resolution\',\'No Fix\')';
        database.executeBatch(new KnownIssuesImpactScoreCalcBatch(knownIssueQuery), 500);

        test.stopTest();
        //for(Case KnownIssuCase : knownIssueList){
        Case[] newCase = [Select KIImpactScore__c from Case where Id = : knownIssueList[0].Id limit 1];
        system.assertEquals(10.0, newCase[0].KIImpactScore__c);
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

    static testMethod void KnownIssuesChangePriorityTests ()
    {
        Test.startTest();
        set<id> incidentIds = new set<id>();
        list<case> knownIssueList = new list<Case>();
        knownIssueList = GetListOfCases();
        for(Case incident : [select Id from Case where RecordType.Name = 'Incident']){
         incidentIds.add(incident.Id);
        }
        KnownIssueImpactCalculationClass.ChangeKIPriority(incidentIds);

        Test.stopTest();

        Case[] newCase = [Select Priority from Case where Id = : knownIssueList[0].Id limit 1];
        system.assertEquals('P1', newCase[0].Priority);
    }
}