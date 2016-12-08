public class NotificationHelperClass 
{
	
	public static string GenerateEmail(String[] addresses, string subject, string htmlBody, string textBody,integer templateId)
	{
        //system.debug(addresses);
        
		Notificationproxy.AuthHeader ah = new Notificationproxy.AuthHeader();
		ah.Username = InContactConfiguration.NotificationUserName;
		ah.Password = InContactConfiguration.NotificationPassword;
		Notificationproxy.ArrayOfString aos = new Notificationproxy.ArrayOfString();
		aos.string_x = addresses;
		Notificationproxy.NotificationProxySoap npp = new Notificationproxy.NotificationProxySoap();
		npp.AuthHeader = ah;
		npp.timeout_x = 50000;
		//npp.clientCertName_x = null;
		string result = npp.SendEmail(aos,subject,htmlBody,textBody,templateId);
		system.debug('webservice response ==>' + result);
        system.debug('addresses => ' + aos);
        
		return result;
        
        
	}
	
    @future(callout=true)
    public static void ResolvedEventEmail(Id eventId)
    {
        Case event = [SELECT Id,CustomerAction__c, EndDateTimeUTC__c,StartDateTImeUTC__c, EventType__c, CustomersMayExperienceTheFollowing__c, OwnerId, Owner.Name, Status, Subject, Priority, Description, RecordTypeId, EventEmailSent__c, CaseNumber, PlatformsImpacted__c, ProductImpacted__c FROM Case WHERE ID = :eventId];
		CaseEventClass cec = new CaseEventClass(event);
        
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(event);
        CaseEventNotificationExtension notificationExtension = new CaseEventNotificationExtension(stdCtrl);
        
        //set body and subject
        notificationExtension.emailBody = Label.EventResolvedEmail;
        notificationExtension.SubjectText = Label.EventResolvedSubject;
        
        //update merge fields
        notificationExtension.MergeFieldUpdate();
        notificationExtension.MergeFieldUpdateSubject();
        
        //send notificiation
        try
        {
            notificationExtension.SendNotification();
        }
        catch(Exception ex)
        {
            inContactBaseClass.SendErrorEmail(ex, 'Event: ' + event.CaseNumber);
        }
        
    }
	
    @future(callout=true)
	public static void NewEventEmailAsync(Id eventId, list<string> lstPlatforms)
	{
		Case event = [SELECT Id,CustomerAction__c,StartDateTImeUTC__c,EndDateTimeUTC__c, EventType__c, CustomersMayExperienceTheFollowing__c, OwnerId, Owner.Name, Status, Subject, Priority, Description, RecordTypeId, EventEmailSent__c, CaseNumber, PlatformsImpacted__c, ProductImpacted__c FROM Case WHERE ID = :eventId];
		system.debug('testing event ==>' + event);
        system.debug('testing lstPlatforms NewEventEmailAsync ==>' + lstPlatforms);
		//if(!event.EventEmailSent__c)
		//{
		//
			CaseEventClass cec = new CaseEventClass(event);
        	if(lstPlatforms != null)
				cec.lstClusters = lstPlatforms; // Added by Aranb
        
            CaseEventNotificationExtension.clusters = lstPlatforms;
			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(event);
			CaseEventNotificationExtension notificationExtension = new CaseEventNotificationExtension(stdCtrl);
			
			//set body and subject
			notificationExtension.emailBody = InContactConfiguration.NewEventEmailBody;
			notificationExtension.SubjectText = InContactConfiguration.NewEventEmailSubject;

			//update merge fields
			notificationExtension.MergeFieldUpdate();
			notificationExtension.MergeFieldUpdateSubject();
			
			//send notificiation
			try
            {
				notificationExtension.SendNotification();
            }
            catch(Exception ex)
            {
                inContactBaseClass.SendErrorEmail(ex, 'Event: ' + event.CaseNumber);
            }
			
			event.EventEmailSent__c = true;
			update event;
		//}
	}
    // Added by Arnab
    @future(callout=true)
    public static void futureCallout(String[] thisaddresses, string thisSubject, string thisHtmlBody, string thisTextBody,integer thistemplateId, string jobId){
      // Get the values for the custom settings
       Number_Of_Retry__c retry = new Number_Of_Retry__c();	
	   retry = Number_Of_Retry__c.getInstance(jobId);  
       Integer intRetry;
       Boolean isOverride = true; 
       if(retry != null)
       {
          intRetry = integer.valueOf(retry.Retry__c); 
          isOverride = Boolean.valueOf(retry.IsManualOverRide__c); 
       }
        
       // Email template  
       string emailResult = ''; 
       list<EmailTemplate> listTemplates = new list<EmailTemplate>(); 
	   EmailTemplate template = new EmailTemplate();
        
       template.recipients = thisaddresses;
       template.subject = thisSubject;
       template.htmlBody = thisHtmlBody;
       template.textBody = thisTextBody; 
       template.templateId = thistemplateId; 
       listTemplates.add(template);
       
        emailResult = NotificationHelperClass.CallNotificationService(template);

        // if failed again .. call the BatchClass.
        if(emailResult == 'ConnectionFailure' && intRetry < 3 && !isOverride){
            update new Number_Of_Retry__c (
               Id =  retry.Id,               
               Retry__c = intRetry + 1
            );
            system.debug('inside if =>' + intRetry); 
        	System.enqueueJob(new NotificationQueableClass(listTemplates, jobId));
        }
        
        if(intRetry >= 3 ){ 
            delete new Number_Of_Retry__c (
               Id =  retry.Id
            );
         string error = 'The service failed to send email. It failed after several retries. Please check the service';
             			
         
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         String[] toAddresses = new String[]{};       
         toAddresses = Label.DEVErrorEmailRecipient.split(',');
         toAddresses.add(Userinfo.getUserEmail());  
         mail.setToAddresses(toAddresses);
         mail.setSubject('Email service failed');
         mail.setPlainTextBody(error);
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	  	 
            
        }
        
    }
    public static string CallNotificationService(EmailTemplate batchCaseEmails)
    {
         // attempt to send email 
        String[] batchAddresses = new String[]{};
        string batchEmailResult = '';
        boolean resellEmailResult = true;
        list<integer> caseNums = new list<integer>();
        String[] resellAddresses = new String[]{};
        
		for(integer i = 0; i<batchCaseEmails.recipients.Size();i++)
       	{
          batchAddresses.add(batchCaseEmails.recipients[i]);
          
          if(batchAddresses.size()==900 || i+1 == batchCaseEmails.recipients.Size())
          {
           	//if(!Test.isRunningTest()){
                batchEmailResult = NotificationHelperClass.GenerateEmail(batchAddresses, batchCaseEmails.subject, batchCaseEmails.htmlBody, batchCaseEmails.textBody,6);
            //}
            if(batchEmailResult == 'ConnectionFailure')
            { 
               //CaseNums.add()
                break;
            }  
          }
        }   
     
        return batchEmailResult;
        
    }

     Public class EmailTemplate
    {
        public String[] recipients;
        public string   subject;
        public string   htmlBody;
        public string 	textBody;
        public integer  templateId;   
        public boolean  isResell;
        
    }
    
}