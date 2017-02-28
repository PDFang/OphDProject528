trigger LeadAfterInsertUpdateTrigger on Lead (after insert, after update)  
{
	Map<Id, Lead> leadsWithStatusChange = new Map<Id, Lead>();
	List<Lead> newLeads = new List<Lead>();
	for(integer i=0; i < trigger.new.size(); i++)
	{
		if(trigger.isInsert)
		{
			//if new create lead detail tracking records
			newLeads.add(trigger.new[i]);
		}
		else
		{
			//only send leads with a status change.
			if(trigger.new[i].Status != trigger.old[i].Status)
			{
				leadsWithStatusChange.put(trigger.new[i].Id, trigger.new[i]);
			}
		}
	}
	if(!newLeads.isEmpty())
	{
		LeadTriggerHelper.NewLeadStatusInsert(newLeads);
	}
	if(!leadsWithStatusChange.isEmpty())
	{
		LeadTriggerHelper.UpdatedLeadStatus(leadsWithStatusChange);
	}

	LeadTriggerHelper.sharePartnerLeadsWithPartnerUser(trigger.new, trigger.oldMap);
}