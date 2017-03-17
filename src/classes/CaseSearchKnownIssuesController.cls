global with sharing class CaseSearchKnownIssuesController 
{
    public Case c{get;set;}
    private Case shellCase;
    public Case[] searchResults{get;set;}
    public String searchString{get;set;}
    public string recordTypeName {get;set;}
    private string filterString;
    
    public CaseSearchKnownIssuesController()
    {        
        filterString = '';
        shellCase = new Case();
    }
    
    public void Search()
    {        
        string query = 'SELECT Id, CaseNumber, Subject, ProductImpacted__c, PlatformsImpacted__c FROM Case WHERE RecordType.Name = \'' + recordTypeName + '\' AND IsClosed = false' + filterString + ' LIMIT 30';
        
        searchResults = Database.Query(query);
    }
    
    public void SelectKnownIssue()
    {
        string knownIssueId = Apexpages.currentpage().getParameters().get('kIssue');
        c.put(recordTypeName.replace(' ', '') + '__c',knownIssueId);


    }
    
    public void ParseFilter()
    {
        
        filterString = '';
        
        if(searchString !=null)
        {
                String[] filterList = searchString.split(' ',0);
                
                filterString = filterString + ' AND (Subject LIKE \'%' + filterList[0] + '%\'';
                if(filterList.size()>1)
                {
                    filterList.remove(0);
                    
                    for(String s:filterList)
                    {
                        filterString = filterString + ' AND Subject LIKE \'%' + s + '%\'';
                    }
                }
                
                filterString = filterString + ')';
        }
        
        if(knownIssue.ProductImpacted__c != null)
        {
                filterString = filterString + ' AND ProductImpacted__c = \'' + shellCase.ProductImpacted__c + '\'';
        }
        
        Search();
    }
    
    public Case knownIssue
    {
        get
        { 
            Schema.DescribeSObjectResult d = Schema.SObjectType.Case; 
            Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        
            shellCase.RecordTypeId = rtMapByName.get(recordTypeName).getRecordTypeId();
            return shellCase;
        }
        set
        {
        	shellCase = value;	
        }
     }
    
    @RemoteAction
    global static string FindCases(string searchText, string productImpacted, string recordType)
    {        
        Case[] results = new Case[]{};
        List<List<SObject>> searchList = new List<List<SObject>>();
        
        try
        {
            if(productImpacted != '')
            {
                if(searchText.length() <= 1){
                    results = [SELECT Id,CaseNumber, Subject, ProductImpacted__c, PlatformsImpacted__c FROM Case WHERE IsClosed = false AND RecordType.Name = :recordType AND ProductImpacted__c = :productImpacted LIMIT 1000];
                }
                else
                {
                    searchList = [FIND :searchText IN ALL FIELDS
                                                         RETURNING Case (Id,CaseNumber, Subject, ProductImpacted__c, PlatformsImpacted__c WHERE IsClosed = false AND RecordType.Name = :recordType AND ProductImpacted__c = :productImpacted) 
                                                         LIMIT 1000];
                
                    results = (Case[])searchList[0];
                }
            }
            else
            {
                if(searchText != '' && searchText.length() > 1)
                {
                    searchList = [FIND :searchText IN ALL FIELDS
                                                         RETURNING Case (Id,CaseNumber, Subject, ProductImpacted__c, PlatformsImpacted__c WHERE IsClosed = false AND RecordType.Name = :recordType) 
                                                         LIMIT 1000];
                    results = (Case[])searchList[0];
                }
            }
        }
        catch(Exception ex)
        {
            //catches the query not long enough errors
        }
        return json.serialize(results);
    }
    
}