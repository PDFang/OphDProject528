public class CaseOwnershipClass 
{
    
    public static CaseOwnership__c[] getLastCaseOwnership(Set<ID> caseIds)
    {
        
        CaseOwnership__c[] caseOwnership = [SELECT c.Id, c.Queue__c, c.Case__c, c.DateTimeAcknowledged__c, c.DateTimeLeftQueue__c, c.CreatedDate FROM CaseOwnership__c c WHERE Case__c IN :caseIds AND DateTimeLeftQueue__c = NULL];
    
        return caseOwnership;
    }
    
    public static void updateCaseOwnership(List<Case> cases,Map<ID,Group> allQueues)
    {
        
        Map<ID,CaseOwnership__c> caseOwner = new Map<ID,CaseOwnership__c>();
        Set<ID> caseIds = new Set<ID>();
        List<CaseOwnership__c> newCaseOwnerships = new List<CaseOwnership__c>();
        List<CaseOwnership__c> updateCaseOwnerships = new List<CaseOwnership__c>();
        String queueName;
        
        
        for(Case c : cases)
        {
            caseOwner.put(c.id,null);
            caseIds.add(c.id);
        }
        
        //get the last case ownership
        //CaseOwnership__c co = new CaseOwnership__c();
        //CaseOwnership__c[] caseOwnership = getLastCaseOwnership(caseId);
        CaseOwnership__c[] caseOwnership = getLastCaseOwnership(caseIds);
        
        if(caseOwnership.size()>0)
        {
            for(CaseOwnership__c co:caseOwnership)
            {
                caseOwner.put(co.Case__c, co);
            }
            
            for(Case c:cases)
            {
                CaseOwnership__c co = new CaseOwnership__c();
                
                if(allqueues.get(c.OwnerID) == null)
                {
                	queueName = 'No Queue';
                }
                else
                {
                	queueName = allqueues.get(c.OwnerId).Name;
                }
                
                if(caseOwner.get(c.Id)!=null)
                {
                    co = caseOwner.get(c.Id);
                    
                    //if queue names are the same
                    if(co.Queue__c == queueName)
                    {
                        //acknowledge if it previously wasn't and should be
                        if(!(c.Status == 'Auto-Assigned' || c.Status == 'Transferred') && co.DateTimeAcknowledged__c == null)
                        {
                            co.DateTimeAcknowledged__c = system.now();
                        }
                        
                        //close out the record if case is closed
                        if((c.Status == 'Closed' || c.Status == 'Released') && co.DateTimeLeftQueue__c == null)
                        {
                            co.DateTimeLeftQueue__c = system.now();
                            
                        }
                        
                        updateCaseOwnerships.add(co);
                    }
                    //if queues have changed
                    else
                    {
                        //create new caseownership record
                        CaseOwnership__c cn = new CaseOwnership__c();
                        
                        cn.Case__c = c.Id;
                        cn.Queue__c = queueName;
                        if(!(c.Status == 'Auto-Assigned' || c.Status == 'Transferred'))
                        {
                            cn.DateTimeAcknowledged__c = system.now();
                        }
                    
                        newCaseOwnerships.add(cn);
                        
                        //close out the old record
                        co.DateTimeLeftQueue__c = system.now();
                        if(co.DateTimeAcknowledged__c == null)
                        {
                            co.DateTimeAcknowledged__c = system.now();
                        }
                        
                        if((c.Status == 'Closed' || c.Status == 'Released') && co.DateTimeLeftQueue__c == null)
                        {
                            co.DateTimeLeftQueue__c = system.now();
                        }
                        
                        updateCaseOwnerships.add(co);
                    }
                    
                                        
                }
                                
                
            }
        }
        else  //if no caseOwnerships insert new records for all
        {
            
            
            for(Case c:cases)
            {
                CaseOwnership__c cp = new CaseOwnership__c();
                        
                cp.Case__c = c.Id;
                
                if(allqueues.get(c.OwnerID) == null)
				{
					cp.Queue__c = 'No Queue';
				}
				else
				{
					cp.Queue__c = allqueues.get(c.OwnerId).Name;
				}
				
                if(!(c.Status == 'Auto-Assigned' || c.Status == 'Transferred'))
                {
                    cp.DateTimeAcknowledged__c = system.now();
                }
                
                newCaseOwnerships.add(cp);
            }       
        }
        
        if(newCaseOwnerships.size()>0)
        {
            insert newCaseOwnerships;
        }
        
        if(updateCaseOwnerships.size()>0)
        {
            update updateCaseOwnerships;
        }
    }
        
}