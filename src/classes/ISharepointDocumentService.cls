@isTest
global class ISharepointDocumentService implements WebServiceMock 
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
        SharepointDocumentService.CreateCustomerLibraryResponse_element respElement = new SharepointDocumentService.CreateCustomerLibraryResponse_element();
        respElement.CreateCustomerLibraryResult = true;
        response.put('response_x', respElement); 
   }
}