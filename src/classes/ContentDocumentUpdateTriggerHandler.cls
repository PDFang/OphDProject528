public class ContentDocumentUpdateTriggerHandler extends TriggerHandler {

    protected override void afterDelete()
    {
        system.debug('**** after delete ****');
        DeletePartnerDocumentManager((List<ContentDocument>) trigger.old);
    }

    // Deletes associated partner document manager record
    private void DeletePartnerDocumentManager(List<ContentDocument> oldList){
        system.debug('deletePartnerDocumentManager(): oldList - '+ oldList);

        List<Partner_Document_Manager__c> deleteList = new List<Partner_Document_Manager__c>();
        Set<Id> contentDocumentIds = new Set<Id>();

        for (ContentDocument contentDoc : oldList) {
            contentDocumentIds.add(contentDoc.Id);
        }

        system.debug('deletePartnerDocumentManager(): contentDocumentIds - '+ contentDocumentIds);

        // Prepare a list of partner document manager records to delete
        for(Partner_Document_Manager__c pdManager : [
                SELECT Id, Name FROM Partner_Document_Manager__c
                WHERE ContentDocumentId__c IN : contentDocumentIds
        ]){
            deleteList.add(pdManager);
        }

        system.debug('deletePartnerDocumentManager(): deleteList - '+ deleteList);


        if(deleteList.size() > 0){
            delete deleteList;
        }
    }
}