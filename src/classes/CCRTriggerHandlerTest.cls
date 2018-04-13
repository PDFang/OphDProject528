
@IsTest
public with sharing class CCRTriggerHandlerTest {
    static testMethod void CCRCreateFeedItemsTest() {
        ChangeControlRequest__c ccr = insertTestData();
        CCRTriggerHandler.changeLogGroup = 'Unit Test Chatter Group';

        List<CCRApplication__c> ccrApplications = new List<CCRApplication__c>();
        ccrApplications.add(new CCRApplication__c(
                Application__c = 'Support Site Unit Test',
                ChangeControlRequest__c = ccr.Id,
                Description__c = 'test - Support Site'
        ));

        ccrApplications.add(new CCRApplication__c(
                Application__c = 'Where Is Unit Test',
                ChangeControlRequest__c = ccr.Id,
                Description__c = 'test - Where Is'
        ));
        insert ccrApplications;

        ccr.Status__c = 'Deployed';
        update ccr;

        test.startTest();

        //set the status to closed
        ccr.Status__c = 'Closed';
        update ccr;

        test.stopTest();

        //verify that FeedItems were created and topics were correctly assigned
        List<FeedItem> feedItems = [select Title, ParentId, Body from FeedItem order by Title];
        List<TopicAssignment> topicAssignments = [select Topic.Name, EntityId from TopicAssignment];

        //there are only two FeedItems, the first one will be the Support Site one
        //the second will be the Where Is
        system.assertEquals(2, feedItems.size());
        system.assertEquals(2, topicAssignments.size());
        Integer index = 0;
        for(FeedItem item : feedItems) {
            system.assertEquals(ccrApplications[index].Description__c, item.Body);
            String topicName = null;
            for(TopicAssignment ta : topicAssignments) {
                if(ta.EntityId == item.Id) {
                    topicName = ta.Topic.Name;
                    break;
                }
            }

            system.assert(topicName != null, 'Topic was not assigned for ' + item.Title);
            system.assertEquals(ccrApplications[index].Application__c, topicName, 'Topic was not assigned correctly for ' + item.Title);
            index++;
        }
    }

    private static ChangeControlRequest__c insertTestData() {
        List<RecordType> ccrRecordType = [select Id from RecordType where Name = 'Corporate IT' and SobjectType = 'ChangeControlRequest__c'];
        //Call ChangeControlRequest object
        ChangeControlRequest__c changeControlRequest =
                new ChangeControlRequest__c(
                        Summary__c = 'Testing CCRs',
                        CCRStartTime__c = system.today(),
                        ChangeReason__c = 'Fix',
                        Monitoring_set_up_on_device__c = 'Yes',
                        Impact__c = 'SEV 1',
                        Urgency__c = 'HIGH',
                        RFCType__c = 'NORMAL',
                        Cluster__c = 'B2;B3',
                        ReleasePicklist__c = 'Architecture',
                        ContingencyOwner__c = userInfo.getUserId(),
                        ContingencyDeadline__c = system.today() + 4,
                        Description__c = 'Test summary',
                        DescriptionOfTesting__c = 'Test summary',
                        ContingencyPlan__c = 'Test summary',
                        ReleaseDate__c = system.today() + 4,
                        SystemsAppsProcessesImpacted__c = 'Test summary',
                        Experience__c = '0 - This has been successfully completed before',
                        PrepTimeRequired__c = '3 - 15-30 days',
                        RequiresUserEducation__c = '2 - Minimal',
                        BusinessImpact__c = '3 - Major, not high profile',
                        Documentation__c = '4 - Considerable amount',
                        ResourcesRequired__c = '2 - 2 people, same group',
                        MaintenanceWindow__c = '8 - Outside',
                        Security__c = '2 - Access affected',
                        Validation__c = '3 - Minor',
                        Backout__c = '2 - In place, easy to do',
                        OutageScope__c = '6 - Partial System',
                        RecordTypeId = ccrRecordType[0].Id
                );

        insert changeControlRequest;

        //create each type of task
        List<RecordType> recordTypes = [select Id from RecordType where Name in ('Communication Task', 'Validation Task', 'Work Task') and SobjectType = 'CCRTask__c'];

        List<CCRTask__c> ccrTasks = new List<CCRTask__c>();
        for(RecordType r : recordTypes) {
            ccrTasks.add(new CCRTask__c(
                    Order__c = 1,
                    AssignedTo__c = userinfo.getUserId(),
                    Description__c = 'Validation',
                    Duration__c = 1,
                    Status__c = 'OPEN',
                    RecordTypeID = r.id,
                    ChangeControlRequest__c = changeControlRequest.Id
            ));
        }

        insert ccrTasks;

        CollaborationGroup feedItemGroup = new CollaborationGroup(
                Name = 'Unit Test Chatter Group',
                CollaborationType = 'Private'
        );
        insert feedItemGroup;

        //insert the new topics
        List<Topic> newTopics = new List<Topic>();

        newTopics.add(new Topic(
                Description = 'Support Site Unit Test',
                Name = 'Support Site Unit Test'
        ));

        newTopics.add(new Topic(
                Description = 'Where Is Unit Test',
                Name = 'Where Is Unit Test'
        ));

        insert newTopics;

        return changeControlRequest;
    }
}