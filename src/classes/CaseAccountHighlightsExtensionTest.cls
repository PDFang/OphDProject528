@isTest
public class CaseAccountHighlightsExtensionTest {

    static testMethod void createJIRABugWithoutException() {

        //set mock for creating Jira Item
        JiraRestWrapperMockHttpGenerator httpMock = new JiraRestWrapperMockHttpGenerator(200,'OK','[{"Name": "testCase"}]',null);
        Test.setMock(HttpCalloutMock.class, httpMock);

        CaseAssignmentClass.isTest = true;
        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        Case knownIssue = new Case();
        knownIssue.RecordTypeId = rtMapByName.get('Known Issue').getRecordTypeId();
        knownIssue.Subject = 'Test Known Issue';
        knownIssue.ProductImpacted__c = 'Test Product';
        insert knownIssue;

        Test.startTest();
        ApexPages.StandardController controller = new ApexPages.StandardController(knownIssue);
        CaseAccountHighlightsExtension extension = new CaseAccountHighlightsExtension(controller);
        extension.target = 'testTarget';
        extension.CreateJIRABug();
        extension.Save();
        Test.stopTest();
    }
}