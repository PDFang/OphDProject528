// this is a class to integrate with TFS
public class ISTFSINTEGRATIONCLASS
{
    // Create a static variable in this class instead
    Public static boolean isWebServiceCall = false;
    @future(callout=true)
    public static void CallTFSFutureMethod(set<String> sObjectIds, String sObjectType)
    {
        if(sObjectIds.size() > 1)
            doSendEmail('Unable to create request for more than 1 items. Please use only one item');
        else if(!isWebServiceCall)
        	boolean isSuccess = CreateTFSItems(sObjectIds, sObjectType);
    }
    
// do the callout
    public static boolean CreateTFSItems(set<string> sObjectIds, string sObjectType)
    {
      
        Map<Id, string> mpProjTFSIds = new map<Id, String>();        
        boolean isError = false;
        string errorString = '';
        String currentId = (new list<string>(sObjectIds))[0];
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        string tfsId;
        string body = ISIntegrationHandlerClass.SerializeObject(currentId, sObjectType);      
        string endPoint = getEndPoint(sObjectType);
        // Form the request 
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8'); 
        req.setTimeout(40000);
        //  map<string, string> mpAuth = new map<string, string>{'Authorization' => 'TFSIntegrationUser:X>}{nq,A>KpQ=3FN'};
        //  req.setHeader('Authorization', EncryptStringClass.EncodeString('512test', mpAuth));
        req.setBody(body);
        try
        {
               res = http.send(req);
				System.debug('response body == >' + res.getBody());            
               if(res.getStatusCode() ==  200)
               {
                 
                       tfsId = string.valueOf(res.getBody());
                       if(tfsId != null && tfsId != '')
                       {
                              mpProjTFSIds.put(currentId, tfsId);       
                       }
               }
               
               else if (res.getStatusCode() ==  204)
               {
                    if(sObjectType != 'Topic')
                   		mpProjTFSIds.put(currentId, 'Successfully created a comment in TFS');       
                      
                }
               else
               {
                   string errMessage = 'Error: - status code is - ' + res.getStatusCode() + ' with message ' + string.valueOf(res.getBody());
                   errorString = errMessage;
                   mpProjTFSIds.put(currentId, errMessage);
                   isError = true;
               }
             }  
			 Catch(System.CalloutException ex)
             {
               errorString = 'Callout error: '+ ex.getMessage() + ' for id - ' + currentId;  
               System.debug('callout errorString == >' + errorString);
               System.debug(res.toString());
                 
               mpProjTFSIds.put(currentId, ex.getMessage());
               isError = true;
               if(!system.isFuture())
               {
                     ApexPages.Message error = new ApexPages.Message(ApexPages.severity.ERROR, 'ERROR: ' + ex.getMessage() + ' for id - ' + currentId);
             		 ApexPages.addMessage(error);       
               }
                       
              }
                 
              Catch(Exception e)
              {
                errorString = 'Other error: at line '+ e.getLineNumber() + ' with ' + e.getMessage() + ' for id - ' + currentId;
                
                System.debug('errorString ==> ' + errorString); 
                mpProjTFSIds.put(currentId, e.getMessage());  
               	isError = true;
                if(!system.isFuture())
                {
                    ApexPages.Message error = new ApexPages.Message(ApexPages.severity.ERROR, 'ERROR: ' + currentId);
                    ApexPages.addMessage(error); 
                }
              }    
       
        if(mpProjTFSIds.size() > 0)
        	ISIntegrationHandlerClass.updateSObjects(mpProjTFSIds, isError);
        
        if(isError)
            doSendEmail(errorString);
        
        return !isError;
    }
    
    // set the endpoint
   	private static string  getEndPoint(string sObjectType)
    {
        string endPoint;  
        if(sObjectType == 'ISTFSWorkItem__c')
            endPoint = 'callout:TFSLink' + Label.TFS_Create_User_Story;
        else if(sObjectType == 'Project__c')
             endPoint = 'callout:TFSLink' + Label.TFS_Create_Feature;
        else 
        	 endPoint = 'callout:TFSLink' + Label.TFS_Create_Comments;	 
        
        if(sObjectType == 'Topic')
        		 endPoint = 'callout:TFSLink' + Label.TFS_Create_Tags;	
        
        return endPoint;
        
    }
   
    private static void doSendEmail(string emailBody)
    {   
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'Arnab.KarSarkar@incontact.com', 'Shawn.Hartke@incontact.com', 'Basant.Pathak@incontact.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('There is an unexpected error occured');
        mail.setHtmlBody(emailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	
 	}
    
}