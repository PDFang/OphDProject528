@isTest
public class KnowledgeControlsClassTests 
{
    
    public static testMethod void TestStandardText()
    {
        Case c = new Case();
        c.Subject = 'test';
		//set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
		c.setOptions(dmo);
        insert c;
        
        General__kav testArticle = new General__kav();
        testArticle.Title = 'SFDC Test General';
        testArticle.Summary = 'KB Summary';
        testArticle.URLName = 'SFDC-Test-General';
        testArticle.Language = 'en_US';
        insert testArticle;
        
        // Get the KnowledgeArticleId
        General__kav insertedTestArticle = [Select KnowledgeArticleId from General__kav where ID = :testArticle.Id];
        
        // Publish
        KbManagement.PublishingService.publishArticle(insertedTestArticle.KnowledgeArticleId, true);
        
        List<KnowledgeControlsClass.KnowledgeSelection> searchList = KnowledgeControlsClass.SearchSaasArticles('test');
        
        KnowledgeArticleVersion kbVersion = [SELECT Id, Summary, Title, KnowledgeArticleId FROM KnowledgeArticleVersion WHERE KnowledgeArticleId = :insertedTestArticle.KnowledgeArticleId AND PublishStatus = 'Online'];
        KnowledgeControlsClass.KnowledgeSelection exampleSearchResult = new KnowledgeControlsClass.KnowledgeSelection(kbVersion);
        searchList.add(exampleSearchResult);
        KnowledgeControlsClass.AttachArticleSelectionsToCase(searchList, c.Id);
    }
}