global class InContactWebServices 
{    
  /* Constructs the Echo Survey URL, makes a http callout, and sents the survey date. */
  WebService static String SendEchoSurveyByTrip_ReportId(ID tripReportId, boolean test) 
  {
    List<Trip_Attendee__c> attendees = new List<Trip_Attendee__c>([SELECT t.Trip_Report__r.Account__r.Name, t.Trip_Report__r.Account__r.CadebillAccountNoText__c, t.Trip_Report__c, t.Survey__c, t.SurveySpawnDate__c,  t.Trip_Report__r.CreatedBy.Name, t.Trip_Report__r.CreatedById, t.Attendee__r.Email, t.Attendee__r.FirstName, t.Attendee__r.LastName, t.Attendee__r.Name, t.Attendee__c, t.Trip_Report__r.RecordType.Name FROM Trip_Attendee__c t WHERE t.Survey__c = true AND t.SurveySpawnDate__c = null AND t.Trip_Report__c = :tripReportId]);
    String results = '';
    List<Trip_Attendee__c> updatedAttendees = new List<Trip_Attendee__c>();
    
    //Loop through all the attendees and attempt to survey the ones that should be surveyed.
    for(Trip_Attendee__c attendee : attendees)
    {
      //Get the URL from the static configuration file
      string url = ''; 
      
      if(attendee.Trip_Report__r.RecordType.Name == 'SDM Trip' || attendee.Trip_Report__r.RecordType.Name == 'Business Consulting Trip')
      {
        url = InContactConfiguration.TripReportEchoSurveyURL;
        //replace the place holders in the url with the data from the trip report
        url = url.replace('{Email1}', EncodingUtil.urlEncode(attendee.Attendee__r.Email,'UTF-8'));
        url = url.replace('{CustomerAcctNumber}', EncodingUtil.urlEncode(attendee.Trip_Report__r.Account__r.CadebillAccountNoText__c,'UTF-8'));
        url = url.replace('{Company}', EncodingUtil.urlEncode(attendee.Trip_Report__r.Account__r.Name,'UTF-8'));
        url = url.replace('{CSM}', EncodingUtil.urlEncode(attendee.Trip_Report__r.CreatedBy.Name,'UTF-8'));
        url = url.replace('{FirstName}', EncodingUtil.urlEncode(attendee.Attendee__r.FirstName,'UTF-8'));
        url = url.replace('{LastName}', EncodingUtil.urlEncode(attendee.Attendee__r.LastName,'UTF-8'));
        
        if(attendee.Trip_Report__r.RecordType.Name == 'Business Consulting Trip')
        {
          url = url + '&BCO=true';
        }
      }
      else if(attendee.Trip_Report__r.RecordType.Name == 'Education Trip' || attendee.Trip_Report__r.RecordType.Name == 'Enablement Trip')
      {
        url = InContactConfiguration.EducationTripReportEchoSurveyURL;
        //replace the place holders in the url with the data from the trip report
        url = url.replace('{Email1}', EncodingUtil.urlEncode(attendee.Attendee__r.Email,'UTF-8'));
        url = url.replace('{CustomerAcctNumber}', EncodingUtil.urlEncode(attendee.Trip_Report__r.Account__r.CadebillAccountNoText__c,'UTF-8'));
        url = url.replace('{customerName}', EncodingUtil.urlEncode(attendee.Attendee__r.FirstName + ' ' + attendee.Attendee__r.LastName,'UTF-8'));
        url = url.replace('{CSM}', EncodingUtil.urlEncode(attendee.Trip_Report__r.CreatedBy.Name,'UTF-8'));
        url = url.replace('{subject}', EncodingUtil.urlEncode('Feedback on inContact\'s training','UTF-8'));
        
      }
      
      if(url != '')
      {
        //Create an HttpRequest object for posting to the Echo survey site
        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setTimeout(30000); 
          
        //body information to trigger Cast Iron orchestration
        req.setBody('');
        Http http = new Http();
          
          //If this isn't a test method then go ahead and make the web service call
          string resultMsg = '';
        if(!test)
        {
          HTTPResponse res = http.send(req);
          resultMsg = res.getBody();
        }
        
        //check the response message for an error.
        if(resultMsg.contains('Error'))
        {
          results = results + 'Survey NOT sent to ' + attendee.Attendee__r.Name + ' (' + resultMsg.trim() + ')\n\r';
        }
        else
        {
          attendee.SurveySpawnDate__c = DateTime.Now();
          updatedAttendees.add(attendee);
          results = results + 'Survey sent to ' + attendee.Attendee__r.Name + '.\n\r';
        }
      }  
    }    
    
    //update the attendee records
    update updatedAttendees;
    
    return results;
  }
  
  /* Resets Partner API User Password */
  WebService static String ResetParnterAPIUserPassword(String ADFSGuid, boolean isTest) 
  {
    string results = '';
    string url = InContactConfiguration.PartnerUserResetPasswordURL;      
    String httpBody = ADFSGuid;
       
       system.debug('***************************************************************');
       system.debug(httpBody);
       system.debug('***************************************************************');
         
       
        //http info
        HttpRequest req = new HttpRequest();
       req.setEndpoint(url);
       req.setMethod('POST');
       
       //If this isn't a test method then go ahead and make the web service call
     string resultMsg = '';
       if(!isTest)
       {
      //body information to trigger Cast Iron orchestration
       req.setBody(httpBody);
       Http http = new Http();
      
              //Execute web service call here    
         HTTPResponse res = http.send(req);
         
         system.debug(res.getBody());
          resultMsg = res.getBody();
    }
      
    //check the response message for an error.
    if(resultMsg.contains('Error'))
    {
      results = results + 'Password reset request was NOT successful.  Please send the following message to IT Developers (' + resultMsg.trim() + ')\n\r';
    }
    else
    {
      results = results + 'Password reset was successful.\n\r';
    }  
    
    return results;
  }
  
  WebService static string GetAlertMessage()
  {
    string messageText = '';
    string space = '&nbsp;';
    Datetime current = system.now();
    BannerAlert__c[] baList = new BannerAlert__c[]{};
    baList = [SELECT AlertMessage__c FROM BannerAlert__c WHERE (AlertStart__c = NULL OR AlertStart__c < :current) AND Expires__c > :current ];
    
    if(!baList.isEmpty())
    {
      for(BannerAlert__c ba:baList )
      {
        if(messageText == '')
        {
          messageText = ba.AlertMessage__c;
        }
        else
        {
          messageText = messageText + space.repeat(150) + ba.AlertMessage__c;
        }
      }
    }
    return messageText;  
  }
    
    Webservice static void SyncTfsWorkItem(string workItemId, integer tfsId)
    {
       TfsAccess.SyncTfsWorkItem(workItemId,tfsId);   
    }
  
}