global class ContactFieldCleaner implements Database.Batchable<sObject>
{ 
	global final String query;
	global string sandboxName;

	global class ContactFieldCleanerException extends Exception{}

	global ContactFieldCleaner(string query, string sandboxName)
	{
        //prevent this process from running against Production
		string orgId = UserInfo.getOrganizationId();

        //don't run for the production OrgId unless running unit tests.
        if(orgId == '00D700000008HFcEAM' && !Test.isRunningTest())
		{
			throw new ContactFieldCleanerException('Not suppose to run this job in Production.');
		}
		this.query = query;
		this.sandboxName = sandboxName;

	}

	global Database.QueryLocator start(Database.BatchableContext context)
	{
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext context, List<Contact> scope)
	{
        //turn off the contact trigger that comes with ReferenceEdge
		refedge__POR_App_Configuration__c referenceEdgeSetting = refedge__POR_App_Configuration__c.getOrgDefaults();

		referenceEdgeSetting.refedge__ContactTrigger__c = false;

		update referenceEdgeSetting;
        
        //update the contact records
		for(Contact contact : scope)
		{
			contact.Email = contact.Email == null ? null : String.format('{0}.{1}', new List<string> { contact.Email, sandboxName });
			contact.ADFSGuid__c = null;
		}

		TriggerHandler.bypass('ContactTriggerHandler');
		Database.SaveResult[] updateResults = Database.update(scope, false);
		TriggerHandler.clearBypass('ContactTriggerHandler');

		String[] errorIds = new List<String>();

		for(Integer i = 0; i < updateResults.size(); i++)
		{
			if(!updateResults.get(i).isSuccess())
			{
				String errorMessage = String.format('{0} - {1}', new List<String> { scope.get(i).Id, updateResults.get(i).getErrors().get(0).getMessage() });
				errorIds.Add(errorMessage);
				system.debug(errorMessage);
			}
		}

		if(errorIds.size() > 0)
		{
			sendErrorEmail(errorIds);
		}
	}

	global void finish(Database.BatchableContext context)
	{
		AsyncApexJob a = [SELECT Id, NumberOfErrors, JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :context.getJobId()];
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] { a.CreatedBy.Email };
		message.setToAddresses(toAddresses);
		message.setSubject('ContactFieldCleaner has completed');

		string messageBody = 'The ContactFieldCleaner process has completed.';
        messageBody = messageBody + ' The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.';
		message.setPlainTextBody(messageBody);

		try{
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
		}catch(system.EmailException ex){
			system.debug(ex);
		}
	}

	@TestVisible
	private void sendErrorEmail(List<String> errorIds)
	{
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] { userInfo.getUserEmail() };
		message.setToAddresses(toAddresses);
		message.setSubject('ContactFieldCleaner Errored on these Contact records');

		string messageBody = 'The following Contacts were not updated:\n';

		for(String id : errorIds)
		{
			messageBody += String.Format('{0}\n', new List<string> { id });
		}

		message.setPlainTextBody(messageBody);

		try{
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
		}catch(system.EmailException ex){
			system.debug(ex);
		}
	}
}