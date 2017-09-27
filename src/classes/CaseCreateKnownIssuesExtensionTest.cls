@isTest
private class CaseCreateKnownIssuesExtensionTest {

    static testMethod void createKnownIssueWithoutException() {

        //set mock for creating Jira Item
        JiraRestWrapperMockHttpGenerator httpMock = new JiraRestWrapperMockHttpGenerator(200,'OK','[{"Name": "testCase"}]',null);
        Test.setMock(HttpCalloutMock.class, httpMock);

        Apexpages.currentpage().getParameters().put('recordType', 'Known Issue');
        Case baseCase = new Case();
        baseCase.Subject = 'subject';
        baseCase.Steps_to_Recreate__c = 'steps to recreate';

        baseCase.TfsItemState__c = 'state';
        baseCase.ProductImpacted__c = 'product';
        baseCase.PlatformsImpacted__c = 'platforms';

        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        baseCase.setOptions(dmo);
        insert baseCase;

        Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SobjectType.Case.getRecordTypeInfosByName();
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

        ApexPages.StandardController controller = new ApexPages.StandardController(baseCase);
        CaseCreateKnownIssueExtension extension = new CaseCreateKnownIssueExtension(controller);

        List<Case> InsertedKnownIssues = [select Id, Priority from Case where Subject = 'KnowIssueImpactCalculationTest'];
        CaseTriggerHandler.createJiraBug = true;
        extension.createJiraBug = true;
        extension.ClearKnownIssue();

        Test.startTest();
        boolean canCreateKnownIssue = extension.canCreateKnownIssue;
        extension.Save();
        baseCase.KnownIssue__c = knownIssueList[0].Id;
        System.assertEquals('P3', InsertedKnownIssues[0].Priority);
        extension.SaveCase();
        Test.stopTest();
    }
}