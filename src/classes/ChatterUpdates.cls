public class ChatterUpdates 
{
	//must be an asychronous call because you cannot update users and then another table
	@future
	public static void AddAllinContactGroupUser(Id[] users,Id chatGroup)
	{
	
		List<CollaborationGroupMember> cgms = new List<CollaborationGroupMember>();
		//make sure is not already member of the group and is a standard user
		for(Id u:users)
		{
			CollaborationGroupMember cg = new CollaborationGroupMember();
			cg.CollaborationGroupId = chatGroup;
			cg.MemberId = u;
		
			cgms.add(cg);
			
		}
		
		insert cgms;
	} 
	
	public static void ChatterFollowITDevelopment(Id[] caseIds)
	{
		List<CollaborationGroupMember> cgmList = new List<CollaborationGroupMember>();
		cgmList = [SELECT MemberId FROM CollaborationGroupMember WHERE CollaborationGroupId IN (SELECT Id FROM CollaborationGroup WHERE Name = 'IT Developers' OR Name = 'IT Development')];
		
		List<EntitySubscription> esList = new List<EntitySubscription>();
		
		for(Id c:caseIds)
		{
			for(CollaborationGroupMember cgm: cgmList)
			{
				EntitySubscription es = new EntitySubscription();
				es.ParentId = c;
				es.SubscriberId = cgm.MemberId;
				
				esList.Add(es);
				
			}
		}
		
		if(!esList.IsEmpty())
		{
			try
			{
				insert esList;
			} 
			catch (DmlException e) 
			{
				//will error if record already exists 
			}
		}
	}
	
	public static void ChatterFollowEvents(Map<Id,String> caseIds)
	{
		List<CollaborationGroupMember> cgmList = new List<CollaborationGroupMember>();
		cgmList = [SELECT MemberId FROM CollaborationGroupMember WHERE CollaborationGroupId IN (SELECT Id FROM CollaborationGroup WHERE Name IN('Event Notification'))];
		Id eventGroup;
		
		if(!Test.isRunningTest())
		{
			eventGroup = [SELECT Id FROM CollaborationGroup WHERE Name = 'Event Notification' LIMIT 1].Id;
		}
		
		
		
		List<FeedItem> feeds = new List<FeedItem>();
		List<EntitySubscription> esList = new List<EntitySubscription>();
		
		for(Id c:caseIds.keySet())
		{
			for(CollaborationGroupMember cgm: cgmList)
			{
				EntitySubscription es = new EntitySubscription();
				es.ParentId = c;
				es.SubscriberId = cgm.MemberId;
				
				esList.Add(es);
				
			}
			
			
			if(eventGroup != null && !Test.isRunningTest())
			{
				FeedItem feedI = new FeedItem();
				feedI.Body = caseIds.get(c);
				feedI.ParentId = eventGroup;
				
				feeds.add(feedI);
			}
			
		}
		
		
		if(!feeds.isEmpty())
		{
			insert feeds;
		}
		
		if(!esList.IsEmpty())
		{
			try
			{
				insert esList;
			} 
			catch (DmlException e) 
			{
				//will error if record already exists 
			}
		}
	}
	
	public static void ChatterPostClosedDeal(Set<Id> opportunities)
	{
		
		Id dealGroup;
		
		if(!Test.isRunningTest())
		{
			dealGroup = [SELECT Id FROM CollaborationGroup WHERE Name = 'Closed Won Alert Group' LIMIT 1].Id;
		}
		
		
		List<String> args = new String[]{'0','currency','###,###,##0.00'};
		List<FeedItem> feeds = new List<FeedItem>();
		
		for(Opportunity o:[SELECT Name, Account.Name, Sales_Rep__r.Name, Sales_Developer__r.Name, SalesEngineer__r.Name, CloseDate, Total_MRC_Min__c, Contract_Type__c, Partner_Deal__c, Partner_Account__r.Name, Original_Lead_Source__c, Original_Lead_Souce_Detail__c FROM Opportunity WHERE ID IN:opportunities])
		{			
			String feedBody = '';
			feedBody = 'Opportunity ' + o.Name + ' Has Been Closed - Won.';
			feedBody = feedBody + '\r\n\r\nAccount Name: ' + o.Account.Name;
			feedBody = feedBody + '\r\nSales Rep: ' + o.Sales_Rep__r.Name;
			feedBody = feedBody + '\r\nSales Developer: ' + o.Sales_Developer__r.Name;
			feedBody = feedBody + '\r\nSales Engineer: ' + o.SalesEngineer__r.Name;
			feedBody = feedBody + '\r\nClose Date: ' + o.CloseDate.format();
			feedBody = feedBody + '\r\nTotal MAT: $' +  String.format(o.Total_MRC_Min__c.format(), args);
			feedBody = feedBody + '\r\nContract Type: ' + o.Contract_Type__c;
			feedBody = feedBody + '\r\nPartner Deal: ' + o.Partner_Deal__c;
			feedBody = feedBody + '\r\nPartner Account: ' + o.Partner_Account__r.Name;
			feedBody = feedBody + '\r\nOriginal Lead Source: ' + o.Original_Lead_Source__c;
			feedBody = feedBody + '\r\nOriginal Lead Source Detail: ' + o.Original_Lead_Souce_Detail__c;
			
			if(dealGroup != null && !Test.isRunningTest())
			{
				FeedItem feedI = new FeedItem();
				feedI.Body = feedBody;
				feedI.ParentId = dealGroup;
				
				feeds.add(feedI);
			}
			
		}
		
		
		if(!feeds.isEmpty())
		{
			
			try
			{
				insert feeds;
			} 
			catch (DmlException e) 
			{
				//will error if record already exists 
			}
		}
	}
}