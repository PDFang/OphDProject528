public class AccountPartnerClass 
{

	public static void UpdateCustomerAccountMasterAgent(Map<Id,Account> custAccts)
	{
		//list for parameter map
		List<Account> listFromMap = new List<Account>();
		Set<Id> partIds = new Set<Id>();
			
		listFromMap = custAccts.Values();
		
		//get all Sales Partner accounts
		for(Account a:listFromMap)
		{
			if(!partIds.contains(a.SalesPartner__c))
			{
				partIds.add(a.SalesPartner__c);
			}
		}
		
		//Map of Sales Partner info from the set of accounts
		Map<Id,Account> partnerAccts = new Map<Id,Account>([SELECT Id, ParentId, RecordType.Name FROM Account WHERE Id IN:partIds]);
		
		//loop through accounts
		for(Account a:listFromMap)
		{
			Account agentInfo = new Account();
			agentInfo = partnerAccts.get(a.SalesPartner__c);
			
			//if sales partner is a master agent then that is the value 
			//otherwise it is the parent of the sales partner
			if(agentInfo.RecordType.Name == 'Master Agents')
			{
				a.SalesPartnerMasterAgent__c = a.SalesPartner__c;
			}
			else
			{
				a.SalesPartnerMasterAgent__c = agentInfo.ParentId;
			}
		}
	}
	
	public static void UpdateSubAgentChildAccounts(Map<Id,Account> subAgentAccts)
	{
		
		//Map of Sales Partner info from the set of accounts
		List<Account> accts = new List<Account>([SELECT SalesPartner__c, SalesPartnerMasterAgent__c FROM Account WHERE SalesPartner__c IN:subAgentAccts.KeySet()]);
		
		
		for(Account a:accts)
		{
			Account mapAcct = new Account();
			mapAcct = subAgentAccts.get(a.SalesPartner__c);
			
			//updated the master agent of the Customer account 
			//to the parent ID of the sub agent account
			a.SalesPartnerMasterAgent__c = mapAcct.ParentId;
		}		
		
		update accts;
	}

}