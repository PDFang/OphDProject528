@isTest
public with sharing class ContentDocumentTriggerHandlerTests {
    static testMethod void testDeletePartnerDocumentManager() {
        List<ContentVersion> contentVersions = new List<ContentVersion>();

        for(Integer i = 0; i < 3; i++) {
            contentVersions.add(new ContentVersion(
                    Title = 'Test Doc ' + i,
                    PathOnClient = 'test' + i + '.doc',
                    VersionData = Blob.valueOf('Test Doc ' + i),
                    IsMajorVersion = true
                )
            );
        }

        insert contentVersions;

        List<ContentDocument> docs = [select Id from ContentDocument];

        system.debug(docs);

        List<Partner_Document_Manager__c> docManagers = new List<Partner_Document_Manager__c>();
        docManagers.add(new Partner_Document_Manager__c(ContentDocumentId__c = docs[0].Id, LatestVersionId__c = contentVersions[0].Id));
        docManagers.add(new Partner_Document_Manager__c(ContentDocumentId__c = docs[1].Id, LatestVersionId__c = contentVersions[1].Id));
        docManagers.add(new Partner_Document_Manager__c(ContentDocumentId__c = docs[2].Id, LatestVersionId__c = contentVersions[2].Id));

        insert docManagers;

        List<String> docManagerIds = new List<String>();
        docManagerIds.add(docManagers[0].Id);
        docManagerIds.add(docManagers[1].Id);
        docManagerIds.add(docManagers[2].Id);

        test.startTest();
        delete docs;
        test.stopTest();

        //ensure that the docManagers were deleted
        List<Partner_Document_Manager__c> resultDocs = [select Id from Partner_Document_Manager__c where Id in :docManagerIds];

        system.debug(resultDocs);

        system.assert(resultDocs.isEmpty());
    }
}