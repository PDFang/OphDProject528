/**
 * Created by adriana.mcquiston on 10/30/2017.
 */

public with sharing class CCRTriggerHandler extends TriggerHandler{
    private static String changeLogGroup = 'Information Systems Change Log';
    map<string, list<string>> topicMap = new  map<string, list<string>>();

    public override void afterUpdate() {
        createFeedItems((List<ChangeControlRequest__c>)trigger.new, (Map<Id, ChangeControlRequest__c>)trigger.oldMap);
    }

    private void createFeedItems(List<ChangeControlRequest__c> newCCRs, Map<Id, ChangeControlRequest__c> oldMap) {
        Set<Id> corporateITRecordTypeIds = getRecordTypeMap();
        Set<Id> ccrIds = new Set<Id>();
        for(ChangeControlRequest__c ccr : newCCRs) {
            if(corporateITRecordTypeIds.contains(ccr.RecordTypeId)
                    && ccr.Status__c != oldMap.get(ccr.Id).Status__c
                    && ccr.Status__c == 'Closed' && oldMap.get(ccr.Id).Status__c == 'Deployed') {
                ccrIds.add(ccr.Id);
            }
        }

        if(ccrIds.size() > 0) {
            List<CCRApplication__c> applications = [select Description__c, Application__c from CCRApplication__c where ChangeControlRequest__c in :ccrIds];

            List<FeedItem> feedItems = new List<FeedItem>();

            //get the group to post into
            Id changeLogGroupId = [select Id from CollaborationGroup where Name = :changeLogGroup].Id;

            //create the feeditems
            for(CCRApplication__c ccrApplication : applications) {
                FeedItem item = new FeedItem(
                        Title = ccrApplication.Application__c,
                        ParentId = changeLogGroupId,
                        Body = ccrApplication.Description__c
                );

                feedItems.add(item);
            }

            if(feedItems.size() > 0) {
                //insert all the feeditems
                insert feedItems;

                addNewTopics(feedItems);

                //assign the topics to each feeditem
                assignTopicsToFeedItems(feedItems);
            }

        }
    }

    private void assignTopicsToFeedItems(List<FeedItem> feedItems) {
        //get a Set of the topics we need to query for
        Set<String> topicNames = new Set<String>();
        for(FeedItem item : feedItems) {
            topicNames.add(item.Title);
        }

        Map<String, Id> topicNameLookup = new Map<String, Id>();

        List<Topic> topics = [Select Id, Name from Topic where Name in :topicNames];

        for(Topic t : topics) {
            topicNameLookup.put(t.Name, t.Id);
        }

        //create a list of TopicAssignments
        List<TopicAssignment> topicAssignments = new List<TopicAssignment>();
        for(FeedItem item : feedItems) {
            TopicAssignment assignment = new TopicAssignment();
            assignment.TopicId = topicNameLookup.get(item.Title);
            assignment.EntityId = item.Id;
            topicAssignments.add(assignment);
        }

        insert topicAssignments;
    }

    private void addNewTopics(List<FeedItem> feedItems) {
        //check to see if the topic, which is the application field, already exists
        Set<String> usedTopics = new Set<String>();
        for(FeedItem item : feedItems) {
            usedTopics.add(item.Title);
        }

        //remove any topics from usedTopics that already exist
        List<Topic> existingTopics = [Select Id, Name from Topic];

        for(Topic existingTopic : existingTopics) {
            usedTopics.remove(existingTopic.Name);
        }

        //insert the new topics
        List<Topic> newTopics = new List<Topic>();

        for(String newTopicName : usedTopics) {
            newTopics.add(new Topic(
                    Description = newTopicName,
                    Name = newTopicName
            ));
        }

        if(newTopics.size() > 0) {
            insert newTopics;
        }
    }

    private static Set<Id> getRecordTypeMap() {
        Set<Id> recordTypes = new Set<Id>();
        Schema.DescribeSObjectResult d = Schema.SObjectType.ChangeControlRequest__c;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        for (Schema.RecordTypeInfo recordType : rtMapByName.values()) {
            String recordTypeName = recordType.getName();
            if(recordTypeName == 'Corporate IT'
                    || recordTypeName == 'Corporate IT Approved'
                    || recordTypeName == 'Corporate IT Board Review'
                    || recordTypeName == 'Corporate IT CCB Master Review'
                    || recordTypeName == 'Corporate IT Closed'
                    || recordTypeName == 'Corporate IT Deployed') {
                recordTypes.add(recordType.getRecordTypeId());
            }
        }

        return recordTypes;
    }
}
