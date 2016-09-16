public class KnowledgeControlsClass 
{
    
	public static List<KnowledgeSelection> SearchSaasArticles(string searchString)
    {
        List<KnowledgeSelection> articleList = new List<KnowledgeSelection>();
        system.debug(searchString);
        List<List<SObject>> searchList = [Find :searchString RETURNING KnowledgeArticleVersion (Id, Title, ArticleNumber, ArticleType, URLName, Summary, KnowledgeArticleId WHERE PublishStatus='online' AND Language='en_US' AND ArticleType IN('General__kav','Technical__kav')) WITH SNIPPET UPDATE TRACKING];
        system.debug(searchList);
        if(!searchList.isEmpty())
        {
            List<KnowledgeArticleVersion> articles = ((List<KnowledgeArticleVersion>)searchList[0]);
            
            for(KnowledgeArticleVersion kav : articles)
            {
        		KnowledgeSelection articleSelect = new KnowledgeSelection(kav);
                articleList.add(articleSelect);
            }
        }
        
        return articleList;
    }
    
    public static void AttachArticleSelectionsToCase(List<KnowledgeSelection> articles, id caseId)
    {
        if(!articles.isEmpty())
        {
            List<CaseArticle> caseArticle = new List<CaseArticle>();
            
            for(KnowledgeSelection a:articles)
            {
                CaseArticle ca = new CaseArticle();
                ca.CaseId = caseId;
                ca.KnowledgeArticleId = a.article.KnowledgeArticleId;
                
                caseArticle.add(ca);
            }
            
            insert caseArticle;
        }
    }
    
    
    
    
    public class KnowledgeSelection
    {
        public boolean selected {get; set;}
        public KnowledgeArticleVersion article {get; set;}
        
        public KnowledgeSelection(KnowledgeArticleVersion kav)
        {
            selected = false;
            article = kav;
        }
    }

}