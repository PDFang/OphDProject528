trigger AccountPartnerRelationshipChange on Account (before insert, before update) 
{
    /**
    * Disable the trigger -- No Longer needed
    */
    /** 
    //Record Types
    Id subAgentRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND Name = 'Sub Agents'].id;
    Id custRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND Name = 'Customers'].id;
    
    //Account Maps
    Map<Id,Account> custAccts = new Map<Id,Account>();
    Map<Id,Account> subAgentAccts = new Map<Id,Account>();
    
    
    //on insert
    if(trigger.isInsert)
    {
        for(Account a:trigger.new)
        {
            if(a.RecordTypeId == custRT && a.SalesPartner__c != null)
            {
                //add account is new account with a sales partner listed
                custAccts.put(a.Id,a);
            }
        }
    }
    
    if(trigger.isUpdate)
    {
        for(integer i=0; i < trigger.new.size(); i++)
        {
            Account an = trigger.new[i];
            Account ao = trigger.old[i];
            
            //customer accounts that have a different sales partner
            if(an.RecordTypeId == custRT && (an.SalesPartner__c != ao.SalesPartner__c))
            {
                //if sub agent is removed then remove master agent
                if(an.SalesPartner__c == null)
                {
                    an.SalesPartnerMasterAgent__c = null;
                }
                else
                {
                    //add to list of accounts to get updated
                    custAccts.put(an.Id,an);
                }
            }
            
            //sub agent accounts where the parent ID has changed.
            if(an.RecordTypeId == subAgentRT && (an.ParentId != ao.ParentId))
            {
                subAgentAccts.put(an.Id,an);
            }
        }
    }
    
    if(!custAccts.isEmpty())
    {
        //update customer accounts
        AccountPartnerClass.UpdateCustomerAccountMasterAgent(custAccts);
    }
    
    if(!subAgentAccts.isEmpty())
    {
        //update customer account attached to the sub agent accounts
        AccountPartnerClass.UpdateSubAgentChildAccounts(subAgentAccts);
    } 
    
    //set up channel managers
    //get channel managers
    
    /** 
    Remove all code related to channel manager   
    */
    /** 

     Map<String,Id> cm = new Map<String,Id>();
    List<ChannelManager__c> cms = new List<ChannelManager__c>([SELECT Name, ChannelManager__c FROM ChannelManager__c]);
    
  /**  for(ChannelManager__c c:cms)
    {
        cm.put(c.Name,c.ChannelManager__c);
    }
    
    //get sales partner info
    Set<Id> pa = new Set<Id>();
    Account[] partners = new Account[]{};
    Map<Id,Account> assignCa = new Map<Id,Account>();
    
    for(Account a:trigger.new)
    {
        if(a.SalesPartnerMasterAgent__c != null)
        {
            pa.Add(a.SalesPartnerMasterAgent__c);
        }
    }
    
    if(!pa.isEmpty())
    {
        partners = [SELECT Id, BillingState, DoNotAssignChannelManager__c FROM Account WHERE ID IN:pa];
        
        for(Account a:partners)
        {
            assignCa.put(a.Id,a);
        }
    }
    
    for(integer i=0;i<trigger.new.size();i++)
    {
        Account na = trigger.new[i];
        
        if(trigger.isInsert)
        {
            if(na.SalesPartnerMasterAgent__c != null && !assignCa.get(na.SalesPartnerMasterAgent__c).DoNotAssignChannelManager__c && cm.get(assignCa.get(na.SalesPartnerMasterAgent__c).BillingState) != NULL)
            {
                na.ChannelManager__c = cm.get(assignCa.get(na.SalesPartnerMasterAgent__c).BillingState);
            }
        }
        else
        {
                    
            
            if(na.SalesPartnerMasterAgent__c == null && na.ChannelManager__c != null)
            {
                na.ChannelManager__c = null;
            }
            
            if(na.SalesPartnerMasterAgent__c != null)
            {
                if(na.ChannelManager__c != null && (assignCa.get(na.SalesPartnerMasterAgent__c).DoNotAssignChannelManager__c || cm.get(assignCa.get(na.SalesPartnerMasterAgent__c).BillingState) == NULL))
                {
                    na.ChannelManager__c = null;
                }
                else if(na.ChannelManager__c != cm.get(assignCa.get(na.SalesPartnerMasterAgent__c).BillingState) && !assignCa.get(na.SalesPartnerMasterAgent__c).DoNotAssignChannelManager__c && cm.get(assignCa.get(na.SalesPartnerMasterAgent__c).BillingState) != NULL)
                {
                    na.ChannelManager__c = cm.get(assignCa.get(na.SalesPartnerMasterAgent__c).BillingState);
                }
            }
        }
    } **/
    
}