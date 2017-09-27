@isTest
private class CaseCreateKnownIssuesExtensionTest {

    static testMethod void createKnownIssueWithoutException() {

        Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();

        Case baseCase = new Case();
        baseCase.Subject = 'subject';
        baseCase.Steps_to_Recreate__c = 'steps to recreate';
        baseCase.RecordTypeId = recordTypeMap.get('Incident').getRecordTypeId();
        baseCase.TfsItemState__c = 'state';
        baseCase.ProductImpacted__c = 'product';
        baseCase.PlatformsImpacted__c = 'platforms';

        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        baseCase.setOptions(dmo);
        insert baseCase;

        /*Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SobjectType.Case.getRecordTypeInfosByName();
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
        insert knownIssueList;*/

        Test.startTest();

        //set mock for creating Jira Item
        JiraRestWrapperMockHttpGenerator httpMock = new JiraRestWrapperMockHttpGenerator(200,'OK','[{"Name": "testCase"}]',null);
        Test.setMock(HttpCalloutMock.class, httpMock);

        Apexpages.currentpage().getParameters().put('recordType', 'Known Issue');

        ApexPages.StandardController controller = new ApexPages.StandardController(baseCase);
        CaseCreateKnownIssueExtension extension = new CaseCreateKnownIssueExtension(controller);

        system.assertEquals(true, extension.canCreateKnownIssue);

        extension.Save();

        Test.stopTest();

        Case[] knownIssues = [Select Id from Case where RecordType.Name = 'Known Issue'];
        system.assertEquals(1, knownIssues.size());

        Case incident = [Select Id, KnownIssue__c from Case where Id = :baseCase.Id];
        system.assertEquals(knownIssues[0].Id, incident.KnownIssue__c);

        extension.ClearKnownIssue();

    }
}