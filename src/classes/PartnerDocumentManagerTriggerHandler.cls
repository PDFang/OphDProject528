/**
 * Created by mohandaas.rangaswamy on 4/17/2017.
 */

public class PartnerDocumentManagerTriggerHandler extends TriggerHandler{

    private static Integer expiresInMinutes = 120;


    protected override void afterInsert(){
        RelateToContentVersion((List<Partner_Document_Manager__c>) trigger.new);
    }

    private void RelateToContentVersion(List<Partner_Document_Manager__c> newList){

        Set<Id> documentIds = new Set<Id>();
        for(Partner_Document_Manager__c record :newList){
            if(record.ContentDocumentId__c != null)
                documentIds.add(record.ContentDocumentId__c);
        }

        if(documentIds.isEmpty()){
            return;
        }
        Map<Id, ContentDocument> documentMap = new Map<Id, ContentDocument>([
                SELECT Id, LatestPublishedVersionId FROM ContentDocument
                Where Id IN :documentIds

        ]);
//        for(ContentVersion version : [SELECT Id, ContentDocumentId FROM ContentVersion where ContentDocumentId IN :documentIds]){
//            documentVersionMap.put(version.ContentDocumentId, version);
//        }

        List<ContentVersion> versionsList= new List<ContentVersion>();
        for(Partner_Document_Manager__c record :newList){
            if(documentMap.containsKey(record.ContentDocumentId__c)){
                ContentVersion version = new ContentVersion(
                        Id = documentMap.get(record.ContentDocumentId__c).LatestPublishedVersionId,
                        Partner_Document_Manager__c = record.Id
                );
                versionsList.add(version);
            }
        }

        if(versionsList.size() > 0)
            update versionsList;

        CreateContentDelivery(documentIds);

    }

    @Future
    private static void CreateContentDelivery(Set<Id> documentIds){

        AppConfiguration__c config = AppConfiguration__c.getInstance();
        if(config != null && config.Partner_Document_URL_Timeout__c != null) {
            expiresInMinutes = (Integer)config.Partner_Document_URL_Timeout__c;
        }

        Map<Id, Partner_Document_Manager__c> documentManagerMap = new Map<Id, Partner_Document_Manager__c>();
        for(Partner_Document_Manager__c record : [
                Select Id, ContentDocumentId__c, Allow_Original_Download__c, Notify_On_Visit__c
                from Partner_Document_Manager__c
                where ContentDocumentId__c IN :documentIds
        ]){
            documentManagerMap.put(record.ContentDocumentId__c, record);
        }

        Map<Id, ContentDocument> documentMap = new Map<Id, ContentDocument>([
                SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument
                Where Id IN :documentIds

        ]);

        List<ContentDistribution> distributionList = new List<ContentDistribution>();
        for(ContentDocument document :documentMap.values()){
            ContentDistribution cd = new ContentDistribution();
            cd.name = document.Title;
            cd.ContentVersionId = document.LatestPublishedVersionId;
            cd.PreferencesAllowOriginalDownload = documentManagerMap.get(document.Id).Allow_Original_Download__c;
            cd.PreferencesAllowPDFDownload = true;
            cd.PreferencesAllowViewInBrowser = true;
            cd.PreferencesExpires = true;
            cd.PreferencesLinkLatestVersion = true;
            cd.PreferencesNotifyOnVisit = documentManagerMap.get(document.Id).Notify_On_Visit__c;
            cd.ExpiryDate = system.now().addMinutes(expiresInMinutes);
            distributionList.add(cd);
        }
        insert distributionList;

        List<Partner_Document_Manager__c> managerList = new List<Partner_Document_Manager__c>();
        for(ContentDistribution distribution : [
                Select Id, ContentDocumentId, DistributionPublicUrl from ContentDistribution
                where ContentDocumentId IN :documentIds
        ]){
            Partner_Document_Manager__c record = new Partner_Document_Manager__c(
                    Id = documentManagerMap.get(distribution.ContentDocumentId).Id,
                    Content_Delivery_URL__c = distribution.DistributionPublicUrl
            );
            managerList.add(record);

        }
        update managerList;

    }

}