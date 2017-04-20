@isTest
public class ContentVersionTriggerHandlerTests 
{
    private static ID supportSiteRecordTypeId;
    private static ID partnerDocRecordTypeId;

    static void setup()
    {
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName();

        supportSiteRecordTypeId = rtMapByName.get('Support Site Link').getRecordTypeId();
        partnerDocRecordTypeId = rtMapByName.get('Partner Document').getRecordTypeId();
        
        //add test records
        List<ContentVersion> existingContentList = new List<ContentVersion>();
        existingContentList.add(new ContentVersion(SupportSiteKey__c = 'TEST', SupportSiteRedirectKeys__c = 'VOIPe911', SupportSiteLinkOrder__c = 10,
                                                   Title = 'Title Test', PathOnClient = 'Test', VersionData = Blob.valueOf('Testing'), 
                                                   RecordTypeId = supportSiteRecordTypeId));
        existingContentList.add(new ContentVersion(SupportSiteKey__c = 'TEST1', SupportSiteRedirectKeys__c = 'Colocation', SupportSiteLinkOrder__c = 20,
                                                   Title = 'Title Test 1', PathOnClient = 'Test1', VersionData = Blob.valueOf('Testing1'),
                                                   RecordTypeId = supportSiteRecordTypeId));
        existingContentList.add(new ContentVersion(
                Title = 'Test Partner Doc', PathOnClient = 'Test1',
                VersionData = Blob.valueOf('Test Partner Doc'),
                RecordTypeId = partnerDocRecordTypeId)
        );

        insert existingContentList;

    }

    // verify Partner Document Manager record is created
    static testmethod void upsertPartnerDocManagerTest(){

        setup();
        List<ContentVersion> contentList = [
                SELECT Id, Title FROM ContentVersion
                WHERE RecordTypeId = :partnerDocRecordTypeId LIMIT 1
        ];
        test.startTest();
        contentList[0].Title = 'Test Partner Doc 1';
        update contentList;
        test.stopTest();


        List<Partner_Document_Manager__c> managerList = [
                Select ContentDocumentId__c, LatestVersionId__c
                from Partner_Document_Manager__c
        ];
        system.assertEquals(contentList.size(), managerList.size(), 'Partner Document Manager record should have been created.');

    }
    
    static void verifyRecordNotInserted(ID idOfInsertedRecord)
    {
        //ensure the record was not inserted
        List<ContentVersion> existingContentList = [SELECT SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                                   FROM ContentVersion
                                                   WHERE Id = :idOfInsertedRecord];
        
        System.assertEquals(0, existingContentList.size());
        
        //ensure the previous records still exist
        existingContentList = [SELECT SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                              FROM ContentVersion
                              where RecordTypeId = :supportSiteRecordTypeId];
        System.assertEquals(2, existingContentList.size());
    }
    
    static void verifyRecordNotInserted(ID idOfInsertedRecord, Integer expectedRecordCount)
    {
        //ensure the record was not inserted
        List<ContentVersion> existingContentList = [SELECT SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                                   FROM ContentVersion
                                                   WHERE Id = :idOfInsertedRecord];
        
        System.assertEquals(0, existingContentList.size());
        
        //ensure the previous records still exist
        existingContentList = [SELECT SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                FROM ContentVersion
                                where RecordTypeId = :supportSiteRecordTypeId];
        System.assertEquals(expectedRecordCount, existingContentList.size());
    }	    
    
    @isTest
    static void BeforeInsert_FailsWithSupportSiteKeyWithDifferentCasing()
    {
        //the support site key should be unique, regardless of the casing
        setup();
        ContentVersion testContent = new ContentVersion(SupportSiteKey__c = 'Test', SupportSiteRedirectKeys__c = NULL, SupportSiteLinkOrder__c = 15,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'), 
                                                       RecordTypeId = supportSiteRecordTypeId);
        
        test.startTest();
        Database.insert(testContent, false);
        test.stopTest();
        
        verifyRecordNotInserted(testContent.Id);
    }
    
    @isTest
    static void BeforeInsert_SucceedsWithUniqueSupportSiteKey()
    {
        setup();
        ContentVersion testContent = new ContentVersion(SupportSiteKey__c = 'TEST2', SupportSiteRedirectKeys__c = NULL, SupportSiteLinkOrder__c = 15,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'), RecordTypeId = supportSiteRecordTypeId);
        
        test.startTest();
        Database.insert(testContent, false);
        test.stopTest();
        
        List<ContentVersion> existingContentList = [SELECT SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                                    FROM ContentVersion
                                                    WHERE Id = :testContent.Id and RecordTypeId = :supportSiteRecordTypeId];
        
        System.assertEquals(1, existingContentList.size());
        ContentVersion actualContent = existingContentList.get(0);
        System.assertEquals('TEST2', actualContent.SupportSiteKey__c);
        System.assertEquals(NULL, actualContent.SupportSiteRedirectKeys__c);
        System.assertEquals(15, actualContent.SupportSiteLinkOrder__c);
    }
    
    @isTest
    static void BeforeInsert_SucceedsWhenNotSupportSiteRecordType()
    {
        
        setup();
        ContentVersion testContent = new ContentVersion(SupportSiteKey__c = NULL, SupportSiteRedirectKeys__c = NULL, SupportSiteLinkOrder__c = NULL,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'));
        
        test.startTest();
        Database.saveResult result = Database.insert(testContent, false);
        test.stopTest();
        
        List<ContentVersion> existingContentList = [SELECT SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                                    FROM ContentVersion
                                                    WHERE Id = :testContent.Id];
        
        System.assertEquals(1, existingContentList.size());
        ContentVersion actualContent = existingContentList[0];
        System.assertEquals(NULL, actualContent.SupportSiteKey__c);
        System.assertEquals(NULL, actualContent.SupportSiteRedirectKeys__c);
        System.assertEquals(NULL, actualContent.SupportSiteLinkOrder__c);
    }
    
    @isTest
    static void BeforeInsert_FailsWithNonUniqueSupportSiteKey()
    {
        setup();
        ContentVersion testContent = new ContentVersion(SupportSiteKey__c = 'TEST', SupportSiteRedirectKeys__c = NULL, SupportSiteLinkOrder__c = 15,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'), 
                                                       RecordTypeId = supportSiteRecordTypeId);
        
        test.startTest();
        Database.insert(testContent, false);
        test.stopTest();
        
        verifyRecordNotInserted(testContent.Id);
    }
    
    @isTest
    static void BeforeInsert_FailsWithSupportSiteKeyMatchingSupportSiteRedirectKeys()
    {
        setup();
        ContentVersion testContent = new ContentVersion(SupportSiteKey__c = 'VOIPe911', SupportSiteRedirectKeys__c = NULL, SupportSiteLinkOrder__c = 15,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'), 
                                                       RecordTypeId = supportSiteRecordTypeId);
        
        test.startTest();
        Database.insert(testContent, false);
        test.stopTest();
        
		verifyRecordNotInserted(testContent.Id);
    }
    
    @isTest
    static void BeforeInsert_FailsWithDuplicateSupportSiteRedirectKeys()
    {
        setup();
        ContentVersion testContent = new ContentVersion(SupportSiteKey__c = 'Test 2', SupportSiteRedirectKeys__c = 'VOIPe911', SupportSiteLinkOrder__c = 15,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'), 
                                                       RecordTypeId = supportSiteRecordTypeId);
        
        test.startTest();
        Database.insert(testContent, false);
        test.stopTest();
        
        verifyRecordNotInserted(testContent.Id);
    }
    
    @isTest
    static void BeforeInsert_FailsWithDuplicateSupportSiteLinkOrder()
    {
        setup();
        ContentVersion testContent = new ContentVersion(SupportSiteKey__c = 'Test 2', SupportSiteRedirectKeys__c = NULL, SupportSiteLinkOrder__c = 10,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'), 
                                                       RecordTypeId = supportSiteRecordTypeId);
        
        test.startTest();
        Database.insert(testContent, false);
        test.stopTest();
        
        verifyRecordNotInserted(testContent.Id);
    }
    
    @isTest
    static void BeforeInsert_FailswithNullSupportSiteLinkOrder()
    {
        setup();
        ContentVersion testContent = new ContentVersion(SupportSiteKey__c = 'Test 2', SupportSiteRedirectKeys__c = NULL, SupportSiteLinkOrder__c = NULL,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'), 
                                                       RecordTypeId = supportSiteRecordTypeId);
        
        test.startTest();
        Database.insert(testContent, false);
        test.stopTest();
        
        verifyRecordNotInserted(testContent.Id);
    }
    
    @isTest
    static void BeforeInsert_FailsWithNullSupportSiteKey()
    {
        setup();
        ContentVersion testContent = new ContentVersion(SupportSiteKey__c = NULL, SupportSiteRedirectKeys__c = NULL, SupportSiteLinkOrder__c = 15,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'), 
                                                       RecordTypeId = supportSiteRecordTypeId);
        
        test.startTest();
        Database.insert(testContent, false);
        test.stopTest();
        
        verifyRecordNotInserted(testContent.Id);
    }
    
    @isTest
    static void BeforeInsert_SucceedsWithDuplicateSupportSiteKeyWhenSameContentDocumentId()
    {
        setup();
        ContentVersion existingContent = [SELECT Id, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c, ContentDocumentId
                                      	  FROM ContentVersion
                                          WHERE SupportSiteKey__c = 'TEST'];
        
        ContentVersion testContent = new ContentVersion(SupportSiteKey__c = 'Test', SupportSiteRedirectKeys__c = 'VOIPe911', SupportSiteLinkOrder__c = 10,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'), 
                                                       RecordTypeId = supportSiteRecordTypeId, ContentDocumentId = existingContent.ContentDocumentId,
                                                       Description = 'This is a test description');
        
        test.startTest();
        Database.insert(testContent, false);
        test.stopTest();
        
        List<ContentVersion> existingContentList = [SELECT SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c, Description
                                                    FROM ContentVersion
                                                    WHERE Id = :testContent.Id];
        
        System.assertEquals(1, existingContentList.size());
        ContentVersion actualContent = existingContentList.get(0);
        System.assertEquals('Test', actualContent.SupportSiteKey__c);
        System.assertEquals('VOIPe911', actualContent.SupportSiteRedirectKeys__c);
        System.assertEquals(10, actualContent.SupportSiteLinkOrder__c);
        System.assertEquals('This is a test description', actualContent.Description);
    }
    
    @isTest
    static void BeforeInsert_MultipleRecords()
    {
        //ensure that if more than one record is inserted at the same time without unique fields
        //will fail
        //the first two records have matching SupportSiteKey__c and should fail to insert.  The last
        //record should insert
        setup();
        List<ContentVersion> testContents = new List<ContentVersion>();
        testContents.add(new ContentVersion(SupportSiteKey__c = 'VOIPe911', SupportSiteRedirectKeys__c = 'VOIPe911', SupportSiteLinkOrder__c = 15,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'), 
                                                       RecordTypeId = supportSiteRecordTypeId));
        
        testContents.add(new ContentVersion(SupportSiteKey__c = 'New 2', SupportSiteRedirectKeys__c = 'VOIPe911', SupportSiteLinkOrder__c = 25,
                                                       Title = 'Title Test 3', PathOnClient = 'Test3', VersionData = Blob.valueOf('Testing2'), 
                                                       RecordTypeId = supportSiteRecordTypeId));
        
        testContents.add(new ContentVersion(SupportSiteKey__c = 'VOIPe911', SupportSiteRedirectKeys__c = NULL, SupportSiteLinkOrder__c = 25,
                                                       Title = 'Title Test 3', PathOnClient = 'Test3', VersionData = Blob.valueOf('Testing2'), 
                                                       RecordTypeId = supportSiteRecordTypeId));
        
        testContents.add(new ContentVersion(SupportSiteKey__c = 'New 3', SupportSiteRedirectKeys__c = NULL, SupportSiteLinkOrder__c = 35,
                                                       Title = 'Title Test 4', PathOnClient = 'Test4', VersionData = Blob.valueOf('Testing2'), 
                                                       RecordTypeId = supportSiteRecordTypeId));

        test.startTest();
        Database.insert(testContents, false);
        test.stopTest();
        
        verifyRecordNotInserted(testContents[0].Id, 3);
        verifyRecordNotInserted(testContents[1].Id, 3);
        verifyRecordNotInserted(testContents[2].Id, 3);
        
        ContentVersion newContent3 = [SELECT Id, SupportSiteKey__c, Title
                                     FROM ContentVersion
                                     WHERE Id = :testContents[3].Id LIMIT 1];
        System.assert(newContent3 != NULL);
        System.assert(newContent3.SupportSiteKey__c == 'New 3');
    }
    
    @isTest
    static void BeforeUpdate_SucceedsWhenSupportSiteFieldsNotUpdated()
    {
        setup();
        ContentVersion testContent = [SELECT Id, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                      FROM ContentVersion
                                      WHERE SupportSiteKey__c = 'TEST'];
        
        testContent.Description = 'Test Description';
        
        test.startTest();
        Database.update(testContent, false);
        test.stopTest();
        
        List<ContentVersion> existingContentList = [SELECT SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c, Description
                                                    FROM ContentVersion
                                                    WHERE Id = :testContent.Id];
        
        System.assertEquals(1, existingContentList.size());
        ContentVersion actualContent = existingContentList.get(0);
        System.assertEquals('Test Description', actualContent.Description);
        System.assertEquals(testContent.SupportSiteRedirectKeys__c, actualContent.SupportSiteRedirectKeys__c);
        System.assertEquals(testContent.SupportSiteLinkOrder__c, actualContent.SupportSiteLinkOrder__c);
    }
    
    @isTest
    static void BeforeUpdate_FailsWithNonUniqueSupportSiteKey()
    {
        setup();
        ContentVersion testContent = [SELECT Id, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                      FROM ContentVersion
                                      WHERE SupportSiteKey__c = 'TEST'];
        
        testContent.SupportSiteKey__c = 'TEST1';
        
        test.startTest();
        Database.update(testContent, false);
        test.stopTest();
        
        //ensure the record was not updated
        ContentVersion actualContent = [SELECT Id, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                       FROM ContentVersion
                                       WHERE Id = :testContent.Id];
        
        System.assertEquals('TEST', actualContent.SupportSiteKey__c);
    }
    
    @isTest
    static void BeforeUpdate_FailWithSupportSiteKeyMatchingSupportSiteRedirectKeys()
    {
        setup();
        ContentVersion testContent = [SELECT Id, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                      FROM ContentVersion
                                      WHERE SupportSiteKey__c = 'TEST'];
        
        testContent.SupportSiteKey__c = 'Colocation';
        
        test.startTest();
        Database.update(testContent, false);
        test.stopTest();
        
        //ensure the record was not updated
        ContentVersion actualContent = [SELECT Id, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                       FROM ContentVersion
                                       WHERE Id = :testContent.Id];
        
        System.assertEquals('TEST', actualContent.SupportSiteKey__c);
    }
    
    @isTest
    static void BeforeUpdate_FailWithDuplicateSupportSiteLinkOrder()
    {
        setup();
        ContentVersion testContent = [SELECT Id, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                      FROM ContentVersion
                                      WHERE SupportSiteKey__c = 'TEST'];
        
        testContent.SupportSiteLinkOrder__c = 20;
        
        test.startTest();
        Database.update(testContent, false);
        test.stopTest();
        
        //ensure the record was not updated
        ContentVersion actualContent = [SELECT Id, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                       FROM ContentVersion
                                       WHERE Id = :testContent.Id];
        
        System.assertEquals(10, actualContent.SupportSiteLinkOrder__c);
    }
    
    @isTest
    static void BeforeUpdate_FailWithNullSupportSiteLinkOrder()
    {
        setup();
        ContentVersion testContent = [SELECT Id, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                      FROM ContentVersion
                                      WHERE SupportSiteKey__c = 'TEST'];
        
        testContent.SupportSiteLinkOrder__c = NULL;
        
        test.startTest();
        Database.update(testContent, false);
        test.stopTest();
        
        //ensure the record was not updated
        ContentVersion actualContent = [SELECT Id, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                       FROM ContentVersion
                                       WHERE Id = :testContent.Id];
        
        System.assertEquals(10, actualContent.SupportSiteLinkOrder__c);
    }
    
    @isTest
    static void BeforeUpdate_FailsWithNullSupportSiteKey()
    {
        setup();
        ContentVersion testContent = [SELECT Id, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                      FROM ContentVersion
                                      WHERE SupportSiteKey__c = 'TEST'];
        
        testContent.SupportSiteKey__c = NULL;
        
        test.startTest();
        Database.update(testContent, false);
        test.stopTest();
        
        //ensure the record was not updated
        ContentVersion actualContent = [SELECT Id, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                       FROM ContentVersion
                                       WHERE Id = :testContent.Id];
        
        System.assertEquals(10, actualContent.SupportSiteLinkOrder__c);
    }
    
    @isTest
    static void BeforeUpdate_SucceedsWhenNotSupportSiteRecordType()
    {
        setup();
        ContentVersion testContent = new ContentVersion(SupportSiteKey__c = NULL, SupportSiteRedirectKeys__c = NULL, SupportSiteLinkOrder__c = NULL,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'));
        insert testContent;
        
        testContent = [SELECT SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c, Title
                       FROM ContentVersion
                       WHERE Id = :testContent.Id LIMIT 1];
        testContent.Title = 'Modified Title';
        
        test.startTest();
        Database.update(testContent, false);
        test.stopTest();
        
        List<ContentVersion> existingContentList = [SELECT SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c, Title
                                                    FROM ContentVersion
                                                    WHERE Id = :testContent.Id];
        
        System.assertEquals(1, existingContentList.size());
        ContentVersion actualContent = existingContentList[0];
        System.assertEquals(NULL, actualContent.SupportSiteKey__c);
        System.assertEquals(NULL, actualContent.SupportSiteRedirectKeys__c);
        System.assertEquals(NULL, actualContent.SupportSiteLinkOrder__c);
        System.assertEquals('Modified Title', actualContent.Title);
    }
    
    @isTest
    static void BeforeUpdate_MultipleRecords()
    {
        setup();
        List<ContentVersion> testContents = [SELECT Id, SupportSiteLinkOrder__c
                                            FROM ContentVersion
                                            WHERE RecordTypeId = :supportSiteRecordTypeId];
        
        for(ContentVersion testContent : testContents)
        {
            testContent.SupportSiteLinkOrder__c = 18;
        }
        
        test.startTest();
        Database.update(testContents, false);
        test.stopTest();
        
		List<ContentVersion> existingContentList = [SELECT SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c, Title
                                                    FROM ContentVersion
                                                    WHERE RecordTypeId = :supportSiteRecordTypeId];        
        
        for(ContentVersion testContent : existingContentList)
        {
            System.assert(testContent.SupportSiteLinkOrder__c != 18);
        }
    }
}