@isTest
public class ContentVersionTriggerHandlerTests 
{
    static ID setup()
    {
        RecordType supportSiteRecordType = [SELECT Id FROM RecordType WHERE Name = 'Support Site Link'];
        ID supportSiteRecordTypeId = supportSiteRecordType.Id;
        
        //add test records
        List<ContentVersion> existingContentList = new List<ContentVersion>();
        existingContentList.add(new ContentVersion(SupportSiteKey__c = 'TEST', SupportSiteRedirectKeys__c = 'VOIPe911', SupportSiteLinkOrder__c = 10,
                                                   Title = 'Title Test', PathOnClient = 'Test', VersionData = Blob.valueOf('Testing'), 
                                                   RecordTypeId = supportSiteRecordTypeId));
        existingContentList.add(new ContentVersion(SupportSiteKey__c = 'TEST1', SupportSiteRedirectKeys__c = 'Colocation', SupportSiteLinkOrder__c = 20,
                                                   Title = 'Title Test 1', PathOnClient = 'Test1', VersionData = Blob.valueOf('Testing1'), 
                                                   RecordTypeId = supportSiteRecordTypeId));
        
        insert existingContentList;
        
        return supportSiteRecordTypeId;
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
                              FROM ContentVersion];
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
                              FROM ContentVersion];
        System.assertEquals(expectedRecordCount, existingContentList.size());
    }	    
    
    @isTest
    static void BeforeInsert_FailsWithSupportSiteKeyWithDifferentCasing()
    {
        //the support site key should be unique, regardless of the casing
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
        ContentVersion testContent = new ContentVersion(SupportSiteKey__c = 'TEST2', SupportSiteRedirectKeys__c = NULL, SupportSiteLinkOrder__c = 15,
                                                       Title = 'Title Test 2', PathOnClient = 'Test2', VersionData = Blob.valueOf('Testing2'), RecordTypeId = supportSiteRecordTypeId);
        
        test.startTest();
        Database.insert(testContent, false);
        test.stopTest();
        
        List<ContentVersion> existingContentList = [SELECT SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c
                                                    FROM ContentVersion
                                                    WHERE Id = :testContent.Id];
        
        System.assertEquals(1, existingContentList.size());
        ContentVersion actualContent = existingContentList.get(0);
        System.assertEquals('TEST2', actualContent.SupportSiteKey__c);
        System.assertEquals(NULL, actualContent.SupportSiteRedirectKeys__c);
        System.assertEquals(15, actualContent.SupportSiteLinkOrder__c);
    }
    
    @isTest
    static void BeforeInsert_SucceedsWhenNotSupportSiteRecordType()
    {
        
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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
        ID supportSiteRecordTypeId = setup();
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