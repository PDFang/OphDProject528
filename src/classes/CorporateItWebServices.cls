global class CorporateItWebServices
{
	webservice static void CreateWorkLog(string featureId, string workType, string username, decimal hoursWorked)
    {
        if(hoursWorked == 0)
        {
            return;
        }
        
        if(InContactConfiguration.Instance == 'Sandbox')
        {
            username = username + '.lab';
        }
         
        try
        {
        	Id projectId = [SELECT Id FROM Project__c WHERE TFSID__c = :featureId OR Feature__r.TFSID__C = :featureId  LIMIT 1].Id;
        	Id userId = [SELECT Id FROM User WHERE UserName = :username].Id;
        
        
            
            WorkLog__c wl = new WorkLog__c();
            wl.Project__c = projectId;
            wl.WorkPerformed__c = workType;
            wl.Hours_Worked__c = hoursWorked;
            wl.OwnerId = userId;
            wl.Date_of_Service__c = system.today();
            
            insert wl;
        }
        catch(Exception ex)
        {
            inContactBaseClass.SendErrorEmail(ex,'TFS ID ' + featureId);
        }
    }
    
    
    Webservice static void SyncCorporateTfsFeature(string featureId, integer tfsId)
    {
     	CorporateItTfsAccess.SyncTfsFeature(featureId, tfsId);
    }
}