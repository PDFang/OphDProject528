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
                // Removed SME Survey Logic from the Product & Practice Experts cases - User Story 25121
                /*if(c.Owner.Name == 'Product & Practice Experts Queue')
                {
                    endPointURLParam = SMEProductPracticeSurveyMapping(c);
                }*/
                /*if(c.RecordType.Name == 'Incident' && (c.Owner.Name == 'TSA Queue' || c.Owner.Name == 'TSM Queue' || c.Owner.Name == 'Tech Support Queue'))*/
                if(c.RecordType.Name == 'Incident' && (c.Owner.Name == 'TSM Queue' || c.Owner.Name == 'Tech Support Queue'))
                {
                    endPointURLParam = TSMSurveyMapping(c);   
                }
                else if (c.RecordType.Name == 'Incident - Premise' && c.Owner.Name == 'Premise TSM Queue') // change recordtype
                {
                    endPointURLParam = TSMSurveyMapping(c); 
                }
                else if (c.RecordType.Name == 'Incident - Premise' && (c.Owner.Name == 'Premise Tech Support Queue' || c.Owner.Name == 'Premise Tech Support II Queue' ))
                {
                    endPointURLParam = PremiseSupportSurveyMapping(c);
                }
                // Added by Arnab as per Story# 48155 - Help Desk Surveys Triggered on Case Closure
                else if(c.RecordType.Name == 'Help Desk' && (c.Owner.Name == 'IT-Help Desk Queue'
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

    // Removed SME Survey Logic from the Product & Practice Experts cases - User Story 25121
    /*private static string SMEProductPracticeSurveyMapping(Case c)
    { 
        //Get the URL from the static configuration file
        string url = Label.SMEproductPracticeEchoSurveyURL;  
        
        //fields to replace 
        //[[AccountNumber]] – Cadebill Account #
        //[[TicketNumber]] – Case Number
        //[[AssignedTo]] – Case Assigned To
        //[[CustomerEmail]] –  Case Contact Email
        //[[Contact]] – Account Name
        //[[CustomerName]] – Case Contact Name
        //[[Status]] –  Case Status
        //[[Subject]] – Case Subject
        
        if(c.Account.CadebillAccountNo__c != null)
        {
            url = url.replace('[[AccountNumber]]', EncodingUtil.urlEncode(string.valueOf(c.Account.CadebillAccountNo__c),'UTF-8'));
        }
        else
        {
            url = url.replace('[[AccountNumber]]', EncodingUtil.urlEncode('','UTF-8'));
        }
        url = url.replace('[[TicketNumber]]', EncodingUtil.urlEncode(c.CaseNumber,'UTF-8'));
        if(c.Assigned_To__r != null)
        {
        	url = url.replace('[[AssignedTo]]', EncodingUtil.urlEncode(c.Assigned_To__r.Name,'UTF-8'));
        }
        else
        {
            url = url.replace('[[AssignedTo]]', EncodingUtil.urlEncode('Product & Practice Experts', 'UTF-8'));
        }
        url = url.replace('[[CustomerEmail]]', EncodingUtil.urlEncode(c.Contact.Email,'UTF-8'));
        url = url.replace('[[Contact]]', EncodingUtil.urlEncode(c.Contact.Name,'UTF-8'));
        url = url.replace('[[CustomerName]]', EncodingUtil.urlEncode(c.Account.Name,'UTF-8'));
        url = url.replace('[[Status]]', EncodingUtil.urlEncode(c.Status,'UTF-8'));
        url = url.replace('[[Subject]]', EncodingUtil.urlEncode(c.Subject,'UTF-8'));
        System.debug(url);
        return url;
    }*/
    
    

    // Modified to add named credentials
    private static string TSMSurveyMapping (Case c)
    {
        //Get the URL from the static configuration file
        string url = Label.TechSupportEchoSurveyURL;
        
        //replace the place holders in the url with the data from the trip report
        url = url.replace('{Case #}', EncodingUtil.urlEncode(c.CaseNumber ,'UTF-8'));
        url = url.replace('{Subject}', EncodingUtil.urlEncode(c.Subject,'UTF-8'));
        
        if(c.Account.CadebillAccountNo__c != null)
        {
            url = url.replace('{CostGuard Acct#}', EncodingUtil.urlEncode(string.valueOf(c.Account.CadebillAccountNo__c),'UTF-8'));
        }
        else
        {
            url = url.replace('{CostGuard Acct#}', EncodingUtil.urlEncode('','UTF-8'));
        }
        url = url.replace('{Account Name}', EncodingUtil.urlEncode(c.Account.Name,'UTF-8'));
        url = url.replace('{Contact Name}', EncodingUtil.urlEncode(c.Contact.Name,'UTF-8'));
        
        if(c.Contact.Email != null)
        {
            url = url.replace('{Contact Email}', EncodingUtil.urlEncode(c.Contact.Email,'UTF-8'));
        }
        
        if(c.Owner.Name != null)
        {
            if(c.Owner.Name == 'TSM Queue' || c.Owner.Name == 'Premise TSM Queue')
            {
                url = url.replace('{Case Owner}', EncodingUtil.urlEncode('Enterprise Technical Management','UTF-8'));
            }
            else if(c.Owner.Name == 'TSA Queue')
            {
                url = url.replace('{Case Owner}', EncodingUtil.urlEncode('Personalized Service Model','UTF-8'));
            }
            else
            {
                url = url.replace('{Case Owner}', EncodingUtil.urlEncode('inContact Tech Support','UTF-8'));
            }
        }
        else
        {
            url = url.replace('{Case Owner}', EncodingUtil.urlEncode('inContact Tech Support','UTF-8'));
        }
        
        
        if(c.Assigned_To__c != null && (c.Owner.Name != 'TSM Queue' || c.Owner.Name != 'Premise TSM Queue'))
        {
            url = url.replace('{Assigned To}', EncodingUtil.urlEncode(c.Assigned_To__r.Name,'UTF-8'));
        }
        else
        {
            if(c.Owner.Name == 'TSM Queue' || c.Owner.Name == 'Premise TSM Queue'){
                if(c.ResolvedBy__c != null){
                    url = url.replace('{Assigned To}', EncodingUtil.urlEncode(c.ResolvedBy__r.Name,'UTF-8'));
                } else{
                    url = url.replace('{Assigned To}', EncodingUtil.urlEncode('Enterprise Technical Management','UTF-8'));
                }
            }
            else if(c.Owner.Name == 'TSA Queue')
            {
                url = url.replace('{Assigned To}', EncodingUtil.urlEncode('Personalized Service Model','UTF-8'));
            }
            else
            {
                url = url.replace('{Assigned To}', EncodingUtil.urlEncode('inContact Tech Support','UTF-8'));
            }
        }
        
        url = url.replace('{Date/Time Opened}', EncodingUtil.urlEncode(String.valueOf(c.CreatedDate),'UTF-8'));
        url = url.replace('{Date/Time Closed}', EncodingUtil.urlEncode(String.valueOf(c.ClosedDate),'UTF-8'));
        url = url.replace('{Status}', EncodingUtil.urlEncode(c.Status,'UTF-8'));
        
        //FLAG SURVEY IF VERIZON
        if(c.AccountBillingGroup__c == 'Verizon')
        {
            url = url + '&Verizon=yes';
        }
         return url;
    }
    // Added code block for IT helpdesk survey -- Arnab
    private static string ITHelpDeskSurveyMapping(Case c){
        string parameters = Label.ITHDSurveyParameters;
        parameters = parameters.replace('{CustomerEmail}', EncodingUtil.urlEncode(c.Contact.Email,'UTF-8'));
        parameters = parameters.replace('{CaseID}', EncodingUtil.urlEncode(c.CaseNumber,'UTF-8'));
        return parameters;
    }
    //Code Block for Uptivity Technical Support Survey Project
    // Modified to add named credentials
    private static string PremiseSupportSurveyMapping(Case c)
    {
        //Get the URL from the static configuration file
        string url = Label.PremiseTechSupportClosedEchoSurveyURL;
        
        //replace the place holders in the url with the data from salesforce case
        url = url.replace('{Case #}', EncodingUtil.urlEncode(c.CaseNumber ,'UTF-8'));
        url = url.replace('{Subject}', EncodingUtil.urlEncode(c.Subject,'UTF-8'));
        url = url.replace('{Account Name}', EncodingUtil.urlEncode(c.Account.Name,'UTF-8'));
        url = url.replace('{Contact Email}', EncodingUtil.urlEncode(c.Contact.Email,'UTF-8'));
        url = url.replace('{AccountNumber}', EncodingUtil.urlEncode(c.Account.IntacctID__c,'UTF-8'));
        
        url = url.replace('{Status}', EncodingUtil.urlEncode(c.Status,'UTF-8'));
        
        
        url = url.replace('{Contact Name}', EncodingUtil.urlEncode(c.Contact.Name,'UTF-8'));
        
        if(c.Owner.Name != null)
        {
            if(c.Owner.Name == 'Premise Tech Support Queue' || c.Owner.Name == 'Premise Tech Support II Queue')
            { 
                url = url.replace('{Case Owner}', EncodingUtil.urlEncode('Uptivity Technical Support','UTF-8'));
            }
            else
            {
                url = url.replace('{Case Owner}', '');
            }
        }
        else
        {
            url = url.replace('{Case Owner}', '');
        }
        
        if(c.Assigned_To__c != null)
        {
            url = url.replace('{AssignedTo}', EncodingUtil.urlEncode(c.Assigned_To__r.Name,'UTF-8'));
        }
        else
        {
            url = url.replace('{AssignedTo}', EncodingUtil.urlEncode('Uptivity Technical Support','UTF-8'));
        }
        return url;
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
    
     //********** MOVE TO THE NEW DESIGN ABOVE WHEN POSSIBLE ******************************************************
    @future (callout=true)
    //Modified to add NamedCredentials - Arnab
public static void SendAMSurvey(Set<Id> caseIds)
    {
        boolean isTest = Test.isRunningTest();
         //Loop through all the attendees and attempt to survey the ones that should be surveyed.
        List<Case> cases = new List<Case>();
        cases = [SELECT CaseNumber, ResolvedBy__r.Name, Subject, AccountBillingGroup__c, Account.CadebillAccountNo__c, Account.Name, Contact.Name, Contact.Email, Owner.Name, Assigned_To__r.Name, CreatedDate, ClosedDate, Status FROM Case WHERE Id IN :caseIds];
        
        for(Case c: cases)
        {
            //Get the URL from the static configuration file
            string url = Label.CaseAMClosedWorkOrderServReqSurveyURL;
            
            //replace the place holders in the url with the data from the trip report
            if(c.Contact.Email != null && c.Contact.Email !='')
            {
                url = url.replace('{Case #}', EncodingUtil.urlEncode(c.CaseNumber ,'UTF-8'));
                url = url.replace('{Subject}', EncodingUtil.urlEncode(c.Subject,'UTF-8'));
                
                if(c.Account.CadebillAccountNo__c != null)
                {
                    url = url.replace('{CostGuard Acct#}', EncodingUtil.urlEncode(string.valueOf(c.Account.CadebillAccountNo__c),'UTF-8'));
                }
                else
                {
                    url = url.replace('{CostGuard Acct#}', EncodingUtil.urlEncode('','UTF-8'));
                }
                url = url.replace('{Account Name}', EncodingUtil.urlEncode(c.Account.Name,'UTF-8'));
                url = url.replace('{Contact Name}', EncodingUtil.urlEncode(c.Contact.Name,'UTF-8'));
                url = url.replace('{Contact Email}', EncodingUtil.urlEncode(c.Contact.Email,'UTF-8'));
                
                if(c.Owner.Name != null)
                {
                    if(c.Owner.Name == 'TSM Queue'){
                        url = url.replace('{Case Owner}', EncodingUtil.urlEncode('Enterprise Customer Management','UTF-8'));
                    }
                    else{
                        url = url.replace('{Case Owner}', '');
                    }
                }
                else
                {
                    url = url.replace('{Case Owner}', '');
                }
                
                if(c.Assigned_To__c != null)
                {
                    url = url.replace('{Assigned To}', EncodingUtil.urlEncode(c.Assigned_To__r.Name,'UTF-8'));
                }
                else
                {
                    url = url.replace('{Assigned To}', EncodingUtil.urlEncode('inContact Account Management','UTF-8'));
                }
                
                url = url.replace('{Date/Time Opened}', EncodingUtil.urlEncode(String.valueOf(c.CreatedDate),'UTF-8'));
                url = url.replace('{Date/Time Closed}', EncodingUtil.urlEncode(String.valueOf(c.ClosedDate),'UTF-8'));
                url = url.replace('{Status}', EncodingUtil.urlEncode(c.Status,'UTF-8'));
                
                //FLAG SURVEY IF VERIZON
                if(c.AccountBillingGroup__c == 'Verizon')
                {
                    url = url + '&Verizon=yes';
                }
                
                if (url != null){
                    String resultMsg = SurveyCallAndPost (url);
                    SurveyCommentPost(c, resultMsg);
                }
            }
            else
            {
                NoEmailAddressCommentPost(c);
            }
        }
    }
    

@future (callout=true)
//Modified to add NamedCredentials
public static void SendSDSSurvey(Set<Id> caseIds)
{
    boolean isTest = Test.isRunningTest();
    
    //Loop through all the attendees and attempt to survey the ones that should be surveyed.
    List<Case> cases = new List<Case>();
    cases = [SELECT Account.Customer_Priority__c, ResolvedBy__r.Name, CreatedBy.Name, CaseNumber, Subject, AccountBillingGroup__c, Account.CadebillAccountNo__c, Account.Name, Contact.Name, Contact.Email, Owner.Name, Assigned_To__r.Name, CreatedDate, ClosedDate, Status FROM Case WHERE Id IN :caseIds];
    
    for(Case c: cases)
    {
        //Get the URL from the static configuration file
        string url = Label.CaseSDSClosedWorkOrderServReqSurveyURL;
        
        //replace the place holders in the url with the data from the trip report
        if(c.Contact.Email != null && c.Contact.Email !='')
        {
            url = url.replace('{Case #}', EncodingUtil.urlEncode(c.CaseNumber ,'UTF-8'));
            url = url.replace('{Subject}', EncodingUtil.urlEncode(c.Subject,'UTF-8'));
            
            if(c.Account.CadebillAccountNo__c != null)
            {
                url = url.replace('{CostGuard Acct#}', EncodingUtil.urlEncode(string.valueOf(c.Account.CadebillAccountNo__c),'UTF-8'));
            }
            else
            {
                url = url.replace('{CostGuard Acct#}', EncodingUtil.urlEncode('','UTF-8'));
            }
            if(c.Account.Customer_Priority__c != null)
            {
                url = url.replace('{ServicePackage}', EncodingUtil.urlEncode(c.Account.Customer_Priority__c,'UTF-8'));
            }
            else
            {
                url = url.replace('{ServicePackage}', EncodingUtil.urlEncode('','UTF-8'));
            }
            
            url = url.replace('{Account Name}', EncodingUtil.urlEncode(c.Account.Name,'UTF-8'));
            url = url.replace('{Contact Name}', EncodingUtil.urlEncode(c.Contact.Name,'UTF-8'));
            url = url.replace('{Contact Email}', EncodingUtil.urlEncode(c.Contact.Email,'UTF-8'));
            
            if(c.Owner.Name != null)
            {
                if(c.Owner.Name == 'TSM Queue'){
                    url = url.replace('{Case Owner}', EncodingUtil.urlEncode('Enterprise Customer Management','UTF-8'));
                }
                else{
                    url = url.replace('{Case Owner}', '');
                }
            }
            else
            {
                url = url.replace('{Case Owner}', '');
            }
            
            if(c.Assigned_To__r.Name != null && c.Owner.Name != 'TSM Queue')
            {
                url = url.replace('{Assigned To}', EncodingUtil.urlEncode(c.Assigned_To__r.Name,'UTF-8'));
            }
            else
            {
                if(c.Owner.Name == 'TSM Queue'){
                    if(c.ResolvedBy__c != null){
                        url = url.replace('{Assigned To}', EncodingUtil.urlEncode(c.ResolvedBy__r.Name,'UTF-8'));
                    } else{
                        url = url.replace('{Assigned To}', EncodingUtil.urlEncode('Enterprise Technical Management','UTF-8'));
                    }
                }
                else{
                    url = url.replace('{Assigned To}', EncodingUtil.urlEncode('inContact Service Delivery Support','UTF-8'));
                }
            }
            url = url.replace('{Date/Time Opened}', EncodingUtil.urlEncode(String.valueOf(c.CreatedDate),'UTF-8'));
            url = url.replace('{Date/Time Closed}', EncodingUtil.urlEncode(String.valueOf(c.ClosedDate),'UTF-8'));
            url = url.replace('{Status}', EncodingUtil.urlEncode(c.Status,'UTF-8'));
            
            //FLAG SURVEY IF VERIZON
            if(c.AccountBillingGroup__c == 'Verizon')
            {
                url = url + '&Verizon=yes';
            }
            
            if (url != null)
            {
                String resultMsg = SurveyCallAndPost (url);
                SurveyCommentPost(c, resultMsg);
            }
        }
        else
        {
            NoEmailAddressCommentPost(c);
        }



    }
}

//Code Block for Customer Success Team Surveys Project #21109
@future (callout=true)
//Modified to add NamedCredentials
public static void SendCSSurvey(Set<Id> caseIds)
{
    string cBody;
    boolean isTest = Test.isRunningTest();
    
    //Loop through all the closed cases and attempt to survey the ones that should be.
    
    List<Case> cases = new List<Case>();
    cases = [SELECT CaseNumber, ResolvedBy__r.Name, Subject, AccountBillingGroup__c, Account.CadebillAccountNo__c, Account.Name, Contact.Name, Contact.Email, Owner.Name, Assigned_To__r.Name, CreatedDate, ClosedDate, Status FROM Case WHERE Id IN :caseIds];
    
    for(Case c: cases)
    {
        //Get the URL from the static configuration file
        string url = Label.CaseCustomerSuccessClosedEchoSurveyURL;
        
        //replace the place holders in the url with the data from the closed case table
        if(c.Contact.Email != null && c.Contact.Email !='')
        {
            url = url.replace('{Case #}', EncodingUtil.urlEncode(c.CaseNumber ,'UTF-8'));
            url = url.replace('{Subject}', EncodingUtil.urlEncode(c.Subject,'UTF-8'));
            url = url.replace('{Account Name}', EncodingUtil.urlEncode(c.Account.Name,'UTF-8'));
            url = url.replace('{Contact Name}', EncodingUtil.urlEncode(c.Contact.Name,'UTF-8'));
            url = url.replace('{Contact Email}', EncodingUtil.urlEncode(c.Contact.Email,'UTF-8'));
            
            if(c.Owner.Name != null)
            {
                if(c.Owner.Name == 'Customer Success Queue')
                { 
                    url = url.replace('{Case Owner}', EncodingUtil.urlEncode('Customer Success','UTF-8'));
                }
                else{
                    url = url.replace('{Case Owner}', '');
                }
            }
            else
            {
                url = url.replace('{Case Owner}', '');
            }
            
            //FLAG SURVEY IF VERIZON
            if(c.AccountBillingGroup__c == 'Verizon')
            {
                url = url + '&Verizon=yes';
            }
            
            if (url != null)
            {
                String resultMsg = SurveyCallAndPost (url);
                SurveyCommentPost(c, resultMsg);
            }
        }
        else
        {
            NoEmailAddressCommentPost(c);
        }
    }
}


//Code Block for Uptivity Installation & Optimization Survey Projects #45259, #45301 
// *** NOT IN USE ??? ARNAB
@future (callout=true)
//Modified to add NamedCredentials
public static void SendPremiseInstallationSurvey(Set<Id> caseIds)
{
    boolean isTest = Test.isRunningTest();
    
    //Loop through all the attendees and attempt to survey the ones that should be surveyed.
    List<Case> cases = new List<Case>();
    cases = [SELECT CaseNumber, ResolvedBy__r.Name, Subject, AccountBillingGroup__c, Account.Name, Contact.Name, Contact.Email, Owner.Name, OwnerId, Assigned_To__r.Name, CreatedDate, ClosedDate, Status FROM Case WHERE Id IN :caseIds];
    
    for(Case c: cases)
    {
        //Get the URL from the static configuration file
        string url = Label.CasePremiseInstallationClosedEchoSurveyURL;
        
        
        if(c.Contact.Email != null && c.Contact.Email !='')
        {
            //replace the place holders in the url with the data from the closed case
            url = url.replace('{Case #}', EncodingUtil.urlEncode(c.CaseNumber ,'UTF-8'));
            url = url.replace('{Account Name}', EncodingUtil.urlEncode(c.Account.Name,'UTF-8'));
            url = url.replace('{Contact Email}', EncodingUtil.urlEncode(c.Contact.Email,'UTF-8'));
            
            if(c.Owner.Name != null)
            {
                if(c.Owner.Name == 'Premise Optimization Queue') 
                { 
                    url = url.replace('{Case Owner}', EncodingUtil.urlEncode('Uptivity Optimization','UTF-8'));
                }
                else if(c.Owner.Name == 'Premise Installation Queue')
                {
                    url = url.replace('{Case Owner}', EncodingUtil.urlEncode('Uptivity Installation','UTF-8'));
                }
                else
                {
                    url = url.replace('{Case Owner}', '');
                }
            }
            else
            {
                url = url.replace('{Case Owner}', '');
            }
            
            if(c.Assigned_To__c != null)
            {
                url = url.replace('{Assigned To}', EncodingUtil.urlEncode(c.Assigned_To__r.Name,'UTF-8'));
            }
            else
            {
                if (c.Owner.Name == 'Premise Optimization Queue') 
                { 
                    url = url.replace('{Assigned To}', EncodingUtil.urlEncode('Uptivity Optimization','UTF-8'));
                }
                else if(c.Owner.Name == 'Premise Installation Queue')
                {
                    url = url.replace('{Assigned To}', EncodingUtil.urlEncode('Uptivity Installation','UTF-8'));
                }
                else
                {
                    url = url.replace('{Assigned To}', EncodingUtil.urlEncode('Uptivity Service Delivery','UTF-8'));
                }
            }
            
            if (url != null){
                String resultMsg = SurveyCallAndPost (url);
                SurveyCommentPost(c, resultMsg);
            }
        }
        else
        {
            NoEmailAddressCommentPost(c);
        }
    }
}  

} //End of Class