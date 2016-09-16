trigger LeadBeforeUpdate on Lead (before update) 
{
	ID phArchiveQueue = [SELECT ID FROM Group WHERE Type = 'Queue' AND Name = 'PH_Archieved_List_Leads'].Id;

	for(integer i=0; i < trigger.new.size(); i++)
	{
		/*Lead l = trigger.new[i];
		Lead ol = trigger.old[i];
		//change nurturing program if status changes to "Convert to Partner"
		if(l.Status == 'Converted' && l.Lead_Status_Detail__c == 'Convert to Partner' && ol.Lead_Status_Detail__c != 'Convert to Partner')
		{
			l.NurturingProgram__c = 'New Partner';
		}
		//see if lead left PH Archive queue to a user
		if(ol.OwnerId == phArchiveQueue && l.OwnerId != phArchiveQueue && ((String)l.OwnerId).substring(0,3) == '005')
		{
			//update lead gen specialist to current owner
			l.LeadGenerationSpecialist__c = l.OwnerId;
		}*/
        LeadTriggerHelper.LeadBeforeUpdate(phArchiveQueue,trigger.new[i],trigger.old[i]);
 	}
}