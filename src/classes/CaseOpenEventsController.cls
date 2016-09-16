public with sharing class CaseOpenEventsController 
{
    public string searchString{get;set;}
    public final Case[] cases;
    public Case[] childCases{get;set;}
    public CaseComment[] eventLogs{get;set;}
    public Account[] accounts{get;set;}
    public Contact[] contacts{get;set;}
    private integer counter;
    private integer records;
    public integer rows{get;set;}
    public integer firstRow{get;set;}
    public integer accountRows{get;set;}
    public integer accountFirstRow{get;set;}
    public boolean renderChildCases{get;set;}
    public boolean renderContacts{get;set;}
    public string selectedEvent{get;set;}
    public string selectedAccount{get;set;}
    public string selectedContact{get;set;}
    public string newCaseId{get;set;}
    
    public CaseOpenEventsController()
    {
        cases = [Select Id, CaseNumber, Subject, EventCommander__c, Status, CreatedDate FROM Case WHERE RecordType.Name = 'Event' AND IsClosed = false ORDER BY CreatedDate DESC];
        counter = 0;
        records = 5;
        rows = openEvents;
        firstRow = 0;
        renderChildCases = false;
        renderContacts = false;
    }
    
    public void AccountSearch()
    {
        string formattedSearchText = '%' + searchString + '%';
        accounts = [SELECT Id, CostGuard_Acct__c, Name, CSM__c, RecordType.Name FROM Account WHERE CG_Disconnect_Date__c = NULL AND (CostGuard_Acct__c = :searchString OR Name LIKE :formattedSearchText) ORDER BY Name LIMIT :records OFFSET :counter] ;
        accountRows = numberOfAccounts;
        accountFirstRow = 0;    
        renderContacts = false;    
    }
    
    public void FindChildCases()
    {
        string parentId = ApexPages.currentPage().getParameters().get('eventId');
        
        childCases = [SELECT Id, Account.Name, Account.CostGuard_Acct__c, CaseNumber FROM Case WHERE ParentId = :parentId ORDER BY Account.Name];
        eventLogs = [SELECT Id, CreatedDate, CommentBody, IsPublished FROM CaseComment WHERE ParentId = :parentId ORDER BY CreatedDate DESC];
        
        rows = 1;
        firstRow = integer.valueOf(ApexPages.currentPage().getParameters().get('pos'));
        renderChildCases = true;
    }
    
    public void ShowAllOpen()
    {
        firstRow = 0;
        rows = openEvents;
        renderChildCases = false;
    }
    
    public void CreateChildCase()
    {
        
        Case parentCase = new Case();
        parentCase = [SELECT Id, Subject, Status FROM Case WHERE Id = :selectedEvent];
        
        //set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        
        Case c = new Case();
        c.ParentId = parentCase.Id;
        c.Subject = parentCase.Subject;
        c.AccountId = selectedAccount;
        c.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Incident','Case');
        c.ContactId = selectedContact;
        
        c.setOptions(dmo);
        
        insert c;
        
        newCaseId = c.Id;
       
        accounts.clear();
        contacts.clear();
        childCases = [SELECT Id, Account.Name, Account.CostGuard_Acct__c, CaseNumber FROM Case WHERE ParentId = :selectedEvent ORDER BY Account.Name];
        
        
    }
    
    public void FindContacts()
    {
        accountRows = 1;
        contacts = [SELECT Id, Name, Contact_Role__c FROM Contact WHERE Deactivated__c = false AND AccountId = :selectedAccount ORDER BY Name];
        renderContacts = true;
    }
    
    public List<Case> caseList
    {
        get{return cases;}
    }
    
    public Integer openEvents
    {
        get{return cases.size();}
    }
    
    public Integer numberOfAccounts
    {
        get{return accounts.size();}
    }

}