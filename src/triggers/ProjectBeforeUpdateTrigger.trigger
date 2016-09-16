trigger ProjectBeforeUpdateTrigger on Project__c(before update, before insert)
{
	if (trigger.isInsert)
	{
		// Assign Project owners and set status to New
		ProjectTriggerHelper.assignProjectOwners(Trigger.new);
	}

	if (trigger.isUpdate)
	{
		// Assign Project owners and set status to New
		ProjectTriggerHelper.setStatusForITAndDbaProjects(Trigger.new, Trigger.oldMap);
	}
}