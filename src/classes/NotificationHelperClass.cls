public class NotificationHelperClass 
{
    
    public static boolean GenerateEmail(String[] addresses, string subject, string htmlBody, string textBody,integer templateId)
    {
        system.debug(addresses);
        Notificationproxy.AuthHeader ah = new Notificationproxy.AuthHeader();
        ah.Username = InContactConfiguration.NotificationUserName;
        ah.Password = InContactConfiguration.NotificationPassword;
        Notificationproxy.ArrayOfString aos = new Notificationproxy.ArrayOfString();
        aos.string_x = addresses;
        Notificationproxy.NotificationProxySoap npp = new Notificationproxy.NotificationProxySoap();
        npp.AuthHeader = ah;
        npp.timeout_x = 50000;
        //npp.clientCertName_x = null;
        boolean b = npp.SendEmail(aos,subject,htmlBody,textBody,templateId);
        system.debug('webservice response ==>' + b);
        system.debug('addresses => ' + aos);
        
        return b;
        
        
    }
    
    
    @future(callout=true)
    public static void NewEventEmailAsync(Id eventId, list<string> lstPlatforms)
    {
        Case event = [SELECT Id,CustomerAction__c,StartDateTImeUTC__c, EventType__c, CustomersMayExperienceTheFollowing__c, OwnerId, Owner.Name, Status, Subject, Priority, Description, RecordTypeId, EventEmailSent__c, CaseNumber, PlatformsImpacted__c, ProductImpacted__c FROM Case WHERE ID = :eventId];
        system.debug('testing event ==>' + event);
        //if(!event.EventEmailSent__c)
        //{
            if(lstPlatforms != null)
                CaseEventNotificationExtension.clusters = lstPlatforms; // Added by Aranb
        
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
    public static void futureCallout(String[] thisaddresses, string thisSubject, string thisHtmlBody, string thisTextBody,integer thistemplateId){
       Number_Of_Retry__c retry = new Number_Of_Retry__c(); 
       retry = Number_Of_Retry__c.getInstance('Enqueued');
       Integer intRetry = integer.valueOf(retry.Retry__c); 
       boolean emailResult = true; 
       list<EmailTemplate> listTemplates = new list<EmailTemplate>(); 
       EmailTemplate template = new EmailTemplate();
        
       template.recipients = thisaddresses;
       template.subject = thisSubject;
       template.htmlBody = thisHtmlBody;
       template.textBody = thisTextBody; 
       template.templateId = thistemplateId; 
       listTemplates.add(template);
        //if(!test.isRunningTest()){
                emailResult = NotificationHelperClass.CallNotificationService(template);
            
        //}
        
        // if test is running return false.        
        if(test.isRunningTest())
           emailResult = false;

        // if failed again .. call the BatchClass.
        if(!emailResult && intRetry < 3){
            update new Number_Of_Retry__c (
               Id =  retry.Id,               
               Retry__c = intRetry + 1
            );
             system.debug('inside if =>' + intRetry); 
            System.enqueueJob(new NotificationQueableClass(listTemplates));
        }
        
        if(intRetry >= 3 ){ //&& !test.isRunningTest()){
            update new Number_Of_Retry__c (
               Id =  retry.Id,               
               Retry__c = 0
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
    public static boolean CallNotificationService(EmailTemplate batchCaseEmails)
    {
         // attempt to send email 
        String[] batchAddresses = new String[]{};
        boolean batchEmailResult = true;
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
            if(!batchEmailResult)
            { 
               //CaseNums.add()
                break;
            }  
          }
        }   
       if(test.isRunningTest())
           batchEmailResult = false;
        
        return batchEmailResult;
        
    }

     Public class EmailTemplate
    {
        public String[] recipients;
        public string   subject;
        public string   htmlBody;
        public string   textBody;
        public integer  templateId;   
        public boolean  isResell;
        
    }
    
}