/**
 * Created by adriana.mcquiston on 10/30/2017.
 */

public with sharing class CCRTriggerHandler extends TriggerHandler{
    private static String changeLogGroup = 'Information Systems Change Log';

    public override void afterUpdate() {
        createFeedItems((List<ChangeControlRequest__c>)trigger.new, (Map<Id, ChangeControlRequest__c>)trigger.oldMap);
    }

    private static void createFeedItems(List<ChangeControlRequest__c> newCCRs, Map<Id, ChangeControlRequest__c> oldMap) {
        Set<Id> ccrIds = new Set<Id>();
        for(ChangeControlRequest__c ccr : newCCRs) {
            if(ccr.Status__c != oldMap.get(ccr.Id).Status__c && ccr.Status__c == 'Closed' && oldMap.get(ccr.Id).Status__c == 'Deployed') {
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


            }

        }
    }
}
