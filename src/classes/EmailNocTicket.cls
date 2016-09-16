/**
 * Email services are automated processes that use Apex classes
 * to process the contents, headers, and attachments of inbound
 * email.
 */
global class EmailNocTicket implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
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
		recType = rtMapByName.get('Incident').getRecordTypeId();
		
		//see if contact exists
		if(1 == [SELECT Count() FROM Contact WHERE Email = :email.fromAddress LIMIT 1])
		{
			ct = [SELECT Id, AccountId FROM Contact WHERE Email = :email.fromAddress LIMIT 1];
		}
		
		c.Subject = email.subject;
		c.Description = email.plainTextBody.left(32000);
		c.RecordTypeId = recType;
		c.Status = 'New';
		c.Request_Type__c = 'Alarm';
		c.Origin = 'Alarm';
		c.Priority = 'P3';
		c.Urgency__c = 'Medium';
		c.Impact__c = 'Low';
		c.Incident_Location__c = 'United States';
		
		
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
}