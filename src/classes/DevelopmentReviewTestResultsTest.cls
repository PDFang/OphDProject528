/**
 * Created by mohandaas.rangaswamy on 3/31/2017.
 */

@IsTest
private class DevelopmentReviewTestResultsTest {

    public class QueryApexTestRunResultMock implements HttpCalloutMock{

        private Integer methodsFailed;

        public QueryApexTestRunResultMock(Integer methodsFailed){
            this.methodsFailed = methodsFailed;
        }

        public HTTPResponse respond(HTTPRequest req) {

            System.assert(req.getEndpoint().contains('/services/data/v38.0/tooling/query/'));
            System.assertEquals('GET', req.getMethod());

            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/plain');
            string apexTestRunResult = '{"entityTypeName":"ApexTestRunResult","records":[{"AsyncApexJobId":"7075B00000E0w4TQAR","Status":"Completed","ClassesEnqueued":10,"ClassesCompleted":10,"MethodsCompleted":40,"MethodsFailed":'+ methodsFailed +',"StartTime":"2017-04-05T17:03:09.000+0000","UserId":"00539000005GcshAAC","TestTime":140241}]}';
            res.setBody(apexTestRunResult);
            res.setStatusCode(200);
            return res;
        }

    }

    // explicitly calls the method asking to send summary email
    static testMethod void testSummaryEmail() {

        test.setMock(HttpCalloutMock.class, new QueryApexTestRunResultMock(0));
        test.startTest();
        DevelopmentReviewTestResults.emailTestRunResult('axyz');
        test.stopTest();

    }

    // explicitly calls the method asking to send error email
    static testMethod void testErrorDetailEmail() {

        test.setMock(HttpCalloutMock.class, new QueryApexTestRunResultMock(1));
        test.startTest();
        DevelopmentReviewTestResults.emailTestRunResult('azxyz');
        test.stopTest();

    }

}