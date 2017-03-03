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
	// similarlly share the Lead with Partner Account Executive role so executives can see each others leads
	public static void sharePartnerLeadsWithPartnerUser(List<Lead> newList, Map<Id, Lead> oldMap){

		if(oldMap == null){
			return;
		}
		system.debug('**** shareWithPartnerUser(): UserType - '+ userinfo.getUserType());

		Set<Id> createdByIdSet = new Set<Id>();
		List<Lead> processList = new List<Lead>();
		for(Lead newLead : newList){
			Lead oldLead = oldMap.get(newLead.Id);
			if(newLead.OwnerId != oldLead.OwnerId){
				createdByIdSet.add(newLead.CreatedById);
				processList.add(newLead);
			}
		}

		system.debug('**** shareWithPartnerUser(): processList - '+ processList);
		system.debug('**** shareWithPartnerUser(): createdByIdSet - '+ createdByIdSet);
		if(processList.isEmpty()){
			return;
		}
		Set<Id> accountIdSet = new Set<Id>();
		Map<Id, User> userMap = new  Map<Id, User>();
		for(user partner : [
				Select Id, AccountId from User
				where IsActive = true
				and IsPortalEnabled = true
				and UserType IN ('Partner', 'PowerPartner')
				and Id IN :createdByIdSet
		]){
			userMap.put(partner.Id, partner);
			accountIdSet.add(partner.AccountId);
		}

		system.debug('**** shareWithPartnerUser(): userMap - '+ userMap);
		if(userMap.isEmpty()){
			return;
		}

		Map<Id, UserRole> accountRoleMap = new  Map<Id, UserRole>();
		for(UserRole role : [
				SELECT Id,Name,PortalAccountId
				FROM UserRole
				WHERE PortalRole = 'Executive' and PortalAccountId IN :accountIdSet
		]){
			accountRoleMap.put(role.PortalAccountId, role);

		}
		system.debug('**** shareWithPartnerUser(): accountRoleMap - '+ accountRoleMap);

		Map<Id, Group> roleGroupMap = new  Map<Id, Group>();
		for(Group roleGroup : [
				SELECT Id,Name,RelatedId
				FROM Group
				WHERE Type = 'Role'
				and RelatedId IN :accountRoleMap.values()
		]){
			roleGroupMap.put(roleGroup.RelatedId, roleGroup);
		}
		system.debug('**** shareWithPartnerUser(): roleGroupMap - '+ roleGroupMap);

		List<LeadShare> shareList = new List<LeadShare>();
		for(Lead newLead : processList){
			// check if lead was created by a Partner User
			if(userMap.containsKey(newLead.CreatedById)){
				LeadShare userShare = new LeadShare(
						UserOrGroupId = newLead.CreatedById,
						LeadId = newLead.Id,
						LeadAccessLevel = 'Read'
				);
				shareList.add(userShare);
				UserRole executiveRole = accountRoleMap.get(userMap.get(newLead.CreatedById).AccountId);
				Group executiveRoleGroup = roleGroupMap.get(executiveRole.Id);
				LeadShare groupShare = new LeadShare(
						UserOrGroupId = executiveRoleGroup.Id,
						LeadId = newLead.Id,
						LeadAccessLevel = 'Read'
				);
				shareList.add(groupShare);
			}
		}

		system.debug('**** shareWithPartnerUser(): shareList - '+ shareList);
		if(shareList.size() > 0){
			insert shareList;
		}

	} // sharePartnerLeadsWithPartnerUser

}