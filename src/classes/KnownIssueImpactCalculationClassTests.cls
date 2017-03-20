/**
 * Created by ravish.chawla on 3/20/2017.
 */

@isTest
public class KnownIssueImpactCalculationClassTests {

    static testMethod void CalculateKnownIssueScore_ReturnsSetScoreCorrectly(){
        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'testCalculateAccountNetScore Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                IsPartner__c = false,
                CustomerSegment__c = 'Strategic',
                Brand_Visibility__c = 'Medium',
                Industry_Leadership_Vocality__c = 'Low',
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
                        KnownIssue__c = knownIssueList[0].Id,
                        KIImpactScore__c = knownIssueList[0].KIImpactScore__c



                )
        };
        insert incidentList;


        // Set stub methods to always return the same value

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
        for(Case KnownIssuCase : knownIssueList){
            Case newCase = [Select KIImpactScore__c from Case where Id = :KnownIssuCase.Id limit 1];
            system.assertEquals(4.0, newCase.KIImpactScore__c);
        }

    }
}