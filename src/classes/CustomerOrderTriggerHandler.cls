public class CustomerOrderTriggerHandler extends TriggerHandler {
	public override void beforeInsert()
    {
        InsertCadebillAccount();
    }
    
    public static void InsertCadebillAccount(){
    	List<CustomerOrder__c> orderList = (List<CustomerOrder__c>)(trigger.new);
        system.debug('orderList - '+orderList);
        Set<Integer> cadebillAccounts = new Set<Integer>();
        for(CustomerOrder__c newCustomerOrder : orderList){
            // add validation
            if(newCustomerOrder.Customer__c == null && newCustomerOrder.CadebillAccountNumber__c == null){
                newCustomerOrder.addError('Cadebill Account Number cannot be blank.');
                continue;
            }
            // process only if Customer__c is null and CadebillAccountNumber__c is not null
            if(newCustomerOrder.Customer__c == null && newCustomerOrder.CadebillAccountNumber__c != null){
                Integer cbAccount = Integer.valueOf(newCustomerOrder.CadebillAccountNumber__c);
                cadebillAccounts.add(cbAccount);
            }
        }
        system.debug('cadebillAccounts - '+cadebillAccounts);
        // return if none of the orders require an update
        if(cadebillAccounts.isEmpty()){
            return;
        }
        
        // use map collection here so to avoid nested for loops below
        Map<Integer, Account> accountMap = new Map<Integer, Account>();
        
        for(Account acct :[SELECT Id, CadebillAccountNo__c FROM Account WHERE CadebillAccountNo__c IN :cadebillAccounts]){
			accountMap.put(Integer.valueOf(acct.CadebillAccountNo__c), acct);        
    	}
        

        for(CustomerOrder__c cOrder: orderList){
            Account sfAccount = accountMap.get(Integer.valueOf(cOrder.CadebillAccountNumber__c));
            // make use of map collection methods containsKey and get here
            if(sfAccount == null){
                cOrder.addError('Account '+ cOrder.CadebillAccountNumber__c + ' does not exist in Salesforce.');
                continue;
            }
            cOrder.Customer__c = sfAccount.Id;
        }

	}
}