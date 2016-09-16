trigger OpportunityBeforeTrigger on Opportunity (before insert, before update) 
{
    if(trigger.isInsert){
        OpportunityTriggerHelper.updateSalesRep(trigger.new, true);
   		OpportunityTriggerHelper.updateTimeStamps(trigger.new);        
    }
    if(trigger.isUpdate){
        OpportunityTriggerHelper.performOtherOperations(trigger.new, trigger.oldMap);
        OpportunityTriggerHelper.updateSalesRep(trigger.new, false);
    }
        	
    OpportunityTriggerHelper.updateSalesRepFromAccount(trigger.new);
}