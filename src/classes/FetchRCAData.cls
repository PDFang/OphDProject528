public with Sharing class FetchRCAData
{ 
   
    public BMCServiceDesk__Problem__c PRB {get;set;}
    
    public String currentRecordId {get;set;}
    
    public user currentuser{get;set;}
    
    public FetchRCAData()
    
    {
        currentuser=new User();
        
        currentuser=[Select Id,Name,Email from User where Id=:userinfo.getuserId()];
        
        currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
        
        PRB = [SELECT Name,RF_Event_Start_Date_Time__c,RF_Event_End_Date_Time__c,RF_Customer_Impact__c,RF_Discovery_Source_of_Problem__c,RF_Incident_Resolution__c,RF_Risk_of_Reoccurrence__c,RF_Root_Cause__c,RF_Remediation__c,RF_Remediation_Status__c,BMCServiceDesk__FKStatus__c,CreatedById,OwnerId,BMCServiceDesk__FKStaff__c FROM BMCServiceDesk__Problem__c where id =: currentRecordId];
             
    }
    
    public PageReference sendPdf()
    {
    
    PageReference pdf = Page.RF_RCA_Problem_Details;
    
    pdf.getParameters().put('id',currentRecordId);

    // the contents of the attachment from the pdf
    Blob body;

    try {

      // returns the output of the page as a PDF
      body = pdf.getContentAsPDF();
 
    } catch (VisualforceException e) {
      body = Blob.valueOf('Some Text');
    }

    Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
    attach.setContentType('application/pdf');
    attach.setFileName('inContact_Problem_RCA_Details.pdf');
    attach.setInline(false);
    attach.Body = body;

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setUseSignature(false);
    mail.setToAddresses(new String[] {currentuser.Email});
    mail.setSubject('inContact Problem Management Details');
    mail.setSenderDisplayName('inContact HelpDesk');
    mail.setHtmlBody('Here is the email you requested! Check the attachment!');
    mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 

    try
    {
    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    catch(System.EmailException e)
    {
    ApexPages.Message myMsg2 = new ApexPages.Message(ApexPages.Severity.ERROR,'Your daily Email limit has been exceeded. Please Contact your System Administrator');
        ApexPages.addMessage(myMsg2);
    }
   
   finally
    {
    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Mail Sent Successfully to '+currentuser.Name));
    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Please ensure that your daily email limits are not getting exceeded in case of failure in Mail Delivery'));
    }
   
 
    return null;

  }

}