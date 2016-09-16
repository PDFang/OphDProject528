/**
 * Email services are automated processes that use Apex classes
 * to process the contents, headers, and attachments of inbound
 * email.
 */
global class EmailCarrierMaintenance implements Messaging.InboundEmailHandler 
{

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		
		string accountId;
		string contactId;
		
		Case c = new Case();
		Id recType;
		String[] emailList = new String[]{email.fromAddress};
		
		Schema.DescribeSObjectResult d = Schema.SObjectType.Case; 
		Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
		recType = rtMapByName.get('Service Request').getRecordTypeId();
		
		accountId = [SELECT Id FROM Account WHERE CadebillAccountNo__c = 100001].Id;
		contactId = [SELECT Id FROM Contact WHERE LastName = 'NOC' AND FirstName = '' AND AccountId = :accountId LIMIT 1].id;
		
		c.Subject = email.subject;
		
		if(email.plainTextBody == null)
		{
			c.Description = email.htmlBody.left(32000);
		}
		else
		{
			c.Description = email.plainTextBody.left(32000);
		}
		
		c.RecordTypeId = recType;
		c.Status = 'Acknowledged';
		c.Origin = 'Email';
		c.Request_Type__c = 'Account Maintenance';
		c.Product_or_Service__c = 'Account Maintenance';
		c.SubProductorService__c = 'Circuits';
		c.Product_or_Service_Details__c = 'Full Loops';
		c.Priority = 'P4';
		c.AccountId = accountId;
		c.ContactId = contactId;
		
		
		//set default assignment rule		
		database.DMLOptions dmo = new database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
        dmo.EmailHeader.triggerUserEmail = true;
        
        c.setOptions(dmo);
		
		insert c;
		
		handleAttachments(c,email);
		
		
		EmailMessage[] newEmail = new EmailMessage[]{};
		
		newEmail.add(
			new EmailMessage
			(
				FromAddress = email.fromAddress,
				FromName = email.fromName,
				Subject = limitLength(email.Subject, EmailMessage.Subject.getDescribe().getLength()),
				
				HtmlBody = limitLength(email.htmlBody,EmailMessage.HtmlBody.getDescribe().getLength()),
				MessageDate = datetime.now(),
				ParentId = c.Id
			)
			);  
 			if(email.toAddresses != null)
 			{
				newEmail[0].ToAddress = email.toAddresses[0];
 			}
 			
 			if(email.plainTextBody != null)
			{
				newEmail[0].TextBody = limitLength(email.plainTextBody,EmailMessage.TextBody.getDescribe().getLength());
			}
			else
			{
				newEmail[0].TextBody = 'No text body.';
			}
			
			insert newEmail;	
			

        return result;
    }
    
    private String limitLength(String input, Integer maxLength)
	{
		 String results;
		 if(input != null && input.length() > maxLength)
		 {
		 	results = input.substring(0,maxLength);
		 }
		 else
		 { 
		 	results = input;
		 }
		 return results;
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