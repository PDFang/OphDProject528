/**
 * Created by mohandaas.rangaswamy on 2/8/2017.
 */
// Development Review Automation
public with sharing class DevelopmentReviewHandler {

    static final Integer TIME_INTERVAL = 60;

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
            scheduleJob(asyncJobId);
        }

        system.debug('RunLocalTestsAsynchronous(): asyncJobId - ' + asyncJobId);
    }

    private static void scheduleJob(String asyncJobId){

        Datetime nextRun = system.now().addMinutes(TIME_INTERVAL);
        String dateTimeFormat = '0 {0} {1} {2} {3} ? {4}';
        String scheduledTime = string.format(
                dateTimeFormat,
                new String[]{
                        nextRun.minute().format(),
                        nextRun.hour().format(),
                        nextRun.day().format(),
                        nextRun.month().format(),
                        nextRun.year().format()
                }
        );
        String scheduledJobId = system.schedule('Apex Test Results Emailer', scheduledTime, new DevelopmentReviewTestResults(asyncJobId));
        system.debug('scheduleJob(): scheduledJobId - ' + scheduledJobId);
    }
}
