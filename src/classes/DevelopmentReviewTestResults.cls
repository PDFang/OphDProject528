/**
 * Created by mohandaas.rangaswamy on 2/24/2017.
 */

global class DevelopmentReviewTestResults implements Schedulable {

    String asyncJobId;

    static final Integer INTERVAL = 15;

    global DevelopmentReviewTestResults(String asyncJobId) {
        this.asyncJobId = asyncJobId;
        system.debug('DevelopmentReviewTestResults(): asyncJobId - ' + asyncJobId);
    }

    global void execute(SchedulableContext sc) {

        emailTestRunResult(asyncJobId);

    } // end of execute()

    @future(callout=true)
    private static void emailTestRunResult(String asyncJobId){

        system.debug('getTestRunResult(): asyncJobId - ' + asyncJobId);
        try {
            String query = 'Select+AsyncApexJobId,ClassesEnqueued,ClassesCompleted,MethodsCompleted,MethodsFailed,StartTime,Status,UserId,TestTime+from+ApexTestRunResult+where'
                    + '+AsyncApexJobId=\'' + asyncJobId + '\'';
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Salesforce_QA/services/data/v38.0/tooling/query/?q=' + query);
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json');
            HttpResponse response = new http().send(request);
            system.debug('emailTestRunResult(): response body - ' + response.getBody());

            ApexTestRunResult testRunResult = null;
            if (response.getStatusCode() == 200) {
                JSONParser parser = JSON.createParser(response.getBody());
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                        while (parser.nextToken() != null) {
                            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                                testRunResult = (ApexTestRunResult) parser.readValueAs(ApexTestRunResult.class);
                                system.debug('emailTestRunResult(): ApexTestRunResult - ' + testRunResult);
                            }

                        }
                    }
                }
            } else {
                inContactBaseClass.SendErrorEmail(response.getStatus(), asyncJobId);
                return;
            }

            if (testRunResult != null && (testRunResult.Status == 'Queued' || testRunResult.status == 'Processing')) {
                DevelopmentReviewHandler.scheduleJob(asyncJobId);
                return;
            }

            if (testRunResult != null && (testRunResult.MethodsFailed > 0 || testRunResult.ClassesEnqueued != testRunResult.ClassesCompleted)) {
                emailTestFailures(asyncJobId);
            }

            if (testRunResult != null && testRunResult.Status == 'Completed') {
                sendSummaryEmail(testRunResult);
            }

        }catch(system.EmailException ex){

        }catch(system.Exception ex){
            system.debug('emailTestRunResult(): Exception - ' + ex);
            inContactBaseClass.SendErrorEmail(ex, asyncJobId);
        }

    }

    private static void emailTestFailures(String asyncJobId){

        system.debug('emailTestFailures(): asyncJobId - ' + asyncJobId);
        String query  = 'Select+AsyncApexJobId,ApexClassId,Message,MethodName,Outcome,StackTrace,RunTime+from+ApexTestResult+where'
                +'+AsyncApexJobId=\''+asyncJobId+'\'+and+Outcome!=\'Pass\'';
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Salesforce_QA/services/data/v38.0/tooling/query/?q=' + query);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        HttpResponse response = new http().send(request);
        system.debug('emailTestFailures(): response body - ' + response.getBody());

        ApexTestResult[] testResults = new ApexTestResult[]{};
        if(response.getStatusCode() == 200) {
            JSONParser parser = JSON.createParser(response.getBody());
            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                    while (parser.nextToken() != null) {
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                            ApexTestResult testResult = (ApexTestResult) parser.readValueAs(ApexTestResult.class);
                            testResults.add(testResult);
                            system.debug('emailTestFailures(): testResult - ' + testResult);
                        }

                    }
                }
            }
            if(testResults.size() > 0)
                sendDetailEmail(testResults);
        } else{
            inContactBaseClass.SendErrorEmail(response.getStatus(), asyncJobId);
        }

    }

    private static void sendSummaryEmail(ApexTestRunResult testRun){

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setSenderDisplayName('SalesforceAdmins');
        message.setSubject('Salesforce Development Review Test Run Summary');
        message.setToAddresses(new String[]{userInfo.getUserEmail()});

        String thead = '<tr>'
                + '<th>AsyncApexJobId</th>'
                + '<th>Status</th>'
                + '<th>StartTime</th>'
                + '<th>ClassesEnqueued</th>'
                + '<th>ClassesCompleted</th>'
                + '<th>MethodsCompleted</th>'
                + '<th>MethodsFailed</th>'
                + '<th>TestTime</th>'
                + '</tr>';
        String tdetail = '<tr>'
                + '<td>{0}</td>'
                + '<td>{1}</td>'
                + '<td>{2}</td>'
                + '<td>{3}</td>'
                + '<td>{4}</td>'
                + '<td>{5}</td>'
                + '<td>{6}</td>'
                + '<td>{7}</td>'
                + '</tr>';
        tdetail = string.format(tdetail, new String[]{
                testRun.AsyncApexJobId,
                testRun.Status,
                testRun.StartTime.format(),
                testRun.ClassesEnqueued.format(),
                testRun.ClassesCompleted.format(),
                testRun.MethodsCompleted.format(),
                testRun.MethodsFailed.format(),
                testRun.TestTime.format()
        });
        String htmlBody = '<table border="1" cellpadding="5" cellspacing="0">'+thead+tdetail+'</table>';
        message.setHtmlBody(htmlBody);
        messaging.sendEmail(new  Messaging.SingleEmailMessage[]{message});

    } // end sendSummaryEmail()

    private static void sendDetailEmail(ApexTestResult[] testResults){

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setSenderDisplayName('SalesforceAdmins');
        message.setSubject('Salesforce Development Review Test Failures');
        message.setToAddresses(new String[]{userInfo.getUserEmail()});

        String thead = '<tr>'
                + '<th>AsyncApexJobId</th>'
                + '<th>ApexClassId</th>'
                + '<th>MethodName</th>'
                + '<th>Outcome</th>'
                + '<th>Message</th>'
                + '<th>StackTrace</th>'
                + '<th>RunTime</th>'
                + '</tr>';
        String tdetailTemplate = '<tr>'
                + '<td>{0}</td>'
                + '<td>{1}</td>'
                + '<td>{2}</td>'
                + '<td>{3}</td>'
                + '<td>{4}</td>'
                + '<td>{5}</td>'
                + '<td>{6}</td>'
                + '</tr>';

        String tdetail = '';
        for(ApexTestResult testResult : testResults){
            tdetail +=  string.format(tdetailTemplate, new String[]{
                    testResult.AsyncApexJobId,
                    testResult.ApexClassId,
                    testResult.MethodName,
                    testResult.Outcome,
                    testResult.Message,
                    testResult.StackTrace,
                    testResult.RunTime.format()
            });
        }

        String htmlBody = '<table border="1" cellpadding="5" cellspacing="0">'+thead+tdetail+'</table>';
        message.setHtmlBody(htmlBody);
        messaging.sendEmail(new  Messaging.SingleEmailMessage[]{message});

    } // end sendDetailEmail()


}