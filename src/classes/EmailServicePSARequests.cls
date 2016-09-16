/**
 * Email services are automated processes that use Apex classes
 * to process the contents, headers, and attachments of inbound
 * email.
 */
global class EmailServicePSARequests implements Messaging.InboundEmailHandler 
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
		Set<String> incidentAddresses = new Set<String>{'solarwinds@ucn.net','ipmonitor@ucn.net'};
		
		newCase.Origin = 'Email';
		newCase.Product_or_Service__c = 'inContact';
		newCase.AccountId = acct.Id;
		newCase.Subject = email.subject;
		newCase.Description = email.plainTextBody;
		
		if(incidentAddresses.contains(email.fromAddress.toLowerCase()))
		{
			newCase.RecordTypeId = rtMapByName.get('Incident').getRecordTypeId();
			newCase.Request_Type__c = 'Monitor Alert';
		}
		else
		{
			newCase.RecordTypeId = rtMapByName.get('Work Orders').getRecordTypeId();
			newCase.Request_Type__c = 'PSA Work Order';
		}
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