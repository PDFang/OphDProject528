@isTest
global class ITfsIntegrationProxy  implements WebServiceMock 
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
   		if(requestName == 'GetInContactReleases')
   		{
   			tfsIntegration.GetInContactReleasesResponse_element respElement = new tfsIntegration.GetInContactReleasesResponse_element();
   			respElement.GetInContactReleasesResult = new tfsIntegration.ArrayOfString();
   			respElement.GetInContactReleasesResult.string_x = new String[]{'test','test2'};
   			
   			response.put('response_x',respElement);
   			
   			
   		}
   		else if(requestName == 'UpsertInContactBug')
   		{
   			tfsIntegration.UpsertInContactBugResponse_element respElement = new tfsIntegration.UpsertInContactBugResponse_element();
	   		respElement.UpsertInContactBugResult = new tfsIntegration.TfsWorkItem();
	   		respElement.UpsertInContactBugResult.TfsId = 11;
	   		respElement.UpsertInContactBugResult.State = 'Active';
	   			   		
	   		
       		response.put('response_x', respElement); 
   		}
   		else if(requestName == 'GetInContactBug') 
   		{
   			tfsIntegration.GetInContactBugResponse_element respElement = new tfsIntegration.GetInContactBugResponse_element();
	   		respElement.GetInContactBugResult = new tfsIntegration.TfsWorkItem();
	   		respElement.GetInContactBugResult.TfsId = 11;
	   		respElement.GetInContactBugResult.State = 'Active';
	   			   		
	   		
       		response.put('response_x', respElement); 
   		}
              		
   }
}