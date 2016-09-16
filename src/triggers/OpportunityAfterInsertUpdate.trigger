trigger OpportunityAfterInsertUpdate on Opportunity (after insert, after update) 
{
	    
    if(trigger.isInsert)
    	OpportunityTriggerHelper.salesEnginnerReassign(trigger.new, null, true);
    if(trigger.isUpdate)
        OpportunityTriggerHelper.salesEnginnerReassign(trigger.new, trigger.oldMap, false);

    OpportunityTriggerHelper.createTripAndProjects(trigger.new);
    
}