global class ContactFieldCleaner implements Database.Batchable<sObject>
{ 
	global final String query;
	global string sandboxId;

	global ContactFieldCleaner(string query, string sandboxId)
	{
        //prevent this process from running against Production
		string orgId = UserInfo.getOrganizationId();

        //don't run for the production OrgId unless running unit tests.
        if(orgId != '00D700000008HFcEAM' || Test.isRunningTest())
		{
			this.query = query;
			this.sandboxId = sandboxId;
		}
		else
		{
			this.query = '';
		}
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
			contact.Email = contact.Email == null ? null : String.format('{0}.{1}', new List<string> { contact.Email, sandboxId });
			contact.ADFSGuid__c = null;
		}

		Database.SaveResult[] updateResults = Database.update(scope, false);

		String[] errorIds = new List<String>();

		for(Integer i = 0; i < updateResults.size(); i++)
		{
			if(!updateResults.get(i).isSuccess())
			{
				String errorMessage = String.format('{0} - {1}', new List<String> { scope.get(i).Id, updateResults.get(i).getErrors().get(0).getMessage() });
				errorIds.Add(errorMessage);
			}
		}

		if(errorIds.size() > 0)
		{
			sendErrorEmail(errorIds);
		}
	}

	global void finish(Database.BatchableContext context)
	{
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] { 'arnab.karsarkar@incontact.com', 'mike.burkhard@incontact.com' };
		message.setToAddresses(toAddresses);
		message.setSubject('ContactFieldCleaner has completed');

		string messageBody = 'The ContactFieldCleaner process has completed';
		message.setPlainTextBody(messageBody);

		if(!Test.isRunningTest())
		{
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
		}
	}

	private void sendErrorEmail(List<String> errorIds)
	{
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] { 'arnab.karsarkar@incontact.com', 'mike.burkhard@incontact.com' };
		message.setToAddresses(toAddresses);
		message.setSubject('ContactFieldCleaner Errored on these Contact records');

		string messageBody = 'The following Contacts were not updated:\n';

		for(String id : errorIds)
		{
			messageBody += String.Format('{0}\n', new List<string> { id });
		}		

		message.setPlainTextBody(messageBody);

		if(!Test.isRunningTest())
		{							
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
		}
	}
}