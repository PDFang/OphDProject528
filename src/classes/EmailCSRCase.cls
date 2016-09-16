/**
 * Email services are automated processes that use Apex classes
 * to process the contents, headers, and attachments of inbound
 * email.
 */
global class EmailCSRCase implements Messaging.InboundEmailHandler 
{

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		
		Contact ct = new Contact();
		Case c = new Case();
		Id recType;
		string urlString;
		String[] emailList = new String[]{email.fromAddress};
		
		//get url for ccr link
    	urlString = URL.getSalesforceBaseUrl().toExternalForm();	
    	urlString = urlString + '/';
    	urlString = urlString.replace('-api','');
		
		Schema.DescribeSObjectResult d = Schema.SObjectType.Case; 
		Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
		recType = rtMapByName.get('Service Request').getRecordTypeId();
		
		//see if contact exists
		if(1 == [SELECT Count() FROM Contact WHERE Email = :email.fromAddress LIMIT 1])
		{
			ct = [SELECT Id, AccountId FROM Contact WHERE Email = :email.fromAddress LIMIT 1];
		}
		
		c.Subject = email.subject;
		c.Description = email.plainTextBody;
		c.RecordTypeId = recType;
		c.Status = 'New';
		c.Request_Type__c = 'General Service Request';
		c.Product_or_Service__c = 'Other';
		
		if(ct.Id != null)
		{
			c.ContactId = ct.id;
			c.AccountId = ct.AccountId;	
		}
		
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
				ToAddress = email.toAddresses[0],
				Subject = limitLength(email.Subject, EmailMessage.Subject.getDescribe().getLength()),
				TextBody = limitLength(email.plainTextBody,EmailMessage.TextBody.getDescribe().getLength()),
				HtmlBody = limitLength(email.htmlBody,EmailMessage.HtmlBody.getDescribe().getLength()),
				MessageDate = datetime.now(),
				ParentId = c.Id
			)
			);  
 
			insert newEmail;	
			
	    Case caseResults = [SELECT CaseNumber, Id, Subject FROM Case WHERE Id = :c.Id];
	    
	    //create message
    	Messaging.SingleEmailMessage sendEmail = new Messaging.SingleEmailMessage();
    	sendEmail.setSubject('Case ' + caseResults.CaseNumber + ' has been created.');
    	sendEmail.setToAddresses(emailList);
    	
    	String bodyString;
    	bodyString = '<h2>Case <a href="' + urlString + c.Id + '">' + caseResults.CaseNumber + '</a> has been created</h2>';
    	bodyString = bodyString + '<p>' + email.htmlBody + '</p>';
    	sendEmail.setHtmlBody(bodyString);	
    	
    	//send message
    	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { sendEmail });

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
	 
	 public static testMethod void mTestEmailCSRCase() 
	 {

		   // Create a new email, envelope object and Attachment
		   Messaging.InboundEmail email = new Messaging.InboundEmail();
		   Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
		   Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
		
		   email.fromAddress = 'jeremy.sparrell@incontact.com';
		   email.subject = 'test';
		   email.plainTextBody = 'test';
		   email.htmlBody = 'test';
		   email.ToAddresses = new String[]{'jeremy.sparrell@incontact.com'};
		   env.fromAddress = 'jeremy.sparrell@incontact.com';
		
		   // set the body of the attachment
		   inAtt.body = blob.valueOf('test');
		   inAtt.fileName = 'my attachment name';
		   inAtt.mimeTypeSubType = 'plain/txt';
		
		   email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
		
		   // call the class and test it with the data in the testMethod
		   EmailCSRCase emailServiceObj = new EmailCSRCase();
		   emailServiceObj.handleInboundEmail(email, env );                      
	}    
	 
}