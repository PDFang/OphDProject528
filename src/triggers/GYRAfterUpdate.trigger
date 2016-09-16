trigger GYRAfterUpdate on GYR__c (after update) 
{
	
	Set<Id> gyrIds = new Set<Id>();
	Set<Id> accts = new Set<Id>();
	List<Account> actsToUpdate = new List<Account>();
	
	
	for(integer i=0; i < trigger.new.size(); i++)
	{
		GYR__c newGYR = trigger.new[i];
		GYR__c oldGYR = trigger.old[i];
		
		//only get GYRs that ended
		if(oldGYR.GYREndDate__c != newGYR.GYREndDate__c && newGYR.GYREndDate__c != null)
		{
			gyrIds.add(newGYR.Id);
			accts.add(newGYR.Account__c);
		}
		
	}
	
	
	
	if(gyrIds.size() > 0)
	{
		//get all the accounts for the GYRs closed
		Map<Id,Account> allAccts = new Map<Id,Account>([SELECT Id, Referenceable__c, GYRStatus__c, CG_Disconnect_Date__c, DisconnectReason__c, DisconnectNotes__c FROM Account WHERE Id IN : accts]);
		//find if accounts have another open GYR
		MAP<Id,GYR__c> gyrs = new Map<Id,GYR__c>([SELECT Id, GYRStatus__c, GYREndDate__c, Account__c FROM GYR__c WHERE Id NOT IN :gyrIds AND Account__c IN :accts AND GYREndDate__c = null]);
		
		//loop through additional gyrs that are open
		for(GYR__c g:gyrs.values())
		{
			if(allAccts.containsKey(g.Account__c))
			{
				Account a = allAccts.get(g.Account__c);
				a.GYRStatus__c = g.GYRStatus__c;
				//a.Referenceable__c = false;
				//
				if(g.GYRStatus__c == 'Black')
                {
                    a.DisconnectReason__c = g.ReasonCategory__c;
                    a.DisconnectNotes__c = g.ReasonSummary__c;
                }
				
				//add to update list
				actsToUpdate.add(a);
				//remove from account map
				allAccts.remove(g.Account__c);
			}
		}
		
		//all other accounts without open GYRs make green
		for(Account a:allAccts.values())
		{
            if(a.CG_Disconnect_Date__c == null)
            {
				a.GYRStatus__c = 'Green';
            }
            else
            {
                a.GYRStatus__c = 'Black';
            }
			actsToUpdate.add(a);
		}
		
		//update accounts
		update actsToUpdate;
	}



}