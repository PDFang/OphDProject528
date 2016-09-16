trigger AccountEntitlementCreation on Account (after update) 
{
     /**
    * Disable the trigger -- No Longer needed
    */
    /** 
    
    List<Account> accts = new List<Account>();
    Set<Id> excludeAccts = new Set<Id>();
    List<Entitlement> entToInsert = new List<Entitlement>();
    
    Entitlement[] ent = [Select e.Id, e.AccountId From Entitlement e WHERE e.AccountID IN :trigger.newMap.keySet() AND Status = 'Active'];
    
    if(!ent.isEmpty())
    {
        for(Entitlement e:ent)
        {
            if(!excludeAccts.contains(e.AccountId))
            {
                excludeAccts.add(e.AccountId);
            }   
        }
    }  
    
    if(trigger.new.size() != excludeAccts.size())
    {
        SlaProcess sla = [SELECT Id FROM SlaProcess WHERE Name = 'inContact Standard Process' AND IsActive = true LIMIT 1]; 
        SlaProcess vzSla = [SELECT Id FROM SlaProcess WHERE Name = 'Verizon Entitlement Process' AND IsActive = true LIMIT 1]; 
        accts = [SELECT Id, Name, CostGuard_Acct__c, Parent.CostGuard_Acct__c FROM Account WHERE ID IN :trigger.newMap.keySet() AND ID NOT IN :excludeAccts];
        
        for(Account a:accts)
        {
            if(a.CostGuard_Acct__c != NULL)
            {
                Entitlement e = new Entitlement();
                e.AccountId = a.Id;
                e.StartDate = system.today();
                e.Name = a.Name + ' - ' + a.CostGuard_Acct__c;
                
                if(a.Parent.CostGuard_Acct__c == '4593141')
                {
                    e.SlaProcessId = vzSla.Id;
                }
                else
                {
                    e.SlaProcessId = sla.Id;
                }
                
                entToInsert.add(e);
                
            }
        }
        
        if(!entToInsert.IsEmpty())
        {
            insert entToInsert;
        }
    }
    */
    
}