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
    private Set<Id> accountIds;
    public boolean canEdit{public get;private set;}
    public boolean canBatch{public get; private set;}
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

        if(c.RecordType.Name == 'Maintenance Notification'){
            canBatch = true;
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

    // public PageReference BatchAssociatedAccounts()
    public void BatchAssociatedAccounts()
    {
        // create group in Xmatters
        string xmGroupName =  'Event_' + c.CaseNumber + '_' + Datetime.now().format('yyyyMMddHHmmss'); // e.g.Event_00830369_12012017225545
        XMRestGroup xm = new XMRestGroup();
        XMGroupModel xmGroup = null;
        xmGroup = xm.CreateNewGroupWithResponseDetail(xmGroupName);

        // create Notification Group with xMatters group name
        if (xmGroup.id != '')
        {
            try{
                xmNotificationGroups__c xmNotificationGroup = new xmNotificationGroups__c(
                        Case__c = c.Id,
                        Name = xmGroup.targetName,
                        xmGroupUID__c = xmGroup.id,
                        Status__c = 'New'
                );

                insert xmNotificationGroup;
            }catch(Exception ex){
                System.Debug('BatchAssociatedAccounts - creating Account Group in Salesforce' + ex.getMessage());
                batchMessage = 'Error: there is an issue creating Account Group in Salesforce';
            }
        }
        else
        {
            batchMessage = 'Error: there is an issue creating Account Group in Xmatters';
        }

        // queue the accounts batch job
        // Id xmNotificationAccountQueueableJobID = System.enqueueJob(new xmNotificationAccountQueueable(xmNotificationGroup));
    }

    public Boolean getDisableBatchAccount()
    {
        // check if there is any previous batch still in progress, then determine enable/disable
        xmNotificationGroups__c[] xmGroups = [SELECT Case__c,Name,Status__c FROM xmNotificationGroups__c WHERE Status__c != 'Completed' AND Status__c != 'Failed' AND Case__c = :c.id];

        if (!xmGroups.isEmpty())
        {
            batchMessage = 'An Account Batch is currently in progress.';
            return true;    // disable batch button
        }
        else
        {
            return false;   // enable batch button
        }

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