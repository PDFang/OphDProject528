global class CastIronWebServices 
{
	WebService static String SelectRecordTypeIDByName(string recType, string objName)
	{
		String recTypeId = [SELECT ID FROM RecordType WHERE sObjectType = :objName AND Name = :recType LIMIT 1].id;
		return recTypeId;
	}
	
	Webservice static String SelectAccountIdByCostguardAcctNumber(string CostguardAcctNumber)
	{
		String acctId;
		
		//if no account number then return null
		try
		{
			acctId = [SELECT ID FROM Account WHERE CostGuard_Acct__c = :CostguardAcctNumber LIMIT 1].Id;
		}
		catch(Exception ex)
		{
			acctId = null;
		}
		
		return acctId;
	}
	
	//Will update inConnect customers with the correct record type and update the Saas Partner
	Webservice static void AddSaasPartnerAccount(string SaasCostGuardAcctNumber, string TeleCostGuardAcctNumber)
	{
		Account teleAcct = [SELECT ID, RecordTypeId, SaasPartnerAccount__c FROM Account WHERE CostGuard_Acct__c = :TeleCostGuardAcctNumber];
		String saasId = SelectAccountIdByCostguardAcctNumber(SaasCostGuardAcctNumber);
		String recTypeId = SelectRecordTypeIDByName('inConnect Customers', 'Account');
		
		
		//if saas account is not there it will create it.  sync will fill out info
		if(saasId == null)
		{
			Account a = new Account();
			a.Name = 'New Saas Account';
			a.CostGuard_Acct__c = SaasCostGuardAcctNumber;
			a.RecordTypeId = SelectRecordTypeIDByName('Resell Customers','Account');
			a.LinkedLDAccount__c = teleAcct.Id;
			
			insert a;
			
			saasId = a.Id;
		}
		else
		{
			Account a = [SELECT ID, RecordTypeId, LinkedLDAccount__c FROM Account WHERE Id = :saasId];
			a.LinkedLDAccount__c = teleAcct.Id;
			
			update a;
		}
		
		teleAcct.SaasPartnerAccount__c = saasId;
		teleAcct.RecordTypeId = recTypeId;
		
		update teleAcct;
	}
	
	
	static testMethod void TestCastIronWebServices() 
    {
    	Account a = new Account();
    	a.Name = 'Test';
    	a.CostGuard_Acct__c = '10000000';
    	
    	insert a;
    	
    	CastIronWebServices.AddSaasPartnerAccount('99999999','10000000');
    	
    	Account a2 = new Account();
    	a2.Name = 'Test2';
    	a2.CostGuard_Acct__c = '22222222';
    	a2.RecordTypeId = SelectRecordTypeIDByName('Resell Customers','Account');
    	
    	insert a2;
    	
    	CastIronWebServices.AddSaasPartnerAccount('22222222','10000000');
    }
}