public class LeadTriggerHelper {
    
    public static void LeadBeforeUpdate(ID phArchiveQueue, Lead lstNewlead, Lead lstOldlead) {
 		//change nurturing program if status changes to "Convert to Partner"
		if(lstNewlead.Status == 'Converted' && lstNewlead.Lead_Status_Detail__c == 'Convert to Partner' && lstOldlead.Lead_Status_Detail__c != 'Convert to Partner')
		{
			lstNewlead.NurturingProgram__c = 'New Partner';
		}
		//see if lead left PH Archive queue to a user
		if(lstOldlead.OwnerId == phArchiveQueue && lstNewlead.OwnerId != phArchiveQueue && ((String)lstNewlead.OwnerId).substring(0,3) == '005')
		{
			//update lead gen specialist to current owner
			lstNewlead.LeadGenerationSpecialist__c = lstNewlead.OwnerId;
		}
    }
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

	// when a lead created by a Partner user is re-assigned, manually share the lead so that the user can access the Lead record even after it is re-assigned
	public static void sharePartnerLeadsWithPartnerUser(List<Lead> newList, Map<Id, Lead> oldMap){

		if(oldMap == null){
			return;
		}

		Set<Id> ownerIdSet = new Set<Id>();
		List<Lead> processList = new List<Lead>();
		for(Lead newLead : newList){
			Lead oldLead = oldMap.get(newLead.Id);
			if(newLead.OwnerId != oldLead.OwnerId){
				ownerIdSet.add(oldLead.OwnerId);
				processList.add(newLead);
			}
		}

		system.debug('**** shareWithPartnerUser(): processList - '+ processList);
		system.debug('**** shareWithPartnerUser(): ownerIdSet - '+ ownerIdSet);
		if(processList.isEmpty()){
			return;
		}

		Map<Id, User> userMap = new  Map<Id, User>([
				Select Id from User
				where IsActive = true and IsPortalEnabled = true
				and UserType IN ('Partner', 'PowerPartner')
				and Id IN :ownerIdSet
		]);

		system.debug('**** shareWithPartnerUser(): userMap - '+ userMap);
		if(userMap.isEmpty()){
			return;
		}

		List<LeadShare> shareList = new List<LeadShare>();
		for(Lead newLead : processList){
			Lead oldLead = oldMap.get(newLead.Id);
			// check if lead was previously assigned to a Partner User
			if(userMap.containsKey(oldLead.OwnerId)){
				LeadShare share = new LeadShare(
						UserOrGroupId = oldLead.OwnerId,
						LeadId = oldLead.Id,
						LeadAccessLevel = 'Edit'
				);
				shareList.add(share);
			}
		}

		system.debug('**** shareWithPartnerUser(): shareList - '+ shareList);

		if(shareList.size() > 0){
			insert shareList;
		}

	} // sharePartnerLeadsWithPartnerUser

}