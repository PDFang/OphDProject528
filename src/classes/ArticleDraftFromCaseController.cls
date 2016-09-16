public class ArticleDraftFromCaseController {
// The constructor takes  ApexPages.KnowledgeArticleVersionStandardController as an argument
    public ArticleDraftFromCaseController(ApexPages.KnowledgeArticleVersionStandardController kbArticle){
		SObject thisArticle = kbArticle.getRecord(); // SObject instance for new Article

        String caseId = kbArticle.getSourceId(); //Returns the id of the case
        Case c = [select subject, description, Product_or_Service__c, SubProductorService__c, Product_or_Service_Details__c from Case where id=:caseId];
        
        thisArticle.put('title', c.subject);  //this overrides the default behavior of pre-filling the title of the article with the subject of the case. 
        
        string productName = c.Product_or_Service__c == null ? '' : c.Product_or_Service__c;
        string subProdName = c.SubProductorService__c == null ? '' : c.SubProductorService__c ;
        string prodOrService = c.Product_or_Service_Details__c == null ? '' : c.Product_or_Service_Details__c ;
        
		if (thisArticle instanceof How_To__kav)     // Mapping for How To articles
        {
              thisArticle.put('Environment__c', productName + '<br/>' + subProdName + '<br/>' + prodOrService); 
    		  thisArticle.put('Objective__c', c.Description);                        
        }
    
		else if (thisArticle instanceof Q_A__kav)     // Mapping for QA articles
        {
            thisArticle.put('Environment__c',productName + '<br/>' + subProdName  + '<br/>' + prodOrService); 
            thisArticle.put('Question__c', c.Description);    
        }
              
		else if (thisArticle instanceof  Solution_Article__kav)     // Mapping for Solutions articles
        {
              thisArticle.put('Environment__c', productName + '<br/>' + subProdName  + '<br/>' + prodOrService); 
			  thisArticle.put('Symptom__c', c.Description);       	
        
        }
            

	} 
 }