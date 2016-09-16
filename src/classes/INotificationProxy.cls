@isTest
global class INotificationProxy implements WebServiceMock 
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
   	   Notificationproxy.SendEmailResponse_element respElement = new NotificationProxy.SendEmailResponse_element();
   	   respElement.SendEmailResult = true;
              		
       response.put('response_x', respElement); 
   }
}