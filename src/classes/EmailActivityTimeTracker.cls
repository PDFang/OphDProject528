/**
 * Email services are automated processes that use Apex classes
 * to process the contents, headers, and attachments of inbound
 * email.
 */
global class EmailActivityTimeTracker implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

		Integer actTime;
		String emailBody;
		String comment;
				
		//end if subject does not match an account number
		if([SELECT Count() FROM Account WHERE CostGuard_Acct__c = :email.subject]==0)
		{
			result.success = false;
			result.message = 'Your time tracking request failed. Account not found. Please resubmit your time tracking request with the account number as the subject.';
			return result;
		}
		
		//get account
		ID account = [SELECT Id FROM Account WHERE CostGuard_Acct__c = :email.subject].Id;
		//find user record from emailer
		system.debug(email.fromAddress);
		User u = [SELECT Id FROM User WHERE UserType = 'Standard' AND Email = :email.fromAddress LIMIT 1];
		//get the email body
		emailBody = email.plainTextBody;
		//parse out integer in the first line
		try
		{
			actTime = integer.valueOf(emailBody.substring(0,emailBody.indexOf('\n')).trim());
		} 
		catch (Exception e) 
		{
 			result.success = false;
			result.message = 'Your time tracking request failed. The first line of your time tracker emails can only include the number of minutes worked.';
			return result;
		}
		//save the rest of the email for the comment
		comment = emailBody.substring(emailBody.indexOf('\n'),emailBody.length());
		
		//create new time tracker task on the account
		Task t = new Task();
		t.WhatId = account;
		//t.CreatedById = u.Id;
		t.OwnerId = u.Id;
		//t.LastModifiedById = u.Id;
		t.Type = 'Time Tracking';
		t.WorkDuration__c = actTime;
		t.ActivityDate = system.today();
		t.Status = 'Completed';
		t.Subject = 'GSD Selling';
		t.Description = comment;
		
		insert t;
		
		
		
        return result;
    }
    
    static testMethod void TestActivityTracker() {
	
		// Create a new email and envelope object.
	 	Messaging.InboundEmail email = new Messaging.InboundEmail();
	 	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
	
		// Create a new test account and insert it in the test method.        
	   	Account a = new Account(Name='Test',CostGuard_Acct__c='000000');
	    insert a;
		
		//get a user
		User u = [SELECT Id, Email FROM User WHERE IsActive = true AND UserType = 'Standard' Limit 1];
		   
	   	// Test
		email.subject = a.CostGuard_Acct__c;
		email.plainTextBody = '5\n TEST Comment';
		system.debug(u.Email + '****************************************************');
		env.fromAddress = u.Email;
		email.fromAddress = u.Email;
	
	   // Call the class and test it with the data in the test method.
	   EmailActivityTimeTracker at = new EmailActivityTimeTracker();
	   at.handleInboundEmail(email, env);		
	   }    
}