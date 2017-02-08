/**
 * Created by mohandaas.rangaswamy on 2/8/2017.
 */

public with sharing class DevelopmentReviewHandler {

    public static void RunLocalTestsAsynchronous(){

        String body =   '{"testLevel":"RunLocalTests"}';

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Salesforce_QA/services/data/v38.0/tooling/runTestsAsynchronous');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(body);
        HttpResponse response = new http().send(request);
        system.debug(response.getStatusCode());
        system.debug(response.getBody());
    }

}