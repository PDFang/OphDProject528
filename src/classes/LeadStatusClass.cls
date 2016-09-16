public class LeadStatusClass 
{
	
	public static void NewLeadStatusInsert(List<Lead> leads)
	{
		List<LeadDetailTracking__c> leadDetailTrackingList = new List<LeadDetailTracking__c>();
		
		for(Lead l:leads)
		{
			LeadDetailTracking__c ldt = new LeadDetailTracking__c();
			ldt.LeadStatus__c = l.Status;
			ldt.Lead__c = l.Id;
			
			leadDetailTrackingList.add(ldt);
		}
		
		insert leadDetailTrackingList;
	}
	
	public static void UpdatedLeadStatus(Map<Id, Lead> leads)
	{
		List<LeadDetailTracking__c> leadDetailTrackingAdd = new List<LeadDetailTracking__c>();
		LeadDetailTracking__c[] leadDetailTrackingUpdate = [SELECT Lead__c, LeadStatus__c FROM LeadDetailTracking__c WHERE DateTimeLeftStatus__c = null AND Lead__c IN :leads.keySet()];
		
		if(!leadDetailTrackingUpdate.isEmpty())
		{
			for(LeadDetailTracking__c ldt:leadDetailTrackingUpdate)
			{
				ldt.DateTimeLeftStatus__c = system.now();
			}
			
			update leadDetailTrackingUpdate;
		}
		
		for(Lead l:leads.values())
		{
			if(!l.IsConverted)
			{
				LeadDetailTracking__c ldt = new LeadDetailTracking__c();
				ldt.Lead__c = l.Id;
				ldt.LeadStatus__c = l.Status;
				
				leadDetailTrackingAdd.add(ldt);
			}
		}
		
		if(!leadDetailTrackingAdd.isEmpty())
		{
			insert leadDetailTrackingAdd;
		}
		
		
	}
}