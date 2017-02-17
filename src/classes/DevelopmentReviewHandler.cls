/**
 * Created by mohandaas.rangaswamy on 2/8/2017.
 */
// Development Review Automation
public with sharing class DevelopmentReviewHandler {

    /*
    * Runs all local tests in the connected Org
    * Connected Org endpoint and authentication settings are specified in named credential : Salesforce_QA
    * */

    @Future(callout=true)
    public static void RunLocalTestsAsynchronous(){

        String body = '{"testLevel":"RunLocalTests"}';

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Salesforce_QA/services/data/v38.0/tooling/runTestsAsynchronous');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(body);
        HttpResponse response = new http().send(request);
        system.debug('RunLocalTestsAsynchronous(): response body - ' + response.getBody());
        String asyncJobId = null;
        if(response.getStatusCode() == 200){
            asyncJobId = response.getBody();
        }

        system.debug('RunLocalTestsAsynchronous(): asyncJobId - ' + asyncJobId);
    }

}