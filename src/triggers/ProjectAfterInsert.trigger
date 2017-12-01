trigger ProjectAfterInsert on Project__c(after insert, after update)
{
	Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c;
	Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

	Id salesEngineeringRecordTypeId = rtMapByName.get('Sales Engineering Project').getRecordTypeId();
	Id psProjectPhaseSaasRecordTypeId = rtMapByName.get('PS Project Phase SaaS').getRecordTypeId();

	if (trigger.isInsert)
	{
		SalesEngineeringLogic.CreateNewProjectTasks(trigger.new, salesEngineeringRecordTypeId);
		ProjectTriggerHelper.updateParentPlannedHours(trigger.new, psProjectPhaseSaasRecordTypeId);
		ProjectTriggerHelper.createProjectTasks(Trigger.new);
		//if it is a phase project validate the phase number
		ProjectTriggerHelper.setNextPhaseNumber(Trigger.new);

	}
	else if (trigger.isUpdate)
	{
		ProjectTriggerHelper.updateParentPlannedHours(trigger.new, psProjectPhaseSaasRecordTypeId);
		ProjectTriggerHelper.updateAssetStatusForPhasedProject(trigger.new, Trigger.oldMap);
		SalesEngineeringLogic.UpdateProjectRelatedOwners(trigger.old, trigger.new, salesEngineeringRecordTypeId);
	}


}