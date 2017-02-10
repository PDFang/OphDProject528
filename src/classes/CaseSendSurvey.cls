public class CaseSendSurvey 
{
    @future (callout=true)
    //Main method for Tech Support type surveys.  Filters cases and calls worker classes.
    public static void TechSupportSurveyMain(Set<Id> caseIds)
    {
        boolean isTest = Test.isRunningTest();
        List<Case> cases = new List<Case>();
        cases = [SELECT CaseNumber, Owner.Name, ResolvedBy__r.Name, Subject, AccountBillingGroup__c,Account.IntacctID__c, Account.CadebillAccountNo__c, Account.Name, Contact.Name, Contact.Email, Assigned_To__r.Name, CreatedDate, ClosedDate, Status, RecordType.Name, Owner.Type FROM Case WHERE Id IN :caseIds];

        for(Case c: cases)
        {  
            String endPointURL = '';
            String endPointURLParam = '';
            system.debug(c);
            system.debug(c.Owner.Name);
            system.debug(c.Owner.Type);
            if(c.Contact.Email != null && c.Contact.Email != '')
            {
                // Added by Arnab (The Man) as per Story# 48155 - Help Desk Surveys Triggered on Case Closure
               if(c.RecordType.Name == 'Help Desk' && (c.Owner.Name == 'IT-Help Desk Queue'
                                                            || c.Owner.Name == 'IT-Desktop Support Queue' 
                                                            || c.Owner.Name == 'IT-Server Admin Queue')){

                        endPointURLParam = ITHelpDeskSurveyMapping(c);
                }
                System.debug('endPointURLParam ==> ' + endPointURLParam);

                
                if (endPointURLParam != '')
                {
                    String resultMsg = SurveyCallAndPost(endPointURLParam);
                    SurveyCommentPost(c, resultMsg);
                }

            } 
            else
            {
                NoEmailAddressCommentPost(c);
            }
        }
    }

    // Added code block for IT helpdesk survey -- Arnab (The man)
    private static string ITHelpDeskSurveyMapping(Case c){
        string parameters = Label.ITHDSurveyParameters;
        parameters = parameters.replace('{CustomerEmail}', EncodingUtil.urlEncode(c.Contact.Email,'UTF-8'));
        parameters = parameters.replace('{CaseID}', EncodingUtil.urlEncode(c.CaseNumber,'UTF-8'));
        return parameters;
    }

    //Survey call and message post back NEW ********************************************        
    // Modified the URL mapping by named credentials - Arnab
    private static string SurveyCallAndPost(string urlParam) 
    {
        boolean isTest = Test.isRunningTest();
        //Create an HttpRequest object for posting to the Echo survey site
        HttpRequest req = new HttpRequest();        
        
        if(urlParam != '') // Add the named credentioal
        {
            req.setEndpoint('callout:EchoSurvey' + urlParam);
        }
        
        req.setMethod('GET');
        req.setTimeout(30000); 
        
        //body information to trigger Cast Iron orchestrationSurvey
        req.setBody('');
        Http http = new Http();
        
        //If this isn't a test method then go ahead and make the web service call
        string resultMsg = '';
        
        if(!istest)
        {
            HTTPResponse res = http.send(req);
            resultMsg = res.getBody();
        }
        
        system.debug('*************' + resultMsg + '*******************');
        return resultMsg;
    }
    
    //Process Survey response message NEW ****************************************************
    private static void SurveyCommentPost (Case c, String resultMsg) 
    {
        string commentBody = '';
        
        //get message if success or failure         
        if(resultMsg.contains('Success!') || resultMsg.contains('successfully'))
        {
            commentBody = 'A survey request was successfully submitted. If the customer has received a survey in the last 30 days a new survey will not be sent.';
        }
        else
        {
            commentBody = 'The survey request failed.';
        }
        
        //add http result to message
        commentBody = commentBody + '\r\n' + resultMsg.trim();
        //cBody = cBody + '\r\n' + url;
        
        //create comment
        CaseComment cc = new CaseComment();
        cc.ParentId = c.Id;
        cc.CommentBody = commentBody;
         cc.IsPublished = False;
        
        insert cc;
    }
    
    private static void NoEmailAddressCommentPost (Case c) 
    {
        string commentBody = 'No survey was sent.  The contact associated to this case does not have an email address.';
        
        //create comment
        CaseComment cc = new CaseComment();
        cc.ParentId = c.Id;
        cc.CommentBody = commentBody;
        cc.IsPublished = False;
        
        insert cc;
    }
}