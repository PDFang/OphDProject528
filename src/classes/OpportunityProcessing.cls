public class OpportunityProcessing 
{
	
	public static void PsHoursValidation(Map<Id, List<Opportunity>> opportunitiesByAccountId)
	{
		List<InternalReleaseNote__c> updatedPsDocs = new List<InternalReleaseNote__c>();
		
		for(Account a: [SELECT Id, (SELECT TimePurchased__c, TimeUsed__c, TimeRemaining__c  FROM PsDocs__r WHERE TimeRemaining__c > 0 ORDER BY PSHoursExpDate__c ) FROM Account WHERE ID IN :opportunitiesByAccountId.keySet()])
		{
			decimal totalTimeRemaining = 0.0;
			decimal quotedTime = 0.0;
			
			if(!a.PsDocs__r.isEmpty())
			{
				for(InternalReleaseNote__c psDoc:a.PsDocs__r)
				{
					totalTimeRemaining = totalTimeRemaining + psDoc.TimeRemaining__c;
				}
			}
			
			for(Opportunity o:opportunitiesByAccountId.get(a.Id))
			{
				if(o.QuotedHours__c != null)
				{
					quotedTime = quotedTime + o.QuotedHours__c;
				}
			}
			
			if(totalTimeRemaining < quotedTime)
			{
				for(Opportunity o:opportunitiesByAccountId.get(a.Id))
				{
					o.addError('This customer does not have enough time purchased to complete this opportunity.');
					return;
				}
			}
			
			for(InternalReleaseNote__c psDoc:a.PsDocs__r)
			{
				if(quotedTime > 0)
				{
					if(quotedTime > psDoc.TimeRemaining__c)
					{
						psDoc.TimeUsed__c = psDoc.TimePurchased__c;
						quotedTime = quotedTime - psDoc.TimeRemaining__c;
					}
					else
					{
						psDoc.TimeUsed__c = psDoc.TimeUsed__c + quotedTime;
						quotedTime = 0;
					}
					
					updatedPsDocs.add(psDoc);
				}
			}
			
			if(!updatedPsDocs.isEmpty())
			{
				update updatedPsDocs;
			}
		}
				
	}
}