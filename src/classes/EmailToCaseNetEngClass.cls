/**
 * Email services are automated processes that use Apex classes
 * to process the contents, headers, and attachments of inbound
 * email.
 * 
 * This class receives an inbound email,creates a case and map 
 * specific email components to case fields.
 */

global class EmailToCaseNetEngClass implements Messaging.InboundEmailHandler 
{

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        
        Schema.DescribeSObjectResult d = Schema.SObjectType.Case; 
    Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
    Map<ID,Schema.RecordTypeInfo> recordTypeMapById = d.getRecordTypeInfosByID();
    
    //set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        dmo.emailHeader.triggerAutoResponseEmail = true;
    
    Contact ct = new Contact();
    Case newCase = new Case ();
    Account acct = [SELECT Id FROM Account WHERE CadebillAccountNo__c = 100001];
    
    //see if contact exists
        if(1 == [SELECT Count() FROM Contact WHERE Email = :email.fromAddress LIMIT 1])
        {
            ct = [SELECT Id, AccountId FROM Contact WHERE Email = :email.fromAddress LIMIT 1];
        }
        
    //map the required fields    
    newCase.Origin = 'Email';
    newCase.Product_or_Service__c = 'inContact';
    newCase.AccountId = acct.Id;
    newCase.Subject = email.subject;
    newCase.Description = email.plainTextBody;
    newCase.Priority = 'P4';
    newCase.SuppliedEmail = email.fromAddress;   
    newCase.RecordTypeId = rtMapByName.get('Work Orders').getRecordTypeId();
    newCase.Request_Type__c = 'NetEng Work Order';
    newCase.setOptions(dmo);

    //map the sender to the contact field    
    	if(ct.Id != null)
		{
			newCase.ContactId = ct.id;
		}
        
    insert newCase;
    
    handleAttachments(newCase,email);

        return result;
    }
    
    // Save attachments, if any
  private void handleAttachments(Case theCase, Messaging.InboundEmail email) 
  {
    if(email.textAttachments!=null && email.textAttachments.size() >0) 
    {
        for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) 
        {
          Attachment attachment = new Attachment();  
          attachment.Name = tAttachment.fileName;
          attachment.Body = Blob.valueOf(tAttachment.body);
          attachment.ParentId = theCase.Id;
          insert attachment;
        }
      }
   
   
     if(email.binaryAttachments!=null && email.binaryAttachments.size() >0) 
     {
        for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) 
        {
          Attachment attachment = new Attachment();
          attachment.Name = bAttachment.fileName;
          attachment.Body = bAttachment.body;
          attachment.ParentId = theCase.Id;
          insert attachment;
        }
     }
   }  
}