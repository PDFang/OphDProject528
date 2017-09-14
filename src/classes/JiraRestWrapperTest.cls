@isTest
public class JiraRestWrapperTest {
    public static testMethod void createJiraBug_WillReturnCorrectJson(){
        JiraRestWrapperMockHttpGenerator httpMock = new JiraRestWrapperMockHttpGenerator(200,'Complete','[{"CaseId": "testCase"}]',null);

        string caseId = 'testCase';

        test.startTest();

        // start calling out the wrapper but using Mock
        Test.setMock(HttpCalloutMock.class, httpMock);
        JiraRestWrapper service = new JiraRestWrapper();
        string jiraKey = service.CreateJIRABug(caseId);

        test.stopTest();

        system.debug('JiraRestWrapperTest - Return Mock Response Json ' + jiraKey);
        system.assertEquals(jiraKey, 'testIssueKey');
    }
}