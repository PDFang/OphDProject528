trigger ContractBeforeInsert on Contract (before insert) 
{
    
    Set<Id> acctIds = new Set<Id>();
    
    //get all Account ids
    for(Contract c:trigger.new)
    {
        if(!acctIds.contains(c.AccountId))
        {
            acctIds.add(c.AccountId);
        }
    }
    
    //get account info
    Map<ID, Account> accts = new Map<ID, Account>([SELECT ID, CS_AM__C, CSM__c, Active_Sales_Rep__c, TsaPrimary__c FROM Account WHERE ID IN :acctIds]);
    
    
    //add in SDS,SDM, and Sales rep from account
    for(Contract c:trigger.new)
    {
        c.SDM__c = accts.get(c.AccountId).CSM__c;
        c.SDSAM__c = accts.get(c.AccountId).CS_AM__c;
        c.ActiveSalesRep__c = accts.get(c.AccountId).Active_Sales_Rep__c;
        c.TSA__c = accts.get(c.AccountId).TsaPrimary__c;
    }
}