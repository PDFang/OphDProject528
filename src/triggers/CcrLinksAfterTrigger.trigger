trigger CcrLinksAfterTrigger on CCRLinks__c (after insert, after update) 
{
	List<Case> cases = new List<Case>();
	Set<Id> caseIds = new Set<Id>();
	
	for(CCRLinks__c link: trigger.new)
	{
		if(link.Case__c != null)
		{
			caseIds.add(link.Case__c);
		}
	}
	
	for(Case c:[SELECT Id, Status FROM Case WHERE Status <> 'Pending Change' AND RecordType.Name = 'Problem' AND ID IN :caseIds])
	{
		c.Status = 'Pending Change';
		cases.add(c);
	}
	
	if(!cases.isEmpty())
	{
		update cases;
	}
}