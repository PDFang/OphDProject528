trigger AccountAfterUpdateInsert on Account (after insert, after update) 
{
	// This is the new method for calling trigger work, eventually this class will be migrated
	new AccountTriggerHandler().Run();
	Map<Id, Account> mpActs = new Map<Id, Account>();
	List<Account> acctsToSendToSharepoint = new List<Account>();
	if(trigger.isUpdate){
		for(Account newAct : Trigger.new){
			if(newAct.CS_AM__c != Trigger.oldMap.get(newAct.Id).CS_AM__c 
				|| newAct.CSM__c != Trigger.oldMap.get(newAct.Id).CSM__c
				|| newAct.Active_Sales_Rep__c != Trigger.oldMap.get(newAct.Id).Active_Sales_Rep__c
				|| newAct.TsaPrimary__c != Trigger.oldMap.get(newAct.Id).TsaPrimary__c){
				 mpActs.put(newAct.Id, newAct);
				}

            //Create SharePoint site if account number changes
            if (newAct.CadebillAccountNo__c != null && newAct.CadebillAccountNo__c != Trigger.oldMap.get(newAct.Id).CadebillAccountNo__c)
            {
				acctsToSendToSharepoint.add(newAct);
            }

		}
		// Account tobe sent to sharepoint if cadbill account number is there
		if(acctsToSendToSharepoint.size() > 0)
			AccountTriggerHelper.accSendToSharePoint(acctsToSendToSharepoint);

		// Update contracts if any of these above field has changed
		if(mpActs.size() > 0)
			AccountTriggerHelper.updateContract(mpActs);

		// Call Entitlement Creation method
		AccountTriggerHelper.accEntitlementsCreation(Trigger.new, Trigger.old);

		AccountTriggerHelper.updateVariousAccountTypes(Trigger.newMap, Trigger.oldMap);
	}
	else if (trigger.isInsert){
		for(Account na : Trigger.new){
            //Create SharePoint site if account number changes
            if (na.CadebillAccountNo__c != null){
                acctsToSendToSharepoint.add(na);
            }        
        }
		AccountTriggerHelper.accSendToSharePoint(acctsToSendToSharepoint);

    }
}