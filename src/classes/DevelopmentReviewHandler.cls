/**
 * Created by mohandaas.rangaswamy on 2/8/2017.
 */
// Development Review Automation
public with sharing class DevelopmentReviewHandler {

    private static Integer TIME_INTERVAL = 60;

    /*
    * Runs all local tests in the connected Org
    * Connected Org endpoint and authentication settings are specified in named credential : Salesforce_QA
    * */

    @Future(callout=true)
    public static void RunLocalTestsAsynchronous() {

        try {
            String body = '{"testLevel":"RunLocalTests"}';
            //String body = '{"classNames":"DevelopmentReviewDemoTestOne,DevelopmentReviewDemoTestTwo","testLevel":"RunSpecifiedTests"}';

            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Salesforce_QA/services/data/v38.0/tooling/runTestsAsynchronous');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(body);
            HttpResponse response;
            if(test.isRunningTest()){
                // explicitly call response method to avoid uncommited work pending exception
                FeedCommentTriggerHandlerTest.RunTestsAsynchronousMock newMock = new FeedCommentTriggerHandlerTest.RunTestsAsynchronousMock();
                response = newMock.respond(request);
            } else{
                response = new http().send(request);
            }

            system.debug('RunLocalTestsAsynchronous(): response body - ' + response.getBody());
            String asyncJobId = null;
            if (response.getStatusCode() == 200) {
                asyncJobId = response.getBody().remove('"');
                system.debug('RunLocalTestsAsynchronous(): asyncJobId - ' + asyncJobId);
                scheduleJob(asyncJobId);
            } else {
                inContactBaseClass.SendErrorEmail(response.getStatus(), response.getStatusCode().format());
                return;
            }
        }catch(system.Exception ex){
            system.debug('RunLocalTestsAsynchronous(): Exception - ' + ex);
            inContactBaseClass.SendErrorEmail(ex, '');
        }

    }

    public static void scheduleJob(String asyncJobId){

        AppConfiguration__c config = AppConfiguration__c.getInstance();
        if(config != null && config.Test_Run_Time__c != null) {
            TIME_INTERVAL = (Integer)config.Test_Run_Time__c;
        }
        system.debug('scheduleJob(): TIME_INTERVAL - ' + TIME_INTERVAL);
        Datetime nextRun = system.now().addMinutes(TIME_INTERVAL);
        String dateTimeFormat = '0 {0} {1} {2} {3} ? {4}';
        String scheduledTime = string.format(
                dateTimeFormat,
                new String[]{
                        nextRun.minute().format(),
                        nextRun.hour().format(),
                        nextRun.day().format(),
                        nextRun.month().format(),
                        nextRun.year().format().remove(',')
                }
        );
        system.debug('scheduleJob(): scheduledTime - ' + scheduledTime);
        String scheduledJobId = system.schedule('Apex Test Results Emailer '+nextRun.format(), scheduledTime, new DevelopmentReviewTestResults(asyncJobId));
        system.debug('scheduleJob(): scheduledJobId - ' + scheduledJobId);
    }
}
