trigger ProjectTrigger on Project__c(after insert, after update, after delete)
{
	Set<Id> psParentProjectIds = new Set<Id> ();
	set<Id> allowedRecordTypes = new set<Id> ();

	Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c;
	List<Schema.RecordTypeInfo> projectRecordTypes = d.getRecordTypeInfos();

	for (Schema.RecordTypeInfo recordType : projectRecordTypes)
	{
		String recordTypeName = recordType.getName();

		if(recordTypeName.contains('Phase') && recordTypeName.startsWith('PS'))
		{
			allowedRecordTypes.add(recordType.getRecordTypeId());
		}
	}

	if (!trigger.isDelete)
	{
		for (integer i = 0; i < trigger.new.size(); i++)
		{
			Project__c newProject = trigger.new[i];

			// Only perform the update if the record type for parent is a Phased Project
			if (allowedRecordTypes.contains(newProject.RecordTypeId))
			{
				if (newProject.ParentProject__c != null)
				{
					psParentProjectIds.add(newProject.ParentProject__c);
				}

				if (!trigger.isInsert)
				{
					Project__c oldProject = trigger.old[i];

					if (newProject.ParentProject__c != oldProject.ParentProject__c && oldProject.ParentProject__c != Null)
					{
						psParentProjectIds.add(oldProject.ParentProject__c);
					}
				}
			}
		}
	}
	else
	{
		for (Project__c p : trigger.old)
		{
			if (p.ParentProject__c != null && allowedRecordTypes.Contains(p.RecordTypeId))
			{
				psParentProjectIds.add(p.ParentProject__c);
			}
		}
	}

	if (!psParentProjectIds.isEmpty())
	{
		Map<Id, Project__c> psParentProjects = ProjectClass.ProjectParentPhaseSummary(psParentProjectIds);
		update psParentProjects.values();
	}

	new ProjectTriggerHandler().run();
	
}