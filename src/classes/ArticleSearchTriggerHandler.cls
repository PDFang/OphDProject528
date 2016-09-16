public class ArticleSearchTriggerHandler  extends TriggerHandler{

    public override void beforeInsert()
    {
        findArticle(trigger.new);
    }
    
    public override void beforeUpdate()
    {
        findArticle(trigger.new);
    }
    
    // Article title search for a given article number
    private void findArticle(list<ServiceSiteArticleSearch__c> lstArticles)
    {
        set<string> articleNums = new set<string>();
        set<string> stArticleIds = new set<string>();
        Map<string, string> mpArticleNumbers = new Map<string,string>();        
        ServiceSiteArticleSearch__c oldRec;
        boolean istriggerRunning  = trigger.isExecuting;
        
        for(ServiceSiteArticleSearch__c items : lstArticles)
        {	
            // get the article numbers
            // 
            if(istriggerRunning && !trigger.isInsert)
            {
                oldRec = (ServiceSiteArticleSearch__c)trigger.oldMap.get(items.Id);
                if(items.LastArticleReviewed__c != null && items.LastArticleReviewed__c != oldRec.LastArticleReviewed__c && isNumber(items.LastArticleReviewed__c))
                {
                    articleNums.add(items.LastArticleReviewed__c);
                }
            }
                	
            else if(items.LastArticleReviewed__c != null && isNumber(items.LastArticleReviewed__c))
            {
                articleNums.add(items.LastArticleReviewed__c);
            }
            
        }
        
       
        if(articleNums.size() > 0)            
        {
            // get the articleIds for the numbers
            for(KnowledgeArticle article : [SELECT Id FROM KnowledgeArticle WHERE ArticleNumber IN :articleNums])
             {
                 stArticleIds.add(article.Id);
             }
             for(KnowledgeArticleVersion version : [SELECT Title, ArticleNumber 
                                               	    FROM KnowledgeArticleVersion
                                                    WHERE KnowledgeArticleId IN :stArticleIds  AND PublishStatus='Online' AND Language = 'en_US'])
                 {
                     mpArticleNumbers.put(version.ArticleNumber, version.Title);
                 }
            
        }     
        // update the article titles 
        if(mpArticleNumbers.size() > 0)
         {
           for(ServiceSiteArticleSearch__c items : lstArticles)
           {
             if(items.LastArticleReviewed__c != null && isNumber(items.LastArticleReviewed__c))
              {
                items.Article_Title__c = mpArticleNumbers.get(items.LastArticleReviewed__c);
              }
            }
            
          }
    }
    
    private boolean isNumber (string articleNum)
    {
        Pattern isNumbers = Pattern.compile('^[0-9]+$');
        Matcher isMatch = isNumbers.matcher(articleNum);
        
        return ismatch.matches();
      
    }
}