public class CaseArticleAttachExtension 
{
    public CaseArticle__c caseArticle {public get;private set;}
    public String searchText{get;set;}
    public List<KnowledgeBaseProxyClass> knowledgeResults{public get;private set;}
    private CaseArticle__c[] currentCaseArticles;
    
    public CaseArticleAttachExtension(ApexPages.StandardController controller) 
    {
        this.caseArticle = (CaseArticle__c)controller.getRecord();
        caseArticle.Case__c = ApexPages.CurrentPage().getParameters().get('CF00N70000003FYuQ_lkid');
        searchText = [SELECT Subject FROM Case WHERE Id = :caseArticle.Case__c].Subject;
        currentCaseArticles = new CaseArticle__c[]{};
        currentCaseArticles = [SELECT ArticleNumber__c FROM CaseArticle__c WHERE Case__c = :caseArticle.Case__c];
        UploadArticles();
    }
    
    public void UploadArticles()
    {
        try
        {
            knowledgeResults = KnowledgeBaseProxyService.ArticleSearch(searchText);
            
        }
        catch(Exception ex)
        {
            knowledgeResults = new List<KnowledgeBaseProxyClass>();
        }
        
                
        if(!knowledgeResults.isEmpty() && !currentCaseArticles.isEmpty())
        {
            integer knowSize = knowledgeResults.size()-1;
            for(integer i=knowSize ;i >=0;i--)
            {
                KnowledgeBaseProxyClass pc = knowledgeResults[i];
                
                for(CaseArticle__c ca:currentCaseArticles)
                {
                    if(ca.ArticleNumber__c == pc.ArticleNumber)
                    {
                        knowledgeResults.remove(i);
                        break;
                    }
                }
            }
        
        }
    }
    
    public void SaveRecord()
    {
        
               
        List<CaseArticle__c> articles = new List<CaseArticle__c>();
        
        for(KnowledgeBaseProxyClass kb:knowledgeResults)
        {
            if(kb.Selected)
            {
                CaseArticle__c ca = new CaseArticle__c();
                ca.Title__c = kb.Title;
                ca.Summary__c = kb.HitHighlightedSummary;
                ca.Case__c = caseArticle.Case__c;
                ca.ArticleNumber__c = kb.ArticleNumber;
                
                articles.add(ca);   
            }
        }
        
        if(!articles.isEmpty())
        {
            insert articles;
        }
    }
    
    public PageReference Save()
    {
        
        SaveRecord();
        
        //return to case page
        PageReference casePage = new PageReference('/' + caseArticle.Case__c);
        casePage.setRedirect(true);
        
        return casePage;
    }

}