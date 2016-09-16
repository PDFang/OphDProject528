global class CommonLibraryWebServices 
{
	global class AccountIdMap
	{
		webservice Integer AccountNo;
		webservice String AccountId;
		
		global AccountIdMap(integer acctNumber, string acctId)
		{
			AccountNo = acctNumber;
			AccountId = acctId;
		}
	}
    
    global class CompanyIdMap
    {
        webservice String CompanyId;
        webservice String AccountId;
        
        global CompanyIdMap(string compId, string acctId)
        {
            CompanyId = compId;
            AccountId = acctId;
        }
    }
    
    global class AgentIdMap
    {
        webservice String AgentId;
        webservice String AccountId;
        
        global AgentIdMap(string agtId, string acctId)
        {
            AgentId = agtId;
            AccountId = acctId;
        }
    }
	
	global class TelcoSaasMap
	{
		webservice integer TelcoAccountNo;
		webservice integer SaasAccountNo;
		
		global TelcoSaasMap(integer telco, integer saas)
		{
			TelcoAccountNo = telco;
			SaasAccountNo = saas;
		}		
	}
	
	WebService static String SelectRecordTypeIDByName(string recType, string objName)
	{
		String recTypeId = [SELECT ID FROM RecordType WHERE sObjectType = :objName AND Name = :recType LIMIT 1].id;
		return recTypeId;
	}
	
	webservice static AccountIdMap[] GetAccountIdsFromAccountNo(Integer[] accountNos)
	{
        Account[] accounts = new Account[]{};
		AccountIdMap[] accountMap = new List<AccountIdMap>();
        
        if(accountNos.size() > 1000)
        {
            for(Integer i=0;i<=(accountNos.size()/1000.00);i++)
            {
                Set<Integer> accountBlock = Parse1000IntegersByIteration(accountNos,i);
                accounts.addAll([SELECT CadebillAccountNo__c, Id FROM Account WHERE CadebillAccountNo__c IN :accountBlock]);
            }
        }
        else
        {
			accounts = [SELECT CadebillAccountNo__c, Id FROM Account WHERE CadebillAccountNo__c IN :accountNos];
        }
        
        
		if(!accounts.isEmpty())
		{
			for(Account a:accounts)
			{
				AccountIdMap acctMap = new AccountIdMap(integer.valueOf(a.CadebillAccountNo__c), a.Id);
				accountMap.add(acctMap);
				//system.debug(acctMap);
			}
		}
		//system.debug(accountMap);
		return accountMap;
		
	}
	
	webservice static CompanyIdMap[] GetAccountIdsFromCompanyId(String[] companyIds)
	{
        if(companyIds != null)
        {
            Account[] accounts = [SELECT CompanyId__c, Id FROM Account WHERE CompanyId__c IN :companyIds AND CompanyId__c <> NULL];
            CompanyIdMap[] companyMap = new List<CompanyIdMap>();
            
            if(!accounts.isEmpty())
            {
                for(Account a:accounts)
                {
                    CompanyIdMap compMap = new CompanyIdMap(a.CompanyId__c, a.Id);
                    companyMap.add(compMap);
                    //system.debug(compMap);
                }
            }
            //system.debug(companyMap);
            return companyMap;
        }
		
        return null;		
	}
    
	
	webservice static AgentIdMap[] GetAccountIdsFromAgentId(String[] agentIds)
	{
		Account[] accounts = [SELECT SalesEntityID__c, Id FROM Account WHERE SalesEntityID__c IN :agentIds];
		AgentIdMap[] agentMap = new List<AgentIdMap>();
		
		if(!accounts.isEmpty())
		{
			for(Account a:accounts)
			{
				AgentIdMap agtMap = new AgentIdMap(a.SalesEntityId__c, a.Id);
				agentMap.add(agtMap);
			}
		}
        
		return agentMap;
		
	}
	
	//Will update inConnect customers with the correct record type and update the Saas Partner
	Webservice static void AddSaasPartnerAccount(TelcoSaasMap[] telcoSaasAccountMap)
	{
		Map<integer,integer> telcoMap = new Map<integer,integer>();
		Map<decimal,Account> telcoAcctMap = new Map<decimal, Account>();
		Map<decimal,Account> saasAcctMap = new Map<decimal, Account>();
		
		for(TelcoSaasMap accountMap:telcoSaasAccountMap)
		{
			telcoMap.put(accountMap.TelcoAccountNo, accountMap.SaasAccountNo);
		}
		
		
		LIST<Account> teleAccts = [SELECT ID, RecordTypeId, SaasPartnerAccount__c, CadebillAccountNo__c FROM Account WHERE CadebillAccountNo__c IN:telcoMap.keySet()];
		LIST<Account> saasAccts = [SELECT ID, RecordTypeId, LinkedLDAccount__c, CadebillAccountNo__c FROM Account WHERE CadebillAccountNo__c IN:telcoMap.values()];
		
		//Create maps
		for(Account a:teleAccts)
		{
			telcoAcctMap.put(a.CadebillAccountNo__c, a);
		}
		for(Account a:saasAccts)
		{
			saasAcctMap.put(a.CadebillAccountNo__c, a);
		}
		
		
		String recTypeId = SelectRecordTypeIDByName('inConnect Customers', 'Account');
		string resellRecTypeId = SelectRecordTypeIDByName('Resell Customers','Account');
		
		for(Account t:telcoAcctMap.values())
		{
			string saasId;
			//if saas account is not there it will create it.  sync will fill out info
			if(!saasAcctMap.containsKey(telcoMap.get(integer.valueOf(t.CadebillAccountNo__c))))
			{
				Account a = new Account();
				a.Name = 'New Saas Account';
				a.CadebillAccountNo__c = telcoMap.get(integer.valueOf(t.CadebillAccountNo__c));
				a.RecordTypeId = resellRecTypeId;
				a.LinkedLDAccount__c = t.Id;
				
				saasAccts.add(a);
				
				saasId = a.Id;
			}
			else
			{
				Account a = saasAcctMap.get(telcoMap.get(integer.valueOf(t.CadebillAccountNo__c)));
				a.LinkedLDAccount__c = t.Id;
				saasId = a.Id;
			}
			
			
			t.SaasPartnerAccount__c = saasId;
			t.RecordTypeId = recTypeId;
		}
		
		upsert saasAccts;
		update teleAccts;
	}
    
    Webservice static void DeleteAccountInvoices(string[] accountIds)
    {
        Invoice__c[] invoices = [SELECT Id FROM Invoice__c WHERE SFDC_Acct_ID__c IN :accountIds AND (Invoice_Group__c = NULL OR isExpired__c = 1) LIMIT 10000];
        
        if(!invoices.isEmpty())
        {
            delete invoices;
        }
    }
    
    webservice static void UpdateContactsByAdfsGuid(string adfsGuid,
            string firstName, string lastName, string email, string phoneNumber,
            string addressStreet, string addressCity, string addressState, string addressPostalCode, string addressCountry)
    {
        if(adfsGuid != null && adfsGuid != '')
        {
        	Contact[] contacts = [SELECT Id, FirstName, LastName, Email, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry FROM Contact WHERE Deactivated__c = false AND ADFSGuid__c = :adfsGuid];
        
            if(!contacts.isEmpty())
            {                
                for(Contact c:contacts)
                {
                    c.FirstName = firstName;
                    c.LastName = lastName;
                    c.Email = email;
                    c.Phone = phoneNumber;
                    c.MailingStreet = addressStreet;
                    c.MailingCity = addressCity;
                    c.MailingPostalCode = addressPostalCode;
                    c.MailingState = addressState;
                    c.MailingCountry = addressCountry;
                }
                
                update contacts;
            }
        }
    }
    
    private static Set<Integer> Parse1000IntegersByIteration(Integer[] integers, Integer iteration)
    {
        Set<Integer> parsedIntegers = new Set<Integer>();
        Integer iterationEnd = (iteration*1000)+1000;
        if(iterationEnd > integers.size())
        {
            iterationEnd = integers.size();
        }
        
        for(Integer i=(iteration*1000);i<iterationEnd;i++)
        {
            parsedIntegers.add(integers[i]);
        }
        
        return parsedIntegers;
    }
}