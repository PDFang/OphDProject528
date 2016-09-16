@isTest
private class EmailServiceTestClass 
{
    private static void createSiteConfig()
    {
        SiteConfiguration__c sbx = new SiteConfiguration__c();
        sbx.OrgId__c = inContactBaseClass.OrgId15Digit;
        sbx.Name = inContactBaseClass.OrgId15Digit;
        sbx.DeveloperErrorEmail__c = 'salesforceadmins@incontact.com';
        sbx.DeveloperErrorFromName__c = 'SBX Salesforce';
        insert sbx;
        
    }
    
     static testMethod void TestEmailCarrierMaintenance() 
     {
        
        //create test account
        Account a = inContactBaseClass.CreateAccount('testName');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
        a.CadebillAccountNo__c = 100001;
                
        insert a;
        System.debug('Insert accounts.');
        
        
        Id rtCustOther = '01270000000Lrn4AAC';
                
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
                            
        insert ct;
         
         //NOC contact
        Contact ct2 = inContactBaseClass.CreateContact(a.Id, '', 'NOC', 'noc@test.com', rtCustOther);
                            
        insert ct2;

           // Create a new email, envelope object and Attachment
           Messaging.InboundEmail email = new Messaging.InboundEmail();
           Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
           Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
        
           email.fromAddress = 'email@test.com';
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
           EmailCarrierMaintenance emailServiceObj = new EmailCarrierMaintenance();
           emailServiceObj.handleInboundEmail(email, env );                      
    }    
    
     static testMethod void TestEmailSustainingEngineering() 
     {
        
        //create test account
        Account a = inContactBaseClass.CreateAccount('testName');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
        a.CadebillAccountNo__c = 100001;
                
        insert a;
        System.debug('Insert accounts.');
        
        

           // Create a new email, envelope object and Attachment
           Messaging.InboundEmail email = new Messaging.InboundEmail();
           Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
           Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
        
           email.fromAddress = 'email@test.com';
           email.subject = 'test';
           email.plainTextBody = 'test';
           email.htmlBody = 'test';
           email.ToAddresses = new String[]{'salesforceadmins@incontact.com'};
           env.fromAddress = 'salesforceadmins@incontact.com';
        
           // set the body of the attachment
           inAtt.body = blob.valueOf('test');
           inAtt.fileName = 'my attachment name';
           inAtt.mimeTypeSubType = 'plain/txt';
        
           email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt }; 
        
           // call the class and test it with the data in the testMethod
           EmailSustainingEngineering emailServiceObj = new EmailSustainingEngineering();
           emailServiceObj.handleInboundEmail(email, env );  
         
           Case c = [SELECT Id, Product_or_Service__c, Origin, Subject FROM Case WHERE AccountId = :a.Id LIMIT 1];
         system.assertEquals('Billing Report Executable', c.Product_or_Service__c);
         system.assertEquals('Alert', c.Origin);
         system.assertEquals('test', c.Subject);
    }    
    
    
     static testMethod void TestEmailNOC() 
     {
        
        //create test account
        Account a = inContactBaseClass.CreateAccount('testName');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
                
        insert a;
        System.debug('Insert accounts.');
        
        
        Id rtCustOther = '01270000000Lrn4AAC';
                
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
                            
        insert ct;

           // Create a new email, envelope object and Attachment
           Messaging.InboundEmail email = new Messaging.InboundEmail();
           Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
           Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
        
           email.fromAddress = 'email@test.com';
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
           EmailNocTicket emailServiceObj = new EmailNocTicket();
           emailServiceObj.handleInboundEmail(email, env );                      
    }    
    
    
     static testMethod void TestEmailServicePSARequests() 
     {
        
        //create test account
        Account a = inContactBaseClass.CreateAccount('testName');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
        a.CadebillAccountNo__c = 100001;
                
        insert a;
        System.debug('Insert accounts.');
        
        
        Id rtCustOther = '01270000000Lrn4AAC';
                
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
                            
        insert ct;

           // Create a new email, envelope object and Attachment
           Messaging.InboundEmail email = new Messaging.InboundEmail();
           Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
           Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
        
           email.fromAddress = 'email@test.com';
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
           EmailServicePSARequests emailServiceObj = new EmailServicePSARequests();
           emailServiceObj.handleInboundEmail(email, env );      
           
           email.fromAddress = 'solarwinds@ucn.net' ;  
           emailServiceObj.handleInboundEmail(email, env );             
    }
    
    static testMethod void TestEmailDbaProject() 
     {
        
           // Create a new email, envelope object and Attachment
           Messaging.InboundEmail email = new Messaging.InboundEmail();
           Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
           Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
        
           email.fromAddress = 'email@test.com';
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
           EmailDbaProject emailServiceObj = new EmailDbaProject();
           emailServiceObj.handleInboundEmail(email, env );                      
    }    
    
    static testMethod void TestEmailVerizonETMS() 
     {
         createSiteConfig();
         
         Account a = new Account();
         a.Name = 'Test Account';
         a.CadebillAccountNo__c = 4593229;
         insert a;

         // Create a new email, envelope object and Attachment
         Messaging.InboundEmail email = new Messaging.InboundEmail();
         Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
         
         email.fromAddress = 'email@test.com';
         email.subject = '(20141111079856) test email';
         email.plainTextBody = 'The above Verizon Business trouble ticket for Verizon Service ID GPS_0061928 Vendor Service ID 4593229 has been referred to you for resolution. Contract Type: Networx Universal\r\nPriority: 4\r\nTrouble Code: CHANGE REQ\r\n\r\nProblem Summary: This is a test email to see if everything is working properly.';
         email.htmlBody = 'test';
         email.ToAddresses = new String[]{'jeremy.sparrell@incontact.com'};
         env.fromAddress = 'jeremy.sparrell@incontact.com';
         
         EmailVerizonETMS emailVerizon = new EmailVerizonETMS();
         Messaging.InboundEmailResult successResult = emailVerizon.handleInboundEmail(email, env);
         system.assert(successResult.success);
         
         email.plainTextBody = 'The above Verizon Business trouble ticket for Verizon Service ID GPS_0061928 Vendor Service ID 4444444 has been referred to you for resolution. Contract Type: Networx Universal\r\nPriority: 4\r\nTrouble Code: CHANGE REQ\r\n\r\nProblem Summary: This is a test email to see if everything is working properly.';
         successResult = emailVerizon.handleInboundEmail(email, env);
         system.assert(!successResult.success);
         system.assertEquals('Verizon ETMS Email Account Not Found', successResult.message);
         
         email.plainTextBody = 'Bad Body Text';
         successResult = emailVerizon.handleInboundEmail(email, env);
         system.assert(!successResult.success);
         system.assertEquals('Verizon ETMS Email Body is in the wrong format', successResult.message);
         
         email.subject = 'Bad Subject Text';
         successResult = emailVerizon.handleInboundEmail(email, env);
         system.assert(!successResult.success);
         system.assertEquals('Verizon ETMS Subject line is in the wrong format', successResult.message);
                  
     }
    
    static testMethod void TestEmailServiceNetEngRequests () 
     {
        //create test account
        Account a = inContactBaseClass.CreateAccount('inContact, Inc.');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
        a.CadebillAccountNo__c = 100001;
                
        insert a;
        System.debug('Insert accounts.');
        
        Id rtCustOther = '01270000000Lrn4AAC';
                
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
                            
        insert ct;

		Test.startTest();     
        // Test 1 - Create a new email, envelope object and Attachment: Sender is a valid account contact
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail.BinaryAttachment inAtt = new Messaging.InboundEmail.BinaryAttachment();
         
        email.fromAddress = 'email@test.com';
        email.subject = 'test email from valid account contact';
        email.plainTextBody = 'This email will test the inbound email to contact look-up and association to the newly created case';
        email.htmlBody = 'This email will test the inbound email to contact look-up and association to the newly created case';
        email.ToAddresses = new String[]{'salesforceadmins@incontact.com'};
        env.fromAddress = 'salesforceadmins@incontact.com';
         
        // set the body of the attachment
        inAtt.body = blob.valueOf('test');
        inAtt.fileName = 'my attachment name';
        inAtt.mimeTypeSubType = 'plain/txt';
         
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt };
        
        //call the class and test
        EmailToCaseNetEngClass emailNetEng = new EmailToCaseNetEngClass ();
        Messaging.InboundEmailResult successResult = emailNetEng.handleInboundEmail(email, env);
        system.assert(successResult.success);
      
        //Test 2- Create a new email, envelope object and Attachment: Sender is not a valid account contact
        Messaging.InboundEmail email2 = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();
        Messaging.InboundEmail.BinaryAttachment inAtt2 = new Messaging.InboundEmail.BinaryAttachment();
         
        email.fromAddress = 'email2@test.com';
        email.subject = 'test email from invalid account contact';
        email.plainTextBody = 'This email will test the inbound email to contact look-up and association to the newly created case. The new case created should not have the contact field populated.';
        email.htmlBody = 'This email will test the inbound email to contact look-up and association to the newly created case. The new case created should not have the contact field populated.';
        email.ToAddresses = new String[]{'salesforceadmins@incontact.com'};
        env.fromAddress = 'salesforceadmins@incontact.com';
        
        //Set the body of the attachment
        inAtt2.body = blob.valueOf('test');
        inAtt2.fileName = 'my attachment name';
        inAtt2.mimeTypeSubType = 'plain/txt';
        
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {inAtt2 };   
        
        //call the class and test
        EmailToCaseNetEngClass emailNetEng2 = new EmailToCaseNetEngClass ();
        Messaging.InboundEmailResult successResult1 = emailNetEng2.handleInboundEmail(email, env);
        system.assert(successResult1.success); 
                    
        Test.stopTest();                          
    }
}