@isTest
global class ICorporateItTfsService implements WebServiceMock 
{
	global void doInvoke
   (
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType
   ) 
   {
   		if(requestName == 'UpsertFeature')
   		{
            CorporateItTfsService.UpsertFeatureResponse_element respElement = new CorporateItTfsService.UpsertFeatureResponse_element();
            respElement.UpsertFeatureResult = new CorporateItTfsService.CorpFeature();
            respElement.UpsertFeatureResult.TfsId = 99999;
            respElement.UpsertFeatureResult.State = 'Active';
	   			   		
	   		
       		response.put('response_x', respElement); 
   		}
   		else if(requestName == 'GetFeature') 
   		{
   			CorporateItTfsService.GetFeatureResponse_element respElement = new CorporateItTfsService.GetFeatureResponse_element();
            respElement.GetFeatureResult = new CorporateItTfsService.CorpFeature();
            respElement.GetFeatureResult.TfsId = 99999;
            respElement.GetFeatureResult.State = 'Active';
	   			   		
	   		
       		response.put('response_x', respElement); 
   		}
   		else if(requestName == 'AddFeatureComment') 
   		{
   			CorporateItTfsService.AddFeatureCommentResponse_element  fcRespElement = new CorporateItTfsService.AddFeatureCommentResponse_element();
            fcRespElement.AddFeatureCommentResult = true;
	   			   		
	   		
       		response.put('response_x', fcRespElement); 
   		}
              		
   }
}