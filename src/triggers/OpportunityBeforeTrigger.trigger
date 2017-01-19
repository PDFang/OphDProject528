trigger OpportunityBeforeTrigger on Opportunity (before insert, before update) 
{
    OpportunityTriggerHelper.isAvailableForCCHandOff(trigger.new, trigger.oldMap);
    if(trigger.isInsert){
        OpportunityTriggerHelper.updateSalesRep(trigger.new, true);
   		OpportunityTriggerHelper.updateTimeStamps(trigger.new);        
    }
    if(trigger.isUpdate){
        OpportunityTriggerHelper.performOtherOperations(trigger.new, trigger.oldMap);
        OpportunityTriggerHelper.updateSalesRep(trigger.new, false);
    }
    OpportunityTriggerHelper.timestampHelper(trigger.new, trigger.oldMap);
    OpportunityTriggerHelper.updateSalesRepFromAccount(trigger.new);
}