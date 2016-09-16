trigger reassignLeads on Lead (after update){
    List<Id> lIds=new List<id>();    
    For (lead l:trigger.new){
        if (l.Status=='Re-engaged'){
            lIds.add(l.Id);
        }    
    }    
    if (AssignLeads.assignAlreadyCalled()==FALSE){
            system.debug('Assign already called? '+AssignLeads.assignAlreadyCalled());        
            AssignLeads.Assign(lIds);
    }
}