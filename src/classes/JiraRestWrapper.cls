public class JiraRestWrapper {

    static final string createUrl = '/issue/CreateIssue';

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

    public String CreateJIRABug(String caseId) {

        String jiraKey = null;

        system.debug('CreateJIRABug(): caseId - ' + caseId);

        CreateRequest newRequest = new CreateRequest();
        newRequest.SObjectType = 'Case';
        newRequest.Id = caseId;
        newRequest.Project = 'IC';
        newRequest.IssueType = '10004';

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

        system.debug('sendRequest(): request - ' + request);

        Http h = new Http();
        HttpResponse response = h.send(request);
        return response;

    }

}