@isTest
public class JiraRestWrapperTest {
    public static testMethod void createJiraBug_WillReturnSuccessResponse(){
        JiraRestWrapperMockHttpGenerator httpMock = new JiraRestWrapperMockHttpGenerator(200,'OK','[{"CaseId": "testCase"}]',null);
        string caseId = 'testCase';

        test.startTest();

        // start calling out the wrapper but using Mock
        Test.setMock(HttpCalloutMock.class, httpMock);
        JiraRestWrapper service = new JiraRestWrapper();
        string jiraKey = service.CreateJIRABug(caseId);

        test.stopTest();

        system.debug('JiraRestWrapperTest - WillReturnSuccessResponse : ' + jiraKey);
        system.assertEquals(jiraKey, 'testIssueKey');
    }

    public static testMethod void createJiraBug_WillReturnFailureException(){
        JiraRestWrapperMockHttpGenerator httpMock = new JiraRestWrapperMockHttpGenerator(400,'Bad Request','[{"CaseId": "testCase"}]',null);
        string caseId = 'testCase';
        JiraRestWrapper.JiraCalloutException testException = null;

        test.startTest();

        // start calling out the wrapper but using Mock
        Test.setMock(HttpCalloutMock.class, httpMock);
        JiraRestWrapper service = new JiraRestWrapper();

        try{
            string createdRecord = service.CreateJIRABug(caseId);
        } catch(JiraRestWrapper.JiraCalloutException calloutException){
            testException = calloutException;
        }


        test.stopTest();

        system.debug('JiraRestWrapperTest - WillReturnFailureException : ' + testException.getMessage());
        system.assert('{"issueKey": "", "error": [ "errorresponse" ]}' == testException.getMessage());

    }
}