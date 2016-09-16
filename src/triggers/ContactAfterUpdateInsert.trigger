trigger ContactAfterUpdateInsert on Contact (after insert, after update) 
{
	//set of accounts to mark as referenceable
	Set<Id> acctAddRef = new Set<Id>();
	
	if(trigger.isInsert)
	{
		//loop through contacts
		for(Contact c:trigger.new)
		{
			//get referenceable contacts
			if(c.Referenceable__c)
			{
				if(!acctAddRef.contains(c.AccountId))
				{
					acctAddRef.add(c.AccountId);
				}
			}
		}
	}
	else
	{
		//loop through triggers
		for(integer i=0; i < trigger.new.size(); i++)
		{
			//get new and old contact record
			Contact cn = trigger.new[i];
			Contact co = trigger.old[i];
			
			//get newly referenceable contacts
			if(!co.Referenceable__c && cn.Referenceable__c)
			{
				if(!acctAddRef.contains(cn.AccountId))
				{
					acctAddRef.add(cn.AccountId);
				}
			}
		}
	}
	
	//only process if there accounts that need to be marked as referenceable
	if(!acctAddRef.isEmpty())
	{
		//get accounts that need referenced
		Account[] accts = [SELECT Id, Referenceable__c FROM Account WHERE Id IN :acctAddRef AND ReferenceStor__Import_into_ReferenceStor__c = false];
		
		//make sure accounts are returned
		if(accts.size()>0)
		{
			//loop through accounts and mark them as referenceable
			for(Account a:accts)
			{
				a.Referenceable__c = true;
			}
			
			//update accounts
			update accts;
		}
	}
}