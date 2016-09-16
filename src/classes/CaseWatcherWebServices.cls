global class CaseWatcherWebServices 
{

	//controls button to add case to the user's watched cases
	WebService static void WatchCase(String caseId,String currentUser)
	{
		
		Integer countOfWatching;
		
		//get current user ID	
		currentUser = UserInfo.getUserId();
		
		Case_Watcher__c caseWatcher = new Case_Watcher__c();
		//check if user is already watching the case
		countOfWatching = [SELECT COUNT() FROM Case_Watcher__c WHERE Case__c = :caseId AND Case_Watcher__c = :currentUser];
		
		//if not watching add to the watching list
		if(countOfWatching == 0)
		{
			caseWatcher.Case__c = caseId;
			caseWatcher.Case_Watcher__c = currentUser;
			
			insert caseWatcher;
		} 
	}
}