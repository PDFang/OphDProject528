trigger AccountBeforeUpdateTrigger on Account (before update, before insert) 
{
    // This is the new method for calling trigger work, eventually this class will be migrated
    new AccountTriggerHandler().Run();

	// Refactored the ownerId change
	integer tsize = trigger.new.size();
	Map<id,id> accountOwnerIdMap = new map<Id,ID>();
	// Account Partnership trigger
    if(trigger.isUpdate)
    {
        AccountTriggerHelper.accountPartnershipChange(Trigger.new, Trigger.old);
        accountOwnerIdMap = AccountTriggerHelper.updateOwner(trigger.new, Trigger.oldMap);
    }
    else if(trigger.isInsert)
    {
        AccountTriggerHelper.accountPartnershipChange(Trigger.new, null);
        accountOwnerIdMap = AccountTriggerHelper.updateOwner(trigger.new, null);
    }

    for (Account act : trigger.new)
    {   
       if(accountOwnerIdMap.get(act.Id) != null) 
        act.OwnerId = accountOwnerIdMap.get(act.Id);
    }
   
}