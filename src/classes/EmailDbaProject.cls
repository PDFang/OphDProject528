global class EmailDbaProject  implements Messaging.InboundEmailHandler 
{
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		
        
		Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c; 
		Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
		Id databaseAdministrationRecordType = rtMapByName.get('Database Administration Request').getRecordTypeId();
        
        try
        {
            User[] users = [SELECT Id FROM User WHERE IsActive = true AND UserType = 'Standard' AND Email = :email.fromAddress];
            Id requester = null;
            
            
            Date currentDate = system.today();
			Date sunday = Date.newInstance(1900, 1, 7);
            Date expectedDate;
            Integer dayOfWeek = Math.mod(sunday.daysBetween(currentDate),7);
            
            if(dayOfWeek == 6)
            {
                expectedDate = currentDate.addDays(3);
            }
            else if(dayOfWeek == 4 || dayOfWeek == 5)
            {
                expectedDate = currentDate.addDays(4);
            }
            else
            {
                expectedDate = currentDate.addDays(2);
            }
            
            if(!users.isEmpty())
            {
                requester = users[0].Id;
            }
        
            Project__c pj = new Project__c();
            pj.Summary__c = email.subject;
            pj.ProjectPriority__c = 'Normal';
            pj.ProjectType__c = 'inContact NG';
            pj.ProjectSubType__c = 'Code Review';
            pj.ProjectStatus__c = 'New';
            pj.ExpectedDeliveryDate__c = expectedDate;
            pj.RecordTypeId = databaseAdministrationRecordType;
            pj.Project_Requester__c = envelope.fromAddress;
            //if there is a user associated to the email set it as the creator
            if(requester != null)
            {
            	//pj.CreatedById = requester;
            }
            
            if(email.plainTextBody == null)
            {
                pj.Description__c = email.htmlBody.left(32000);
            }
            else
            {
                pj.Description__c = email.plainTextBody.left(32000);
            }
            
            insert pj;
            
            handleAttachments(pj,email);
        }
        catch(Exception ex)
        {
            inContactBaseClass.SendErrorEmail(ex,email.fromAddress);
        } 
		
			

        return result;
    }
    
    
    // Save attachments, if any
	private void handleAttachments(Project__c theProject, Messaging.InboundEmail email) 
	{
		if(email.textAttachments!=null && email.textAttachments.size() >0) 
		{
	  		for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) 
	  		{
			    Attachment attachment = new Attachment();  
			    attachment.Name = tAttachment.fileName;
			    attachment.Body = Blob.valueOf(tAttachment.body);
			    attachment.ParentId = theProject.Id;
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
			    attachment.ParentId = theProject.Id;
			    insert attachment;
	  		}
	 	}
	 }  

}