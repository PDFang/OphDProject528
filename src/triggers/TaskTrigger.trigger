trigger TaskTrigger on Task (before insert, before update) 
{
    Schema.DescribeSObjectResult projectSchema = Schema.SObjectType.Project__c; 
    Map<String,Schema.RecordTypeInfo> projectRecordTypeMapByName = projectSchema.getRecordTypeInfosByName();
    Id salesEngineeringProjectRecordTypeId = projectRecordTypeMapByName.get('Sales Engineering Project').getRecordTypeId();
    
	SalesEngineeringLogic.SetProjectTaskSubject(trigger.new, salesEngineeringProjectRecordTypeId);
}