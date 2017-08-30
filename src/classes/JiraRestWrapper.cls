/**
 * Created by mohandaas.rangaswamy on 8/29/2017.
 */

public class JiraRestWrapper {

    public String CreateJIRABug(String caseId) {

        HttpRequest request = new HttpRequest();

        String body = '{"SObjectType": "Case", "Id": "'+ caseId + '", "Project" : "IC", "IssueType" : "10004"}';

        request.setBody(body);

        //request.setEndpoint('http://tlvjiratst02:8080/rest/customware/connector/1.0/1/Case/' + c.Id + '/issue/create.json');

        request.setEndpoint('https://labproxy.ucn.net/JIRAProxy/api/issue/CreateIssue');

        request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf('salesforceuser' + ':' + '1qaz2wsx')));

        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');


        system.debug('CreateJIRABug(): request - ' + request);
        Http h = new Http();


        HttpResponse response = h.send(request);
        system.debug('CreateJIRABug(): response -  ' + response.getBody());

        String returnResponse = response.getBody();

        return returnResponse;

    }

}