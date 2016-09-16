@isTest
public class CaseUpdateBatchTest {
    
    @isTest
	static void TestKBAttachedFlag_Updated_WhenClosed() 
    {
        // Arrange
        String query = 'SELECT Id, KB_Attached__c, CaseNumber, Status, ClosedDate FROM Case WHERE KB_ATTACHED__C = false AND Status = \'Closed\' AND ClosedDate >= YESTERDAY';
        
        Case[] caseList = new List<Case>();
		Id sfQueue = '00G70000001ciT7';        
        
        
        // Case WITH KB Article Referenced
        Case case1 = new Case(
        	Status = 'New',
            KB_Attached__c = false,
            Description = 'Kb Will be attached',
            OwnerId = sfQueue,
		  	Origin = 'Web'
        );
        
        caseList.add(case1);
        
        // Case with no KB Article Referenced
        Case case2 = new Case(
        	Status = 'New',
            KB_Attached__c = false,
            Description = 'Kb Will NOT be attached',
            OwnerId = sfQueue,
		  	Origin = 'Web'
        );
        
        caseList.add(case2);
        
        insert caseList;
        
        FAQ__kav articleRecord = new FAQ__kav(
            Title = 'Not a real article',
            Summary = 'Not a real article',
            URLName = 'testArnab'
        );
        
        
            
        database.SaveResult svr = database.insert(articleRecord);
        Id articleID;
        if(svr.isSuccess())
            articleID = svr.getId();
        	
        articleRecord = [SELECT KnowledgeArticleId FROM FAQ__kav where Id =:articleID];
        
        
        CaseArticle caseArticleRecord = new CaseArticle(
            CaseId = case1.Id,
            KnowledgeArticleId = articleRecord.KnowledgeArticleId
         );
        
        insert caseArticleRecord;
        
        Last_Batch_Run_Date__c batchRunDtCreate = new Last_Batch_Run_Date__c();
        batchRunDtCreate.Name = 'test';
        batchRunDtCreate.LastRunTime__c = system.now();
        
        insert batchRunDtCreate;
        
        case1.Status = 'Closed';
        case2.Status = 'Closed';
        
        update caseList;
        
        
        
       KnowledgeArticleVersion KBversion = [SELECT SourceId, CreatedById, KnowledgeArticleId 
                                            FROM KnowledgeArticleVersion
										 	WHERE PublishStatus='Draft' AND Language = 'en_US' 
                                            AND KnowledgeArticleId =: articleRecord.KnowledgeArticleId limit 1];
        system.debug('KBVersion ==>' + KBversion.SourceId);
        
        // Act
        Test.startTest();
        
        Last_Batch_Run_Date__c batchRunDt = Last_Batch_Run_Date__c.getall().values();
        dateTime lastBatchRunTime = batchRunDt.LastRunTime__c;
        
        if(lastBatchRunTime == null)
            lastBatchRunTime = system.now().addDays(-7);
        
        string formattedDate = lastBatchRunTime.format('yyyy-MM-dd') + 'T00:00:00Z';
		Set<String> stRecordTypes = new Set<String>();

        string casesQuery = 'SELECT Id, KB_Attached__c, CaseNumber, Status, ClosedDate FROM Case WHERE KB_ATTACHED__C = false AND isClosed = true AND ClosedDate >= ' + formattedDate + ' AND recordTypeId in :stRecordTypes';
            
        CaseUpdateBatch kbAttachedBatch = new CaseUpdateBatch(query);
        Database.executeBatch(kbAttachedBatch);
        
        Test.stopTest();
        
        Case caseWithKBAttached = [Select KB_Attached__c,New_vs_Known__c, ClosedDate FROM Case where KB_Attached__c = true];
        Case caseWithoutKBAttached = [Select KB_Attached__c, New_vs_Known__c, ClosedDate FROM Case where KB_Attached__c = false];
        
        // Assert
        System.assertEquals(true, caseWithKBAttached.KB_Attached__c);
        System.assertEquals('Known', caseWithKBAttached.New_vs_Known__c);
        System.assertEquals(case1.Id, caseWithKBAttached.Id);
		
        System.assertEquals(false, caseWithoutKBAttached.KB_Attached__c);
        System.assertEquals('N/A', caseWithoutKBAttached.New_vs_Known__c);
        System.assertEquals(case2.Id, caseWithoutKBAttached.Id);
    }
}