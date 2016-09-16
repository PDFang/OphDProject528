@istest
public class ArticleSearchTriggerHandlerTest {

    public static testmethod void CreateServiceSiteArticleSearchItem()
    {
        String accountName = 'Test01';
        Id articleID;
        
        Map<String,Schema.RecordTypeInfo> recordTypeMapByName = Schema.SObjectType.Contact.getRecordTypeInfosByName();
		Id rtCustOther = recordTypeMapByName.get('Customer-Other').getRecordTypeId();
        
        Account act = inContactBaseClass.CreateAccount(accountName);
        insert act;
        
        Contact con = inContactBaseClass.CreateContact(act.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);        
        insert con;
       
        FAQ__kav articleRecord = new FAQ__kav(
            Title = 'Not a real article',
            Summary = 'Not a real article',
            URLName = 'testArnab'
        );
        
        database.SaveResult svr = database.insert(articleRecord);
        if(svr.isSuccess())
            articleID = svr.getId();
        
        articleRecord = [SELECT KnowledgeArticleId, ArticleNumber, Title FROM FAQ__kav where Id =:articleID];
        
        KbManagement.PublishingService.publishArticle(articleRecord.KnowledgeArticleId, true);
        
        
        ServiceSiteArticleSearch__c item = new ServiceSiteArticleSearch__c();
        item.Account__c = act.Id;
        item.Contact__c = con.Id;
        item.LastArticleReviewed__c = articleRecord.ArticleNumber;
        
        insert item;
        
        
        ServiceSiteArticleSearch__c verifySearch = [select Id, Article_Title__c FROM ServiceSiteArticleSearch__c Limit 1];
        
        system.assertEquals('Not a real article', verifySearch.Article_Title__c);
          
        
    }
    
    public static testmethod void UpdateServiceSiteArticleSearchItemWithArticleNum()
    {
        String accountName = 'Test01';
        Id articleID;
        
        Map<String,Schema.RecordTypeInfo> recordTypeMapByName = Schema.SObjectType.Contact.getRecordTypeInfosByName();
		Id rtCustOther = recordTypeMapByName.get('Customer-Other').getRecordTypeId();
        
        Account act = inContactBaseClass.CreateAccount(accountName);
        insert act;
        
        Contact con = inContactBaseClass.CreateContact(act.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);        
        insert con;
       
        FAQ__kav articleRecord = new FAQ__kav(
            Title = 'Not a real article',
            Summary = 'Not a real article',
            URLName = 'testArnab'
        );
        
        database.SaveResult svr = database.insert(articleRecord);
        if(svr.isSuccess())
            articleID = svr.getId();
        
        articleRecord = [SELECT KnowledgeArticleId, ArticleNumber, Title FROM FAQ__kav where Id =:articleID];
        
        KbManagement.PublishingService.publishArticle(articleRecord.KnowledgeArticleId, true);
        
        
        ServiceSiteArticleSearch__c item = new ServiceSiteArticleSearch__c();
        item.Account__c = act.Id;
        item.Contact__c = con.Id;        
        insert item;
        
        
        test.startTest();
        ServiceSiteArticleSearch__c searchItem = [select Id, LastArticleReviewed__c  from  ServiceSiteArticleSearch__c limit 1];
        searchItem.LastArticleReviewed__c = articleRecord.ArticleNumber;
        update searchItem;        
        test.stopTest();
        
        
        ServiceSiteArticleSearch__c verifySearch = [select Id, Article_Title__c FROM ServiceSiteArticleSearch__c Limit 1];
        
        system.assertEquals('Not a real article', verifySearch.Article_Title__c);
          
        
    }
    
}