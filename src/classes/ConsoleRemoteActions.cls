global virtual with sharing class ConsoleRemoteActions 
{
	
    
    @RemoteAction
    global static string JsonSearchedArticles(string searchText, string caseId)
    {
        List<KnowledgeBaseProxyClass> kbResults = KnowledgeBaseProxyService.ArticleSearch(searchText);
        CaseArticle__c[] articles = [SELECT c.Title__c, c.Summary__c, c.Id, c.ArticleUrl__c, c.ArticleNumber__c From CaseArticle__c c WHERE c.Case__c = :caseId];
        
        for(Integer i=kbResults.size()-1;i >= 0 ;i--)
        {
            for(CaseArticle__c article:articles)
            {
                if(article.ArticleNumber__c == kbResults[i].ArticleNumber)
                {
                    kbResults.remove(i);   
                    break;
                }
            }
        }
        
        return JSON.serialize(kbResults);
    }
    
    @RemoteAction
    global static string JsonCaseArticles(string caseId)
    {
        List<CaseArticle__c> articles = [SELECT c.Title__c, c.Summary__c, c.Id, c.ArticleUrl__c, c.ArticleNumber__c From CaseArticle__c c WHERE c.Case__c = :caseId];
        return JSON.serialize(articles);
    }
    
    @RemoteAction
    global static void AttachArticle(string jsonArticle, string caseId)
    {
        JSONParser parser = JSON.createParser(jsonArticle);
        KnowledgeBaseProxyClass article = (KnowledgeBaseProxyClass)parser.readValueAs(KnowledgeBaseProxyClass.class);
        
        CaseArticle__c ca = new CaseArticle__c();
        ca.Title__c = article.Title;
        ca.Summary__c = article.HitHighlightedSummary.left(255);
        ca.Case__c = caseId;
        ca.ArticleNumber__c = article.ArticleNumber;
        
        insert ca;
    }
    
    
    @RemoteAction
    global static void DeleteCaseArticle(string caseArticleId)
    {
        
        CaseArticle__c ca = new CaseArticle__c();
        ca.Id = caseArticleId;
        
        delete ca;
    }
    
    @RemoteAction
    global static void DeleteAttachment(string attachmentId )
    {
        CaseAttachment.DeleteCaseAttachment(attachmentId);
    }
    
    
    @RemoteAction
    global static void UpdateVisibility(string attachmentId, boolean isPublic, string caseId )
    {
        Attachment attach = [SELECT Id, Name, Body, Description, LastModifiedBy.Name, LastModifiedDate, ParentId FROM Attachment WHERE Id = :attachmentId];
        CaseAttachment ca = new CaseAttachment(attach, isPublic, caseId);
        ca.SaveAttachment();
    }
    
    
    @RemoteAction
    global static string JsonSelectCaseAttachments(string caseId)
    {
            CaseAttachment[] ca = CaseAttachment.SelectCaseAttachments(caseId);
            return JSON.serialize(ca);
    }
    
    @RemoteAction
    global static string JsonEventLog(string parentCaseId)
    {
        CaseComment[] comments = new CaseComment[]{};
        comments =  [SELECT Id, CommentBody, IsPublished, CreatedDate, CreatedBy.Name FROM CaseComment WHERE ParentId = :parentCaseId ORDER BY CreatedDate DESC];
        
        return JSON.serialize(comments);
    }
    
    @RemoteAction
    global static string JsonOpenEvents()
    {
        Case[] events = new Case[]{};
        events = CaseEventClass.GetOpenEvents();
        return JSON.serialize(events);
    }
    
        
    @RemoteAction
    global static void SetRelatedEvent(string eventId, string caseId)
    {
        Case c = new Case();
        c.Id = caseId;
        c.ParentId = eventId;
        
        update c;
    }
    
    @RemoteAction
    global static void SyncChildPriorities(string parentId, string priority)
    {
        Case[] childCases = [SELECT Priority FROM Case WHERE ParentId = :parentId];
        
        if(!childCases.isEmpty())
        {
            for(Case ca:childCases)
            {
                ca.Priority = priority;
            }
            
            update childCases;
        }
    }
    
    @RemoteAction
    global static void ChatRoomEmail(string caseId)
    {
        Case chatCase = new Case();
        chatCase.Id = caseId;
        chatCase.SendChatRoomEmail__c = true;
        
        update chatCase;
    }
    
    @RemoteAction
    global static void SetAccountMood(string accountId, string mood)
    {
        Account a = new Account();
        a.Id = accountId;
        a.CustomerTemperature__c = mood;
        a.CustomerTemperatureDate__c = system.now();
        a.CustomerMoodLastUpdatedBy__c = UserInfo.getUserId();
        
        update a;
    }
}