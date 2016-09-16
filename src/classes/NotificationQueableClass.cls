public class NotificationQueableClass implements Queueable, Database.AllowsCallouts {
  
    public list<NotificationHelperClass.EmailTemplate> allTemplates = new list<NotificationHelperClass.EmailTemplate>();
    
    public NotificationQueableClass(list<NotificationHelperClass.EmailTemplate> listCaseEmailTemplates){
            allTemplates = listCaseEmailTemplates;
           
        
    } 

    public void execute(QueueableContext context){
        // attempt to send email 
        boolean emailResult = true;   

        for(NotificationHelperClass.EmailTemplate template : allTemplates)
        {
            if(!test.isRunningTest())
            {
                emailResult = NotificationHelperClass.CallNotificationService(template);
                if(!emailResult)
                    break;
            }
         }   
        
        // if test is running return false.        
        if(test.isRunningTest())
           emailResult = false;
        
        Number_Of_Retry__c retry = new Number_Of_Retry__c();    
        retry = Number_Of_Retry__c.getInstance('Enqueued');
        Integer intRetry = integer.valueOf(retry.Retry__c);
        system.debug('intretry =>' + intRetry);       
        
        // if failed call the future method because we cant call the same queuable class if there is a webservice callout
        // Salesforce limitation
        if(!emailResult && intRetry < 3){
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
                  NotificationHelperClass.futureCallout(template.recipients,template.subject,template.htmlBody,template.textBody,template.templateId);
                  i++;
             }
         }
        }
        else if(intRetry >= 3){
            update new Number_Of_Retry__c (
               Id =  retry.Id,               
               Retry__c = 0
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