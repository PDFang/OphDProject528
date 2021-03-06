public class CaseEventAccountsExtension 
{
    private final Case c;
    public Account[] accounts{public get;private set;}
    public Account[] excludedAccounts{public get;private set;}
    public Account[] accountsSearched{public get;private set;}
    private integer listSize=20;
    private integer counter=0;
    public integer totalSize{public get;private set;}
    public string searchString{get;set;}
    public integer accountRows{get;set;}
    public string selectedAccount{get;set;}
    public string selectedAccountFromMasterList{get;set;}
    public string selectedExcludedAccount{get;set;}
    public string batchMessage{get;set;}
    public string batchStatus{get;set;}
    private Set<Id> accountIds;
    public boolean canEdit{public get;private set;}
    public boolean canBatch{public get; private set;}
    public boolean enablePoller {public get; private set;}
    public CaseEventClass cec{public get;private set;}
    public CaseEventClass.AccountIncident[] acctIncidents{
        												get{
                                                            if(acctIncidents != null) 
                                                                  return acctIncidents;
                                                            else
                                                                return new CaseEventClass.AccountIncident[]{};
                                                         } 
       													set{acctIncidents = value;}
    												  }
     // Avariables for pagination - Arnab
	 public Integer FirstPage {get;set;}
	 private Integer sumCount;
     private Integer totalRecords;
     public Integer lastPage{get; Set;}
	 public Integer currentPageCount{get{ return 15;} set;}

    public CaseEventAccountsExtension(ApexPages.StandardController controller) 
    {
		totalSize = 0;
        FirstPage = 0;
        this.c = (Case)controller.getRecord();
        accountIds = new Set<Id>();
        
        //system.debug('this is c ==>' + c.Id);
        
        if(c.Id != null){
            
          cec = new CaseEventClass(c);
            AccountIncidentsUpdate();
            ExcludedAccountsUpdate();
             canEdit = inContactBaseClass.HasEditAccess(c.Id,UserInfo.getUserId());
         
        }

        RecordType r = [Select Name From RecordType where Id = :c.RecordTypeId limit 1];
        if(r.Name == 'Maintenance Notification'){
                canBatch = true;
                enablePoller = true;
                xmNotificationGroups__c[] xmGroup = [SELECT Id, Name, Status__c, CreatedDate FROM xmNotificationGroups__c WHERE Case__c = :c.id ORDER BY CreatedDate DESC NULLS LAST LIMIT 1];
                if (xmGroup.size() > 0) {
                    enablePoller = (xmGroup[0].Status__c != 'In Progress' && xmGroup[0].Status__c != 'New') ? false : true;
                }
        }
    }
    
    public void AccountSearch()
    {
        AccountsSearchedUpdate();
        accountRows = numberOfAccounts;   
    }
    
    
    private void EventAccountsUpdate()
    {
        
        accounts = cec.EventAccountList();
        
        if(!accounts.isEmpty())
        {
            for(Account a:accounts)
            {
                accountIds.add(a.Id);
            }
        }
    }
    
    private void AccountIncidentsUpdate()
    {
        acctIncidents = cec.AccountIncidentList();

        
        if(!acctIncidents.isEmpty())
        {
            for(CaseEventClass.AccountIncident a:acctIncidents )
            {
                accountIds.add(a.acct.Id);
            }
        }
		totalSize = acctIncidents.size();
		doPagination();
    }
    
    private void AccountsSearchedUpdate()
    {
        if(searchString != '')
        {
            string formattedSearchText =  '%' + searchString + '%';
            double accountSearch = null;
            if(searchString .isNumeric())
            {
                accountSearch = double.valueOf(searchString);
            }
            
            totalSize = [SELECT COUNT() FROM Account WHERE ID NOT IN :accountIds AND CG_Disconnect_Date__c = NULL AND CadebillAccountNo__c != NULL AND (CadebillAccountNo__c = :accountSearch OR Name LIKE :formattedSearchText)] ;
            accountsSearched = [SELECT Id, CostGuard_Acct__c,CadebillAccountNo__c, Name, CSM__c, RecordType.Name FROM Account WHERE ID NOT IN :accountIds AND CG_Disconnect_Date__c = NULL AND CadebillAccountNo__c != NULL AND (CadebillAccountNo__c = :accountSearch OR Name LIKE :formattedSearchText) 
                                ORDER BY Name
                                LIMIT :listSize
                                OFFSET :counter
                               ] ;
       }
    }
    
    private void ExcludedAccountsUpdate()
    {
        excludedAccounts = cec.EventExcludedAccounts();
        
        if(!excludedAccounts.isEmpty())
        {
            for(Account a:excludedAccounts)
            {
                accountIds.add(a.Id);
            }
        }
    }
    
    public Integer numberOfAccounts
    {
        get{return accountsSearched.size();}
    }
    
    public void AddAccount()
    {
        EventAccount__c ea = new EventAccount__c();
        ea.Event__c = c.Id;
        ea.Account__c = selectedAccount;
        
        insert ea;
        
        
        AccountIncidentsUpdate();
        AccountsSearchedUpdate();
    }
    
    public void RemoveAccount()
    {
        if(0 < [SELECT COUNT() FROM EventAccount__c WHERE Account__c = :selectedAccountFromMasterList AND Event__c = :c.Id])
        {
            EventAccount__c rea = new EventAccount__c();
            rea = [SELECT Id FROM EventAccount__c WHERE Account__c = :selectedAccountFromMasterList AND Event__c = :c.Id LIMIT 1];
            delete rea;
        }
        else
        {
            EventAccount__c rea = new EventAccount__c();
            rea.Event__c = c.Id;
            rea.Account__c = selectedAccountFromMasterList;
            rea.Excluded__c = true;
            
            insert rea;
        }
        
        accountIds.clear();
        AccountIncidentsUpdate();
        ExcludedAccountsUpdate();
        AccountsSearchedUpdate();
    }
    
    public void RemoveExclusion()
    {
        EventAccount__c rea = new EventAccount__c();
        rea = [SELECT Id FROM EventAccount__c WHERE Event__c = :c.Id AND Account__c = :selectedExcludedAccount AND Excluded__c = true LIMIT 1];
        
        delete rea;
        
        accountIds.clear();
        AccountIncidentsUpdate();
        ExcludedAccountsUpdate();
        AccountsSearchedUpdate();
    }
    
    public PageReference AssociatedBeginning() 
    { //user clicked beginning
      cec.Beginning();
        AccountIncidentsUpdate();
      return null;
   }

   public PageReference AssociatedPrevious() 
   { //user clicked previous button
      cec.Previous();
        AccountIncidentsUpdate();
      return null;
   }

   public PageReference AssociatedNext() 
   { //user clicked next button
      cec.Next();
        AccountIncidentsUpdate();
      return null;
   }

   public PageReference AssociatedEnd() 
   { //user clicked end
      cec.End();
        AccountIncidentsUpdate();
      return null;
   }

    public void BatchAssociatedAccounts()
    {
        // create group in Xmatters
        string xmGroupName =  'Event_' + c.CaseNumber + '_' + Datetime.now().format('yyyyMMddHHmmssSSS'); // e.g.Event_00830369_12012017225545
        boolean xmError = false;
        XMGroupModel xmGroup = null;
        try {
            XMRestGroup xm = new XMRestGroup();
            xmGroup = xm.CreateNewGroupWithResponseDetail(xmGroupName);
            boolean xmAddShiftToGroup = xm.AddShiftToGroup(xmGroupName, '24x7');
            xmError = (String.isBlank(xmGroup.id) || !xmAddShiftToGroup) ? true: false;
        }catch(Exception ex){
            xmError = true;
        }

        if (xmError) {
            batchMessage = 'An error occurred with xMatters when attempting to create the account group. Please try again.';
        }
        else
        {
            // create Notification Group
            try{
                xmNotificationGroups__c xmNotificationGroup = new xmNotificationGroups__c(
                        Case__c = c.Id,
                        Name = xmGroup.targetName,
                        xmGroupUID__c = xmGroup.id,
                        Status__c = 'New'
                );
                insert xmNotificationGroup;

                // queue the Accounts Batch job
                Id xmNotificationAccountQueueableJobID = System.enqueueJob(new xmNotificationAccountQueueable(xmNotificationGroup));

            }catch(Exception ex){
                batchMessage = 'An error occurred with Salesforce when attempting to create the account group. Please try again.';
            }
        }
    }

    // Enable/Disable the Accounts Batch button and display status
    public boolean getDisableBatchAccount() {
        boolean disableBatchAccountButton = true;

        // enable button in certain status
        string displayedBatchStatus = getDisplayedBatchStatus();
        if (!string.isBlank(displayedBatchStatus)){
            batchStatus = 'Account Batch Status: ' + displayedBatchStatus;
            enablePoller = ( displayedBatchStatus != 'Processing' && displayedBatchStatus != 'New') ? false : true;
        }
        disableBatchAccountButton = (displayedBatchStatus == 'Ready' || displayedBatchStatus == 'Failed' || string.isBlank(displayedBatchStatus)) ? false : true;

        // disable button if exceeds maxium running batches
        if (!disableBatchAccountButton) {
            if (getNumOfRunningBatches() == 5) {
                batchMessage = 'Warning: Max number of account group batches are currently running, please wait until the other account groups are created and try again.';
                disableBatchAccountButton = true;
            }
        }

        return disableBatchAccountButton;
    }

    private boolean isDefaultGroupChanged()
    {
        Set<ID> setAccountIds;
        boolean isChanged = false;
        setAccountIds = cec.AddedAccountIds(c.id);

        if (setAccountIds.size() <= 0)
        {
            setAccountIds = cec.ExcludedAccountIds(c.id);
        }
        if (setAccountIds.size() > 0)
        {
            isChanged = true;
        }

        return isChanged;
    }

    private string getDisplayedBatchStatus()
    {
        xmNotificationGroups__c[] xmGroup = [SELECT Id, Name, Status__c, CreatedDate FROM xmNotificationGroups__c WHERE Case__c = :c.id ORDER BY CreatedDate DESC NULLS LAST LIMIT 1];

        string displayedBatchStatus;
        if (xmGroup.size() > 0) {
            if (xmGroup[0].Status__c == 'New') {
                displayedBatchStatus = 'New';
            } else if (xmGroup[0].Status__c == 'Failed') {
                displayedBatchStatus = 'Failed';
            } else if (xmGroup[0].Status__c == 'Completed') {
                displayedBatchStatus = 'Ready';
            } else {
                displayedBatchStatus = 'Processing';
            }
        }

        return displayedBatchStatus;
    }

    private integer getNumOfRunningBatches()
    {
        List<AsyncApexJob> jobList = [
                SELECT Id, Status
                FROM AsyncApexJob
                WHERE Status IN ('Preparing', 'Processing', 'Queued') AND JobType = 'BatchApex'
                ORDER BY createddate DESC
                LIMIT 5
        ];

        return jobList.size();
    }

    public PageReference refreshBatchStatus()
    {
        return null;
    }

    public PageReference Beginning() 
    { //user clicked beginning
      counter = 0;
      AccountsSearchedUpdate();
      return null;
   }

   public PageReference Previous() 
   { //user clicked previous button
      counter -= listSize;
      AccountsSearchedUpdate();
      return null;
   }

   public PageReference Next() 
   { //user clicked next button
      counter += listSize;
      AccountsSearchedUpdate();
      return null;
   }

   public PageReference End() 
   { //user clicked end
      counter = totalSize - math.mod(totalSize, listSize);
      AccountsSearchedUpdate();
      return null;
   }

   public Boolean getDisablePrevious() 
   { 
      //this will disable the previous and beginning buttons
      if (counter>0) return false; else return true;
   }

   public Boolean getDisableNext() { //this will disable the next and end buttons
      if (counter + listSize < totalSize) return false; else return true;
   }

   public Integer getTotal_size() {
      return totalSize;
   }

   public Integer getPageNumber() {
      return counter/listSize + 1;
   }

   public Integer getTotalPages() 
   {
      if (math.mod(totalSize, listSize) > 0) {
         return totalSize/listSize + 1;
      } else {
         return (totalSize/listSize);
      }
   }
   // Methods for pagination
   public void doPagination()
    {	
            lastPage = Math.mod(totalSize, currentPageCount) == 0 ? totalSize / currentPageCount : totalSize / currentPageCount + 1;
   }

   public void previousPage()
   {
		if(FirstPage - currentPageCount >= 0)
        {
            FirstPage -= currentPageCount;
        }
    }
   
	public void nextPage()
    {
            //System.debug('totalSize ==>' + totalSize);
            if(FirstPage + currentPageCount < totalSize)
            {
                FirstPage += currentPageCount;
               
            }
    }
    
	public void lastPage()
    {
                FirstPage = totalSize - currentPageCount;
    }
	public void firstPageS()
    { 
      FirstPage = 0;
    } 
}