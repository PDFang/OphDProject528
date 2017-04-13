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
        result = KnownIssueScoreReportController.GetKnownIssues();
        KnownIssueViewHelper.KnownIssuDataWrapper kiDiClsObj = (KnownIssueViewHelper.KnownIssuDataWrapper)JSON.deserialize(result,KnownIssueViewHelper.KnownIssuDataWrapper.class);
        system.debug('kiDiClsObj =>' + kiDiClsObj.KIDataItems.size());
        system.assertEquals(15, kiDiClsObj.KIDataItems.size());
    }

    static testMethod void GetKnownIssueScoreFilter_ReturnsFilterViewCorrectly()
    {
        list<case> knownIssueList = new list<Case>();
        knownIssueList = GetListOfCases();

        string result;

        system.debug('knownIssueList =>' + knownIssueList.size());
        result = KnownIssueScoreReportController.GetFilterString('Subject', 'Test');
        list<string> KiScoreFilterTest = (list<string>)JSON.deserialize(result,list<string>.class);
        system.debug('KiScoreFilterTest =>' + KiScoreFilterTest.size());
        system.assertEquals(15, KiScoreFilterTest.size());

        result = KnownIssueScoreReportController.GetFilterString('KI', 'Test');
        result = KnownIssueScoreReportController.GetFilterString('TFS Id', 'Test');
        result = KnownIssueScoreReportController.GetFilterString('KI Status', 'Test');
        result = KnownIssueScoreReportController.GetFilterString('Team', 'Test');
        result = KnownIssueScoreReportController.GetFilterString('Priority', 'Test');
        result = KnownIssueScoreReportController.GetFilterString('TFS Status', 'Test');
        result = KnownIssueScoreReportController.GetFilterString('Iteration', 'Test');
    }

    static testMethod void GetKnownIssueAccounts_ReturnsAccounts()
    {
        list<case> knownIssueList = new list<Case>();
        knownIssueList = GetListOfCases();

        string result;

        system.debug('knownIssueList =>' + knownIssueList.size());
        result = KnownIssueScoreReportController.GetAccounts(knownIssueList[0].id);
        list<KnownIssueScoreReportController.AccountLists> kiAccountList =
                (list<KnownIssueScoreReportController.AccountLists>)JSON.deserialize(result, list<KnownIssueScoreReportController.AccountLists>.class);
        system.debug('KiScoreFilterTest =>' + kiAccountList[0].AccountName);
        system.assertEquals('testCalculateAccountNetScore Account', kiAccountList[0].AccountName);
    }

    static testMethod void GetKnownIssueRefreshDateTime()
    {
        KnownIssueScoreReportController kiIssueSRControllerObj = new KnownIssueScoreReportController();

        kiIssueSRControllerObj.refreshDateTime();
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