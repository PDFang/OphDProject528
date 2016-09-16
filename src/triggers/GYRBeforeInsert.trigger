trigger GYRBeforeInsert on GYR__c (before insert) 
{
	Set<Id> accounts = new Set<Id>();
	List<GYR__c> gyr = trigger.new;
	
	//get all the account IDs
	for(GYR__c g:gyr)
	{
		accounts.add(g.Account__c);
	}
	
	//get account and old GYR info
	List<Account> accts = new List<Account>([SELECT Id,Referenceable__c, ParentID,  Customer_Priority__c FROM Account WHERE Id IN:accounts OR ParentID IN:accounts]);
	GYR__c[] oldGYR = [SELECT Id, GYRStatus__c, GYREndDate__c, Account__c FROM GYR__c WHERE Account__c IN:accounts AND GYREndDate__c = NULL];

	//make sure there are old GYR records
	if(oldGYR.size()>0)
	{
		for(GYR__c g:oldGYR)
		{
			//close the old GYR record
			g.GYREndDate__c = system.today();
		}
		
		update(oldGYR);
		
	}
	
	//loop through
	for(GYR__c g:gyr)
	{
		
		for(Account a:accts)
		{
			//add service package
			g.ServicePackage__c = a.Customer_Priority__c;
			
			//dispay status on the account
			a.GYRStatus__c = g.GYRStatus__c;
			//a.Referenceable__c = false;
			if(g.GYRStatus__c == 'Black')
            {
                a.DisconnectReason__c = g.ReasonCategory__c;
                a.DisconnectNotes__c = g.ReasonSummary__c;
            }
		}
		
		update accts;
	}
	
}