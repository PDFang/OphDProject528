public class JiraRestWrapper {

    static final string createUrl = '/issue/CreateIssue';

    string issueTypeId = '10004';
    string project = 'IC';
    integer timeout = 60000;
    Boolean jiraIntegrationTurnedOff = false;

    public class JiraCalloutException extends Exception{}

    private class CreateRequest{
        protected String SObjectType;
        protected String Id;
        protected String Project;
        protected String IssueType;
    }

    public class CreateResponse{
        protected String issueKey;
        protected String[] errors;
    }

    public JiraRestWrapper(){

        AppConfiguration__c config = AppConfiguration__c.getInstance();
        if(config != null){
            issueTypeId = String.isNotBlank(config.Default_JIRA_Issue_Type_ID__c) ? config.Default_JIRA_Issue_Type_ID__c : issueTypeId;
            project = String.isNotBlank(config.Default_JIRA_Project__c) ? config.Default_JIRA_Project__c : project;
            jiraIntegrationTurnedOff = config.Turn_Off_JIRA_Integration__c;
            timeout = (Integer)config.Default_JIRA_Timeout__c;
        }

    }

    public String CreateJIRABug(String caseId) {

        String jiraKey = null;

        system.debug('CreateJIRABug(): caseId - ' + caseId);

        if(jiraIntegrationTurnedOff){
            system.debug('CreateJIRABug(): JIRA Integration is Turned Off Good Bye ');
            return null;
        }

        CreateRequest newRequest = new CreateRequest();
        newRequest.SObjectType = 'Case';
        newRequest.Id = caseId;
        newRequest.Project = project;
        newRequest.IssueType = issueTypeId;

        String body = JSON.serialize(newRequest);
        system.debug('CreateJIRABug(): body - ' + body);

        HttpResponse response = sendRequest(body);

        String returnResponse = response.getBody();
        system.debug('CreateJIRABug(): returnResponse -  ' + returnResponse);

        if (response.getStatusCode() == 200) {
            CreateResponse result = (CreateResponse) JSON.deserialize(returnResponse, CreateResponse.Class);
            system.debug('CreateJIRABug(): result -  ' + result);
            jiraKey = result.issueKey;
        } else{
            throw new JiraCalloutException(returnResponse);
        }

        return jiraKey;

    }

    private HttpResponse sendRequest(string body){

        HttpRequest request = new HttpRequest();
        request.setBody(body);
        request.setEndpoint('callout:JIRA_Proxy_Service' + createUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(timeout);
        system.debug('sendRequest(): request - ' + request);

        Http h = new Http();
        HttpResponse response = h.send(request);
        return response;

    }

}