/**
 * Created by mohandaas.rangaswamy on 8/29/2017.
 */

public class JiraRestWrapper {

    private class CreateRequest{
        protected String SObjectType;
        protected String Id;
        protected String Project;
        protected String IssueType;
    }

    private class CreateResponse{
        protected String issueKey;
        protected String[] errors;
    }

    public String CreateJIRABug(String caseId) {

        system.debug('CreateJIRABug(): caseId - ' + caseId);

        HttpRequest request = new HttpRequest();

        CreateRequest newRequest = new CreateRequest();
        newRequest.SObjectType = 'Case';
        newRequest.Id = caseId;
        newRequest.Project = 'IC';
        newRequest.IssueType = '10004';

        //String body = '{"SObjectType": "Case", "Id": "'+ caseId + '", "Project" : "IC", "IssueType" : "10004"}';
        String body = JSON.serialize(newRequest);
        system.debug('CreateJIRABug(): body - ' + body);
        request.setBody(body);

        request.setEndpoint('callout:JIRA_Proxy_Service' + '/issue/CreateIssue');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        system.debug('CreateJIRABug(): request - ' + request);

        Http h = new Http();
        HttpResponse response = h.send(request);

        String returnResponse = response.getBody();
        system.debug('CreateJIRABug(): returnResponse -  ' + returnResponse);

        String jiraKey = null;

        if(response.getStatusCode() == 200){
            CreateResponse result = (CreateResponse)JSON.deserialize(returnResponse, CreateResponse.Class);
            system.debug('CreateJIRABug(): result -  ' + result);
            jiraKey = result.issueKey;
        }


        return jiraKey;

    }

}