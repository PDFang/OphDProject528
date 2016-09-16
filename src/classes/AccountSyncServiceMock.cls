@isTest
global class  AccountSyncServiceMock implements WebServiceMock 
{
   global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName, 
           String responseNS,
           String responseName,
           String responseType) 
   {
       AccountSyncService.AccountSyncResponse_element respElement = new AccountSyncService.AccountSyncResponse_element();

       		
       response.put('response_x', respElement); 
   }
}