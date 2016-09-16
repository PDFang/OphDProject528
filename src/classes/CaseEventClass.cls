public with sharing class CaseEventClass
{
	private final Case event;
	private Map<String, ProductEventMap__c> nodeMap;
	private List<Case> childIncidents;
	public integer listSize = 20;
	public integer counter = 0;
	public integer totalSize = 0;
	private string recordTypeName;
    public list<string> lstClusters = new list<string>(); 

	public CaseEventClass(Case eventCase)
	{
		Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
		Map<Id, Schema.RecordTypeInfo> recordTypeMapById = d.getRecordTypeInfosById();

		event = eventCase;

		nodeMap = ProductEventMap__c.getAll();


		recordTypeName = recordTypeMapById.get(event.RecordTypeId).Name;

		childIncidents = new List<Case> ();

		if (event != null)
		childIncidents = SelectChildIncidents(event.Id);
	}

	@future
	public static void SyncChildCases(id eventId)
	{
		Case event = [SELECT Reason__c, Releases__c, Status, Disposition__c, Reason, Issue_Product__c, Database__c, Clients__c, OtherJustification__c FROM Case WHERE Id = :eventId];
		Case[] childCases = [SELECT ID, Reason__c, Releases__c, Reason, Disposition__c, Database__c, CaseNumber, Subject, Account.Name, Account.CostGuard_Acct__c, Status, KnownIssue__c FROM Case WHERE ParentId = :eventId];

		if (!childCases.isEmpty())
		{
			for (Case ic : childCases)
			{
				//don't change status if attached to known issue
				if (ic.KnownIssue__c == NULL)
				{
					ic.Status = event.Status;
				}

				ic.Database__c = event.Database__c;
				ic.Disposition__c = event.Disposition__c;
				ic.Reason = event.Reason;
				ic.Issue_Product__c = event.Issue_Product__c;
				ic.Clients__c = event.Clients__c;
				ic.Reason__c = event.Reason__c;
				ic.Releases__c = event.Releases__c;

				if (event.Releases__c != null && event.Releases__c.contains('Other'))
				{
					ic.OtherJustification__c = event.OtherJustification__c;
				}
			}

			update childCases;
		}
	}


	public static Set<String> excludedPlatforms()
	{
		Set<String> exPlatforms = new Set<String> { 'Echo' }; // removed WFO
		return exPlatforms;
	}

	public List<Account> EventExcludedAccounts()
	{
		Account[] accounts = new Account[] { };

		accounts = [SELECT Id, Name, CadebillAccountNo__c, inContact_Cluster__c, Verint_Cluster__c FROM Account WHERE ID IN(SELECT Account__c FROM EventAccount__c WHERE Excluded__c = true AND Event__c = :event.Id) ORDER BY Name];

		return accounts;
	}

	public List<AccountIncident> AccountIncidentList()
	{
		AccountIncident[] ais = new AccountIncident[] { };
		Map<Id, Case> accountCaseMap = new Map<Id, Case> ();
		Account[] accounts = new Account[] { };


		accounts = EventAccountList();

		if (!accounts.isEmpty())
		{

			for (Case c : childIncidents)
			{
				accountCaseMap.put(c.AccountId, c);
			}

			if (!accountCaseMap.isEmpty())
			{
				for (Account a : accounts)
				{
					AccountIncident ai = new AccountIncident(a);

					if (accountCaseMap.containsKey(a.Id))
					{
						ai.childCase = accountCaseMap.get(a.Id);
					}

					ais.add(ai);
				}

				return ais;
			}



			for (Account a : accounts)
			{
				AccountIncident ai = new AccountIncident(a);
				ais.add(ai);
			}
		}

		return ais;
	}


	public List<Account> EventAccountList()
	{
		Account[] accounts = new Account[] { };
		Map<String, String> clusterProducts = new Map<String, String> ();
		Set<String> nonClusterProducts = new Set<String> ();
		Set<String> excludedProducts = new Set<String> ();
		Set<String> excludedPlatforms = excludedPlatforms();
		Set<Id> excludedAccounts = new Set<Id> ();
		Set<Id> addedAccounts = new Set<Id> ();
		Set<Id> incidentAccounts = new Set<Id> ();
		Set<Id> resellPartnerIds = new Set<Id> ();
		String implementedProduct = '';

		String product = event.ProductImpacted__c;
        //String[] platforms = event.PlatformsImpacted__c.split(';');
        String[] platforms = String.isNotBlank(event.PlatformsImpacted__c) ? event.PlatformsImpacted__c.split(';') : new String[]{};
		
        // Added by Arnab - if there are clusters predefined dont look for everything
        if(lstClusters.size() > 0) 
            platforms = lstClusters; 
        
        
		//ProductEventMap__c productMap = nodeMap.get(product);
		ProductEventMap__c productMap = nodeMap.get(product);

		//if multiple cluster for product map will be null
		if (productMap != null)
		{
			implementedProduct = productMap.ImplementedProduct__c;
		}
		else
		{
			//get the first instance for multiple cluster per product
			for (ProductEventMap__c pm : nodeMap.values())
			{
				if (pm.Product__c == product)
				{
					productMap = pm;
					break;
				}
			}
		}

		System.debug('productmap ==>' + productMap);
		excludedAccounts = ExcludedAccountIds(event.Id);
		addedAccounts = AddedAccountIds(event.Id);

		System.debug('excludedAccounts ==>' + excludedAccounts);


		if (!childIncidents.isEmpty())
		{
			for (Case c : childIncidents)
			{
				incidentAccounts.add(c.AccountId);
			}
		}

		if (productMap != null && productMap.AllCustomers__c)
		{
			for (ProductEventMap__c p : nodeMap.values())
			{
				if (excludedPlatforms.contains(p.Platform__c))
				{
					excludedProducts.add(p.ImplementedProduct__c);
				}
			}

			if (recordTypeName == 'Maintenance Notification')
			{
				accounts = [SELECT Id, Name, CadebillAccountNo__c, inContact_Cluster__c, Verint_Cluster__c, CSM__r.Email FROM Account WHERE CG_Disconnect_Date__c = NULL AND ID IN(SELECT Account__c FROM ImplementedProduct__c WHERE(GoLiveDate__c <= TODAY OR(EstimatedGoLiveDate__c <= NEXT_N_DAYS : 14 AND Status__c != 'Canceled')) AND Product__c NOT IN :excludedProducts) AND ID NOT IN :excludedAccounts ORDER BY Name LIMIT :listSize OFFSET :counter];
				totalSize = [SELECT COUNT() FROM Account WHERE CG_Disconnect_Date__c = NULL AND ID IN(SELECT Account__c FROM ImplementedProduct__c WHERE(GoLiveDate__c <= TODAY OR(EstimatedGoLiveDate__c <= NEXT_N_DAYS : 14 AND Status__c != 'Canceled')) AND Product__c NOT IN :excludedProducts) AND ID NOT IN :excludedAccounts];
			}
			else
			{
				accounts = [SELECT Id, Name, CadebillAccountNo__c, inContact_Cluster__c, Verint_Cluster__c, CSM__r.Email FROM Account WHERE CG_Disconnect_Date__c = NULL AND ID IN(SELECT Account__c FROM ImplementedProduct__c WHERE GoLiveDate__c <= TODAY AND Product__c NOT IN :excludedProducts) AND ID NOT IN :excludedAccounts ORDER BY Name LIMIT :listSize OFFSET :counter];
				totalSize = [SELECT COUNT() FROM Account WHERE CG_Disconnect_Date__c = NULL AND ID IN(SELECT Account__c FROM ImplementedProduct__c WHERE GoLiveDate__c <= TODAY AND Product__c NOT IN :excludedProducts) AND ID NOT IN :excludedAccounts];
			}
		}
		else if (productMap != null && productMap.SelectCustomers__c)
		{
			accounts = [SELECT Id, Name, CadebillAccountNo__c, inContact_Cluster__c, Verint_Cluster__c, CSM__r.Email FROM Account WHERE CG_Disconnect_Date__c = NULL AND(ID IN :addedAccounts OR ID IN :incidentAccounts) ORDER BY Name LIMIT :listSize OFFSET :counter];
			totalSize = [SELECT COUNT() FROM Account WHERE CG_Disconnect_Date__c = NULL AND(ID IN :addedAccounts OR ID IN :incidentAccounts)];
		}
		else
		{

			ImplementedProduct__c[] includedProducts = new ImplementedProduct__c[] { };
			ImplementedProduct__c[] resellerProducts = new ImplementedProduct__c[] { };
			Set<Id> implementedAccounts = new Set<Id> ();

			if (productMap != null && productMap.HasClusters__c)
			{
				for (String s : platforms)
				{

					clusterProducts.put(s.left(s.indexOf(' - ')).trim(), implementedProduct);
					system.debug('s ==> ' + s.left(s.indexOf(' - ')).trim());

				}
				system.debug('clusterProducts ==> ' + clusterProducts);

				if (recordTypeName == 'Maintenance Notification')
				{
					// Added the Verint cluster in where clause
					includedProducts = [SELECT Account__c
					                    FROM ImplementedProduct__c
					                    WHERE Account__r.CG_Disconnect_Date__c = NULL
					                    AND(Account__r.inContact_Cluster__c IN :clusterProducts.keySet()
					                        OR Account__r.Verint_Cluster__c IN :clusterProducts.keySet()
                                            OR Account__r.NICE_WFM_Cluster__c IN :clusterProducts.keySet()
                                            OR Account__r.NICE_QM_Cluster__c IN :clusterProducts.keySet())
					                    AND Product__c IN :clusterProducts.values()
					                    AND(GoLiveDate__c <= TODAY
					                        OR(EstimatedGoLiveDate__c <= NEXT_N_DAYS : 14
					                           AND Status__c != 'Canceled'))];
				}
				else
				{
					includedProducts = [SELECT Account__c
					                    FROM ImplementedProduct__c
					                    WHERE Account__r.CG_Disconnect_Date__c = NULL
					                    AND(Account__r.inContact_Cluster__c IN :clusterProducts.keySet()
					                        OR Account__r.Verint_Cluster__c IN :clusterProducts.keySet()
                                            OR Account__r.NICE_WFM_Cluster__c IN :clusterProducts.keySet()
                                            OR Account__r.NICE_QM_Cluster__c IN :clusterProducts.keySet())
					                    AND Product__c IN :clusterProducts.values()
					                    AND GoLiveDate__c <= TODAY];

				}
			}
			else
			{
				nonClusterProducts.add(implementedProduct);
				//add platforms to product list for VoIP services
				for (String s : platforms)
				{
					nonClusterProducts.add(s);
				}

				if (recordTypeName == 'Maintenance Notification')
				{
					includedProducts = [SELECT Account__c
					                    FROM ImplementedProduct__c
					                    WHERE Account__r.CG_Disconnect_Date__c = NULL
					                    AND Product__c IN :nonClusterProducts
					                    AND(GoLiveDate__c <= TODAY
					                        OR(EstimatedGoLiveDate__c <= NEXT_N_DAYS : 14
					                           AND Status__c != 'Canceled'))];
				}
				else
				{
					// change the query format
					includedProducts = [SELECT Account__c
					                    FROM ImplementedProduct__c
					                    WHERE Account__r.CG_Disconnect_Date__c = NULL
					                    AND Product__c IN :nonClusterProducts AND GoLiveDate__c <= TODAY];
				}
			}





			if (!includedProducts.isEmpty())
			{
				for (ImplementedProduct__c ip : includedProducts)
				{
					implementedAccounts.add(ip.Account__c);
				}
			}


			Account[] resellPartners = [SELECT ParentId FROM Account WHERE Parent.RecordType.Name = 'Resell Partner' AND(Id IN :implementedAccounts
			                                                                                                             OR ID IN :addedAccounts
			                                                                                                             OR ID IN :incidentAccounts)];
			if (!resellPartners.isEmpty())
			{
				for (Account partner : resellPartners)
				{
					resellPartnerIds.add(partner.ParentId);
				}
			}

			accounts = [SELECT Id, Name, CadebillAccountNo__c, inContact_Cluster__c, Verint_Cluster__c, CSM__r.Email, ParentId FROM Account
			            WHERE
			            CG_Disconnect_Date__c = NULL
			            AND(
			                Id IN :implementedAccounts
			                OR ID IN :addedAccounts
			                OR ID IN :incidentAccounts
			                OR ID IN :resellPartnerIds
			)
			            AND ID NOT IN :excludedAccounts
			            ORDER BY Name
			            LIMIT :listSize OFFSET :counter
			           ];

			totalSize = [SELECT COUNT() FROM Account
			             WHERE
			             CG_Disconnect_Date__c = NULL
			             AND(
			                 Id IN :implementedAccounts
			                 OR ID IN :addedAccounts
			                 OR ID IN :incidentAccounts
			)
			             AND ID NOT IN :excludedAccounts
			            ];
			//accounts.addAll([SELECT Id, Name, CostGuard_Acct__c, inContact_Cluster__c  FROM Account WHERE CG_Disconnect_Date__c = NULL AND inContact_Cluster__c IN :clusterProducts.keySet() AND Id IN(SELECT Account__c FROM ImplementedProduct__c WHERE Product__c IN :clusterProducts.values() AND GoLiveDate__c <= TODAY) AND ID NOT IN(SELECT Account__c FROM EventAccount__c WHERE Event__c = :event.Id AND Excluded__c = true) ORDER BY Name]);
			//accounts.addAll([SELECT Id, Name, CostGuard_Acct__c, inContact_Cluster__c  FROM Account WHERE CG_Disconnect_Date__c = NULL AND ID IN(SELECT Account__c FROM EventAccount__c WHERE Event__c = :event.Id AND Excluded__c = false) ORDER BY Name]);
		}

		return accounts;
	}

	public Set<ID> ExcludedAccountIds(Id eventId)
	{

		List<EventAccount__c> excludedAccountList = new List<EventAccount__c> ();
		Set<Id> excludedAccounts = new Set<Id> ();

		excludedAccountList = [SELECT Account__c FROM EventAccount__c WHERE Event__c = :eventId AND Excluded__c = true];

		if (!excludedAccountList.isEmpty())
		{
			for (EventAccount__c ea : excludedAccountList)
			{
				excludedAccounts.add(ea.Account__c);
			}
		}

		return excludedAccounts;
	}

	public Set<ID> AddedAccountIds(Id eventId)
	{
		List<EventAccount__c> addedAccountList = new List<EventAccount__c> ();
		Set<Id> addedAccounts = new Set<Id> ();

		addedAccountList = [SELECT Account__c FROM EventAccount__c WHERE Event__c = :eventId AND Excluded__c = false];

		if (!addedAccountList.isEmpty())
		{
			for (EventAccount__c ea : addedAccountList)
			{
				addedAccounts.add(ea.Account__c);
			}
		}

		return addedAccounts;
	}

	public List<Case> SelectChildIncidents(Id eventId)
	{
		Case[] cases = new Case[] { };

		cases = [SELECT Id, CaseNumber, AccountId FROM Case WHERE ParentId = :eventId];

		return cases;
	}

	/* methods and properties for the pagination*/


	public void Beginning()
	{ //user clicked beginning
		counter = 0;
	}

	public void Previous()
	{ //user clicked previous button
		counter -= listSize;
	}

	public void Next()
	{ //user clicked next button
		counter += listSize;
	}

	public void End()
	{ //user clicked end
		counter = totalSize - math.mod(totalSize, listSize);
	}

	public Boolean getDisablePrevious()
	{
		//this will disable the previous and beginning buttons
		if (counter > 0) return false; else return true;
	}

	public Boolean getDisableNext()
	{ //this will disable the next and end buttons
		if (counter + listSize < totalSize) return false; else return true;
	}

	public Integer getTotal_size()
	{
		return totalSize;
	}

	public Integer getPageNumber()
	{
		return counter / listSize + 1;
	}

	public Integer getTotalPages()
	{
		if (math.mod(totalSize, listSize) > 0)
		{
			return totalSize / listSize + 1;
		}
		else
		{
			return(totalSize / listSize);
		}
	}

	public static List<Case> GetOpenEvents()
	{
		Case[] events = new Case[] { };
		events = [SELECT ID, Subject, Status, InternalEvent__c, CaseNumber FROM Case WHERE RecordType.Name = 'Event' AND IsClosed = False AND NonEvent__c = FALSE];
		return events;
	}

	public class AccountIncident
	{
		public Case childCase { public get; private set; }
		public Account acct { public get; private set; }

		public AccountIncident(Account a)
		{
			acct = a;
			childCase = new Case();
		}
	}

}