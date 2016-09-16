global class EmailSustainingEngineering implements Messaging.InboundEmailHandler 
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
		
		Case newCase = new Case();
		Account acct = [SELECT Id FROM Account WHERE CadebillAccountNo__c = 100001];
		
		newCase.Origin = 'Alert';
		newCase.Product_or_Service__c = 'Billing Report Executable';
		newCase.AccountId = acct.Id;
        newCase.Urgency__c = 'Medium';
        newCase.Impact__c = 'Medium';
		newCase.Subject = email.subject;
		newCase.Description = email.plainTextBody;
		newCase.RecordTypeId = rtMapByName.get('Incident').getRecordTypeId();
		newCase.Request_Type__c = 'Production Issue';
		
		newCase.setOptions(dmo);
		
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