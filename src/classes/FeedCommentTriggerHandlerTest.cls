/**
 * Created by mohandaas.rangaswamy on 2/27/2017.
 */
@isTest
public class FeedCommentTriggerHandlerTest {

    public class RunTestsAsynchronousMock implements HttpCalloutMock{

        public HTTPResponse respond(HTTPRequest req) {

            System.assert(req.getEndpoint().contains('/services/data/v38.0/tooling/runTestsAsynchronous'));
            System.assertEquals('POST', req.getMethod());

            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/plain');
            res.setBody('001aeK');
            res.setStatusCode(200);
            return res;
        }

    }

    static testmethod void TestRunQAUnitTests(){

        FeedCommentTriggerHandler.DEVELOPMENT_REVIEW_CHATTER_GROUP = 'Test Salesforce Development Review';

        CollaborationGroup developmentReviewGroup = new CollaborationGroup(
                Name = 'Test Salesforce Development Review',
                CollaborationType = 'Public'

        );
        insert developmentReviewGroup;

        FeedItem newPost = new FeedItem(
                Title = 'Change Submitted for Development Review',
                ParentId = developmentReviewGroup.Id,
                Body = 'TestRunQAUnitTests'
        );
        insert newPost;

        AppConfiguration__c config = new AppConfiguration__c(
                Test_Run_Time__c = 5
        );
        insert config;

        test.setMock(HttpCalloutMock.class, new RunTestsAsynchronousMock());

        test.startTest();

        FeedComment reviewComment = new FeedComment(
                FeedItemId = newPost.Id,
                CommentBody = '~Run Tests~'
        );
        insert reviewComment;
        test.stopTest();

        String datetimeString = system.now().addMinutes((Integer)config.Test_Run_Time__c).format();
        String jobName = 'Apex Test Results Emailer ' + datetimeString;
        CronTrigger[] jobs = [Select Id From CronTrigger where CronJobDetail.Name = :jobName];
        system.assertEquals(1, jobs.size());

    }
}