/**
 * Created by mohandaas.rangaswamy on 4/17/2017.
 */

public without sharing class PartnerDocumentManagerTriggerHandler extends TriggerHandler{

    protected override void afterInsert(){
        RelateToContentVersion((List<Partner_Document_Manager__c>) trigger.new, (Map<Id, Partner_Document_Manager__c>) trigger.oldMap);
    }

    protected override void afterUpdate(){
        RelateToContentVersion((List<Partner_Document_Manager__c>) trigger.new, (Map<Id, Partner_Document_Manager__c>) trigger.oldMap);
    }

    // establishes a link between Partner Document Manager and the latest content version
    private void relateToContentVersion(List<Partner_Document_Manager__c> newList, Map<Id, Partner_Document_Manager__c> oldMap){

        Set<Id> versionIds = new Set<Id>();
        system.debug('relateToContentVersion(): newList - '+ newList);
        for(Partner_Document_Manager__c record :newList){
            Partner_Document_Manager__c oldRecord = (oldMap != null) ? oldMap.get(record.Id) : null;
            if(record.ContentDocumentId__c != null && (oldRecord == null || oldRecord.LatestVersionId__c != record.LatestVersionId__c) )
                versionIds.add(record.LatestVersionId__c);
        }
        system.debug('relateToContentVersion(): versionIds - '+ versionIds);
        if(versionIds.isEmpty()){
            return;
        }

        Map<Id, ContentVersion> versionsMap = new Map<Id, ContentVersion>();
        for(Partner_Document_Manager__c record :newList){
            ContentVersion version = new ContentVersion(
                    Id = record.LatestVersionId__c,
                    Partner_Document_Manager__c = record.Id
            );
            versionsMap.put(record.LatestVersionId__c, version);
        }

        if(versionsMap.size() > 0){
            update versionsMap.values();
        }

    }

}