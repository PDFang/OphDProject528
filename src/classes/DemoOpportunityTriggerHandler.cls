public class DemoOpportunityTriggerHandler extends TriggerHandler{
	
    public override void beforeUpdate()
    {
        updateOpportunityName((List<Opportunity>)trigger.new, (Map<Id, Opportunity>)trigger.oldMap);
    }

    public override void beforeInsert()
    {
        updateOpportunityName((List<Opportunity>)trigger.new, (Map<Id, Opportunity>)trigger.oldMap);
    }
    
    private static void updateOpportunityName(List<Opportunity> newList, Map<Id, Opportunity> oldMap){
        
        Set<Id> accountIdSet = new Set<Id>();
        List<Opportunity> processList = new List<Opportunity>();
        for(Opportunity newOpp :newList){
            Opportunity oldOpp = oldMap != null ? oldMap.get(newOpp.ID) : null;
            if(trigger.isInsert || ( trigger.isUpdate && oldOpp.AccountId != newOpp.AccountId ) ){
				accountIdSet.add(newOpp.AccountId);
                processList.add(newOpp);
            }                
        }
               
		if(processList.isEmpty()){
        	return; 
		}
               
        Map<Id, Account> accountMap = new Map<Id, Account>([
           Select Id, Name from Account where Id IN :accountIdSet 
        ]);
               
        for(Opportunity newOpp :newList){
            Opportunity oldOpp = oldMap != null ? oldMap.get(newOpp.ID) : null;
            if(trigger.isInsert){
                newOpp.Name =  newOpp.Name + ' - ' + accountMap.get(newOpp.AccountId).Name;                
            }
            else if(trigger.isUpdate && oldOpp.AccountId != newOpp.AccountId){
				newOpp.Name = newOpp.Name.left(newOpp.Name.indexOf('-')) + ' - ' + accountMap.get(newOpp.AccountId).Name;
            }                
        }
    }
}