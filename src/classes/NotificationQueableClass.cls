public class NotificationQueableClass implements Queueable, Database.AllowsCallouts {
  
    public list<NotificationHelperClass.EmailTemplate> allTemplates = new list<NotificationHelperClass.EmailTemplate>();
    public string firstJobId = '';
    public NotificationQueableClass(list<NotificationHelperClass.EmailTemplate> listCaseEmailTemplates, string jobId){
            allTemplates = listCaseEmailTemplates;
        	if(jobId != '')
                firstJobId = jobId;
    } 

    public void execute(QueueableContext context){
        // attempt to send email 
        string emailResult = '';   
		
       
        
        for(NotificationHelperClass.EmailTemplate template : allTemplates)
       	{
			
             	emailResult = NotificationHelperClass.CallNotificationService(template);
            	if(emailResult != 'Success')
                	break;
         }   

        if(firstJobId == ''){
            firstJobId = (string)context.getJobId();
            insert new Number_Of_Retry__c(
                               Retry__c = 1,
                               Name = firstJobId,
                               IsManualOverRide__c = false
                              );
        }
        
        Number_Of_Retry__c retry = Number_Of_Retry__c.getInstance(firstJobId);
        Integer intRetry = integer.valueOf(retry.Retry__c);
        boolean isOverride = Boolean.valueOf(retry.IsManualOverRide__c); 
        
        system.debug('intretry =>' + intRetry);       
        
        // if failed call the future method because we cant call the same queuable class if there is a webservice callout
        // Salesforce limitation
        if(emailResult == 'ConnectionFailure' && intRetry < 3 && !isOverride){
            update new Number_Of_Retry__c (
               Id =  retry.Id,               
               Retry__c = intRetry + 1
            );
         // call the future method
         integer i = 0;
       for(NotificationHelperClass.EmailTemplate template : allTemplates)
         {             
             if(i < 2)
             {
                  NotificationHelperClass.futureCallout(template.recipients,template.subject,template.htmlBody,template.textBody,template.templateId, firstJobId);
       			  i++;
             }
         }
        }
        else if(intRetry >= 3){
            
            if(!test.isRunningTest())
            {
                delete new Number_Of_Retry__c (
                   Id =  retry.Id
                );
             
                
               // if all tries fails - send an email to DEV team.
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
           
                
    }
    
}