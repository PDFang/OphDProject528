global class AccountSyncWebServices 
{
	public static boolean isTest = false;
	
   WebService static void AccountSync(decimal accountNo)
   {
   		ServiceConnection__c connectionInfo = ServiceConnection__c.getInstance('AccountSync');
   	
   		AccountSyncService.AuthenticationHeader authHeader = new AccountSyncService.AuthenticationHeader();
        authHeader.Password = connectionInfo.Password__c;
        authHeader.Username = connectionInfo.Username__c;
        
        AccountSyncService.AccountSyncServiceSoap sync = new AccountSyncService.AccountSyncServiceSoap();
        sync.AuthenticationHeader = authHeader;
        sync.timeout_x = 50000;
        
        sync.AccountSync(integer.valueOf(accountNo));

   }
   
}