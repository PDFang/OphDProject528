trigger OpportunityAfterInsertUpdate on Opportunity (after insert, after update) 
{
	    
    if(trigger.isInsert) {
        OpportunityTriggerHelper.salesEnginnerReassign(trigger.new, null, true);
        new OpportunityShareHelper().addShare(trigger.new, trigger.oldMap);
    }
    if(trigger.isUpdate) {
        OpportunityTriggerHelper.salesEnginnerReassign(trigger.new, trigger.oldMap, false);
        new OpportunityShareHelper().deleteShare(trigger.new, trigger.oldMap);
        new OpportunityShareHelper().addShare(trigger.new, trigger.oldMap);
    }
    OpportunityTriggerHelper.createTripAndProjects(trigger.new);
    
}