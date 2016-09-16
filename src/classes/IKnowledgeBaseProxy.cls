@isTest
global class IKnowledgeBaseProxy implements WebServiceMock {
   global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
       KnowledgeBaseProxyService.QueryKBResponse_element respElement = new KnowledgeBaseProxyService.QueryKBResponse_element();
       respElement.QueryKBResult = new KnowledgeBaseProxyService.ArrayOfResult();
       KnowledgeBaseProxyService.Result[] resultItemArray = new KnowledgeBaseProxyService.Result[]{};
       KnowledgeBaseProxyService.Result resultItem  = new KnowledgeBaseProxyService.Result();
       
       resultItem.ArticleNumber = '1234';
       resultItem.Title = 'Test';
       resultItem.HitHighlightedSummary = 'Test';
       resultItem.Path = 'http://mojo';  	
       
       resultItemArray.add(resultItem);
       respElement.QueryKBResult.Result = resultItemArray;
       		
       response.put('response_x', respElement); 
   }
}