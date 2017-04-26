/**
 * Created by mohandaas.rangaswamy on 2/27/2017.
 */
@isTest
public class FeedCommentTriggerHandlerTest {

    static FeedItem newPost;
    static Integer testRunTime = 5;

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

    static testmethod void testRunQAUnitTests(){

        FeedCommentTriggerHandler.DEVELOPMENT_REVIEW_CHATTER_GROUP = 'Test Salesforce Development Review';

        setupTestData();
        test.setMock(HttpCalloutMock.class, new RunTestsAsynchronousMock());
        test.startTest();
        FeedComment reviewComment = new FeedComment(
                FeedItemId = newPost.Id,
                CommentBody = '~Run Tests~'
        );
        insert reviewComment;
        test.stopTest();

        String datetimeString = system.now().addMinutes(testRunTime).format();
        String jobName = 'Apex Test Results Emailer ' + datetimeString;
        CronTrigger[] jobs = [Select Id From CronTrigger where CronJobDetail.Name = :jobName];
        system.assertEquals(1, jobs.size());

    }

    static testmethod void testNoChatterGroup(){

        FeedCommentTriggerHandler.DEVELOPMENT_REVIEW_CHATTER_GROUP = 'Test Salesforce Development Review';
        setupTestData();

        test.startTest();
        FeedCommentTriggerHandler.DEVELOPMENT_REVIEW_CHATTER_GROUP = 'No Test Salesforce Development Review';
        FeedComment reviewComment = new FeedComment(
                FeedItemId = newPost.Id,
                CommentBody = '~Run Tests~'
        );
        insert reviewComment;
        test.stopTest();

    }

    static void setupTestData(){

        AppConfiguration__c config = new AppConfiguration__c(
                Test_Run_Time__c = testRunTime
        );
        insert config;

        CollaborationGroup developmentReviewGroup = new CollaborationGroup(
                Name = FeedCommentTriggerHandler.DEVELOPMENT_REVIEW_CHATTER_GROUP,
                CollaborationType = 'Public'

        );
        insert developmentReviewGroup;

        newPost = new FeedItem(
                Title = 'Change Submitted for Development Review',
                ParentId = developmentReviewGroup.Id,
                Body = 'TestRunQAUnitTests'
        );
        insert newPost;

    }
}