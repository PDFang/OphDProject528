/**
 * Created by mohandaas.rangaswamy on 4/20/2017.
 */

@IsTest
private class PartnerDocumentManagerTriggerHandlerTest {

    @TestSetup
    static void createTestData(){

        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName();
        Id partnerDocRecordTypeId = rtMapByName.get('Partner Document').getRecordTypeId();

        ContentVersion partnerDoc = new ContentVersion(
                Title = 'Test Partner Doc',
                PathOnClient = 'Test1',
                VersionData = Blob.valueOf('Test Partner Doc'),
                RecordTypeId = partnerDocRecordTypeId
        );

        insert partnerDoc;

    }


    static testMethod void trelateToContentVersionTest() {

        ContentVersion partnerDoc = [SELECT ContentDocumentId,Id,Title FROM ContentVersion LIMIT 1];
        test.startTest();
        Partner_Document_Manager__c docManager = new Partner_Document_Manager__c(
                ContentDocumentId__c = partnerDoc.ContentDocumentId,
                LatestVersionId__c = partnerDoc.Id,
                Title__c = partnerDoc.Title
        );
        insert docManager;
        test.stopTest();

        ContentVersion[] versionList = [SELECT Id, Partner_Document_Manager__c FROM ContentVersion where Id = :partnerDoc.Id];
        system.assertEquals(docManager.Id, versionList[0].Partner_Document_Manager__c, 'A link should have been established between the content verison and document manager.');

    }
}