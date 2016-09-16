trigger DG_Lead_Trigger on Lead (after update, before update) {
	if (trigger.isUpdate && trigger.isBefore){
    	DG_Lead_Class.ReEngagedMQL_ToSalesDev_OnUpdate(trigger.New, trigger.Old);
    }
    if (trigger.isUpdate && trigger.isAfter){
    	DG_Lead_Class.ReEngagedMQL_ToAssignmentRule_OnUpdate(trigger.New, trigger.Old);
    } 
}