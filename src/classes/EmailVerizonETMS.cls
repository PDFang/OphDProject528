global class EmailVerizonETMS implements Messaging.InboundEmailHandler 
{

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		
        string accountNumber;
        string vzTicketNumber;
        Account acct;
        //set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        Case vzCase = new Case();
		
        try
        {
            Pattern subjectPattern = Pattern.compile('\\(?(\\d+)\\)\\s');
            Matcher subjectMatcher = subjectPattern.matcher(email.subject);
            
            if(subjectMatcher.lookingAt())
            {
                vzTicketNumber = subjectMatcher.group(1);
            }
            else
            {
                inContactBaseClass.SendErrorEmail('Verizon ETMS Subject line is in the wrong format.<br/>Subject: ' + email.subject + '<br/><br/>Body: ' + email.plainTextBody, 'Verizon ETMS Email Service'); 
        		result.success = false;
                result.message = 'Verizon ETMS Subject line is in the wrong format';
		        return result;
            }
            
            Pattern bodyPattern = Pattern.compile('^.+Vendor\\sService\\sID\\s(\\d+)\\s');
            Matcher bodyMatcher = bodyPattern.matcher(email.plainTextBody);
            
            if(bodyMatcher.lookingAt())
            {
                accountNumber = bodyMatcher.group(1);
            }
            else
            {
                inContactBaseClass.SendErrorEmail('Verizon ETMS Email Body is in the wrong format.<br/>Subject: ' + email.subject + '<br/><br/>Body: ' + email.plainTextBody, 'Verizon ETMS Email Service');
                result.success = false;
                result.message = 'Verizon ETMS Email Body is in the wrong format';
		        return result;
            }
            
            try
            {
            	acct = [SELECT Id, Name, (SELECT Id FROM Contacts WHERE Email LIKE 'Federal.Service.Desk@verizon.com%' LIMIT 1) FROM Account WHERE CadebillAccountNo__c =:double.valueOf(accountNumber)];
            }
            catch(Exception ex2)
            {
                inContactBaseClass.SendErrorEmail('Verizon ETMS Email Account Not Found. Account Number: ' + accountNumber + ' <br/>Subject: ' + email.subject + '<br/><br/>Body: ' + email.plainTextBody, 'Verizon ETMS Email Service');
            	result.success = false;
                result.message = 'Verizon ETMS Email Account Not Found';
		        return result;
            }
            
            vzCase.AccountId = acct.Id;
            
            if(!acct.Contacts.isEmpty())
            {
            	vzCase.ContactId = acct.Contacts[0].Id;
            }
            else
            {
                //create contact if doesn't exist on account
                Contact con = new Contact();
                con.AccountId = acct.Id;
                con.LastName = 'Networx Help Desk';
                if(inContactConfiguration.Instance == 'Production')
                {
                	con.Email = 'Federal.Service.Desk@verizon.com';
                }
                else
                {
                    con.Email = 'Federal.Service.Desk@verizon.com.test';
                }
                con.Contact_Role__c = 'Authorized Caller; General Contact; Main';
                con.Phone = '8886247821';
                con.Department = 'VCC customer help desk';
                con.RecordTypeId = '01270000000Lrn4';
                insert con;
                vzCase.ContactId = con.Id;
            }
            vzCase.Request_Type__c = 'Application Behavior';
            vzCase.Product_or_Service__c = 'Virtual Contact Center';
            vzCase.Impact__c = 'Medium';
            vzCase.Urgency__c = 'Medium';
            vzCase.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Incident', 'Case');
            vzCase.Description = email.plainTextBody; //ask
            vzCase.Subject = 'VZN Federal Account Case (' + vzTicketNumber + ')';
            vzCase.X3rdPartyVendorTicket__c = vzTicketNumber;
            vzCase.Origin = 'Verizon ETMS';
            vzCase.setOptions(dmo);
            
            insert vzCase;
            
            EmailMessage[] newEmail = new EmailMessage[]{};
		
            newEmail.add
                (
                    new EmailMessage
                    (
                        FromAddress = email.fromAddress,
                        FromName = email.fromName,
                        ToAddress = email.toAddresses[0],
                        Subject = inContactBaseClass.LimitStringLength(email.Subject, EmailMessage.Subject.getDescribe().getLength()),
                        TextBody = inContactBaseClass.LimitStringLength(email.plainTextBody,EmailMessage.TextBody.getDescribe().getLength()),
                        HtmlBody = inContactBaseClass.LimitStringLength(email.htmlBody,EmailMessage.HtmlBody.getDescribe().getLength()),
                        MessageDate = datetime.now(),
                        ParentId = vzCase.Id
                    )
                );  
 
			insert newEmail;
            result.success = true;
        }
        catch(Exception ex)
        {
            inContactBaseClass.SendErrorEmail(ex, 'Verizon ETMS Email Service');
            result.success = false;
            result.message = ex.getMessage();
        }
        
        
        return result;
    }
}