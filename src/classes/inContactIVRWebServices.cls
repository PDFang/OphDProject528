global class inContactIVRWebServices 
{
	Webservice static boolean HasCustomerPriorityOneEvent(string customerAccountNumber)
	{
		String dialerString = '';
		String incontactString = '';
		Boolean hasDialer = false;
		Boolean hasInContact = false;
		Set<string> productSet = new Set<string>();
		string products = '';
		
		Account account = [SELECT CadebillAccountNo__c, inContact_Cluster__c, (SELECT Product__c FROM Implemented_Products__r WHERE Status__c = 'Implemented') FROM Account WHERE CadebillAccountNo__c = :double.valueOf(customerAccountNumber)];
				
		//return false if no implemented products or cluster
		if(account.Implemented_Products__r.isEmpty() || account.inContact_Cluster__c == null)
		{
			return false;
		}
		
		Map<String,ProductEventMap__c> nodeMap = ProductEventMap__c.getAll();
		
		for(ImplementedProduct__c impProduct: account.Implemented_Products__r)
		{
			for(ProductEventMap__c pem:nodeMap.values())
			{
				if(impProduct.Product__c == pem.ImplementedProduct__c)
				{
					if(pem.Platform__c == 'Cluster - inContact')
					{
						hasInContact = true;
						productSet.add(impProduct.Product__c);
					}
					if(pem.Platform__c == 'Cluster - Dialer')
					{
						hasDialer = true;
						productSet.add(impProduct.Product__c);
					}
				}
			} 
		}
		//only dialer and incontact events
		if(!hasDialer && !hasInContact)
		{
			return false;
		}
		
		for(String s:productSet)
		{
			if(s!=null)
			{
				if(products == '')
				{
					products = '\'' + s + '\'';
				}
				else
				{
					products = products + ',' + '\'' + s + '\'';
				}
			}
		}
		
		if(hasDialer)
		{
			dialerString = account.inContact_Cluster__c + ' - Dialer';
		}
		
		if(hasInContact)
		{
			incontactString = account.inContact_Cluster__c + ' - inContact';
		}
		string queryString = 'SELECT ProductImpacted__c, PlatformsImpacted__c FROM Case WHERE ProductImpacted__c IN (' + products + ') AND PlatformsImpacted__c INCLUDES(\'' + dialerString + '\',\'' + incontactString + '\') AND Priority = \'P1\' AND InternalEvent__c = false AND NonEvent__c = false AND Status != \'Suspected\' AND Status != \'Resolved\' AND IsClosed = false AND RecordType.Name = \'Event\' AND ID NOT IN(SELECT Event__c FROM EventAccount__c WHERE Account__r.CadebillAccountNo__c = ' + customerAccountNumber + ' AND Excluded__c = true)';
		
		Case[] events = Database.Query(queryString);
		
		//check for priority 1 events
		if(events.isEmpty())
		{
			return false;
		}		
		
		
		
		return true;
	}
}