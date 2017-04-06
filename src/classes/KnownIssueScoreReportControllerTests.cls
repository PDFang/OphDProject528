/**
 * Created by ravish.chawla on 4/6/2017.
 */

@isTest
public class KnownIssueScoreReportControllerTests {

    static testMethod void CalculateKnownIssueScoreReport_ReturnsReportViewCorrectly()
    {
        list<case> knownIssueList = new list<Case>();
        knownIssueList = GetListOfCases();

        string result;

        system.debug('knownIssueList =>' + knownIssueList.size());
        result = KnownIssueScoreReportController.GetKnownIssues(null, 0);
        KnownIssueViewHelper.KnownIssuDataWrapper kiDiClsObj = (KnownIssueViewHelper.KnownIssuDataWrapper)JSON.deserialize(result,KnownIssueViewHelper.KnownIssuDataWrapper.class);
        system.debug('kiDiClsObj =>' + kiDiClsObj.KIDataItems.size());
        system.assertEquals(10, kiDiClsObj.KIDataItems.size());
        result= KnownIssueScoreReportController.GetKnownIssues(null, 10);
        kiDiClsObj = (KnownIssueViewHelper.KnownIssuDataWrapper)JSON.deserialize(result,KnownIssueViewHelper.KnownIssuDataWrapper.class);
        system.assertEquals(5, kiDiClsObj.KIDataItems.size());


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
        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        list<Case> knownIssueList = new list<Case>();
        list<Case> incidentList = new list<Case>();

        for(integer i=0; i<15; i++) {

            knownIssueList.add(
                    new Case(
                            //AccountId = testAccount.Id,
                            RecordTypeId = recordTypeMap.get('Known Issue').getRecordTypeId(),
                            Type = 'Known Issue',
                            Status = 'New',
                            KB_Attached__c = false,
                            Subject = 'KnowIssueImpactCalculationTest' + i,
                            Description = 'Known Issue Calculation Test',
                            Origin = 'Web',
                            KIImpactScore__c = 1000

                    )
            );
        }
            for(Case c : knownIssueList){
                c.setOptions(dmo);
            }

            insert knownIssueList;

        for(integer i=0; i<knownIssueList.size(); i++) {
            incidentList.add(
                    new Case(
                            AccountId = testAccount.Id,
                            RecordTypeId = recordTypeMap.get('Incident').getRecordTypeId(),
                            Type = 'Incident',
                            Status = 'New',
                            KB_Attached__c = false,
                            Subject = 'KnowIssueImpactCalculationTest' + i,
                            Description = 'Known Issue Calculation Test' + i,
                            Origin = 'Web',
                            Priority = 'P1',
                            KnownIssue__c = knownIssueList[i].Id
                    )
            );
        }
            for(Case c : incidentList){
                c.setOptions(dmo);
            }

            insert incidentList;

        return knownIssueList;

    }

}