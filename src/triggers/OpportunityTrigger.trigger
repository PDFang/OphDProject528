trigger OpportunityTrigger on Opportunity (
    before insert, after insert, 
    before update, after update, 
    before delete, after delete) {
        
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                // Call class logic here!
                OpportunityTriggerHandler oppHandlerInst = new OpportunityTriggerHandler();
				oppHandlerInst.updateOrInsertOpportunity(trigger.new);
            } 
            if (Trigger.isUpdate) {
                // Call class logic here!
                OpportunityTriggerHandler oppHandlerInst = new OpportunityTriggerHandler();
                oppHandlerInst.checkOppIsUpdated(trigger.new, trigger.oldMap);
            }
            if (Trigger.isDelete) {
                // Call class logic here!
            }
        }
        
        if (Trigger.IsAfter) {
            if (Trigger.isInsert) {
                // Call class logic here!
            } 
            if (Trigger.isUpdate) {
                // Call class logic here!
            }
            if (Trigger.isDelete) {
                // Call class logic here!
            }
        }
    }