public class CaseWatchedCasesController 
{


    public List<Case> caseList;
    public List<Case_Watcher__c> caseWatcher;
    private ID currentUser;
    public String SortField {get; set;}
    public String PreviousSortField {get; set;}
    
    
    public CaseWatchedCasesController()
    {
        //get current user ID
        currentUser = UserInfo.getUserId();
    }
    
    public List<Case> GetWatchedCases()
    {
        //do not want to reload caseList everytime the table is rendered to allow sort capabilities
        if(caseList == null)
        {
                //get cases watched by current user
                caseList = [SELECT Id, CreatedDate, CaseNumber, Account.Name, AccountId, Subject, CostGuardAccountNumber__c, Contact.Name, ContactID, Status, Priority, RecordType.Name, Owner.Name FROM Case WHERE Id IN(SELECT Case__c FROM Case_Watcher__c WHERE Case_Watcher__c = : UserInfo.getUserId())];
        }
        
        return caseList;
    }
    
    public void UnwatchCase()
    {
        //delete the selected case from the users watch list
        caseWatcher = [SELECT Id FROM Case_Watcher__c WHERE Case__c = :ApexPages.currentPage().getParameters().get('caseId') AND Case_Watcher__c = :currentUser];
        delete caseWatcher;      
        
        //remove case from list
        for(integer i=0;i<caseList.size();i++)
        {
                if(caseList[i].Id == ApexPages.currentPage().getParameters().get('caseId'))
                {
                        caseList.remove(i);
                }
        }
        //reload page
        /*
        PageReference curPage = ApexPages.currentPage();
        curPage.getParameters().clear();
       
        curPage.setRedirect(true);
        return curPage;
        */
    }
    
    //this sorts the case watch results.
    public void DoSort()
    {
        if(!caseList.isEmpty())
        {
	        
	        String order = 'asc';
	        
	        /*This checks to see if the same header was click two times in a row, if so 
	        it switches the order.*/
	        if(PreviousSortField == SortField)
	        {
	            order = 'desc';
	            PreviousSortField = null;
	        }
	        else
	        {
	            PreviousSortField = sortField;
	        }
	       
	        //To sort the table we simply need to use this one line, nice!
	        superSort.sortList(caseList,SortField,order);
        }
    }
    
}