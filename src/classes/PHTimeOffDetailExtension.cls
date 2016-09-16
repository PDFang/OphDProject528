public with sharing class PHTimeOffDetailExtension 
{

    private final Project__c p;
    private List<TimeOffDetail__c> tod;
    private List<TimeOffDetail__c> todToDelete;
    private Id recrdTyp;
    

    public PHTimeOffDetailExtension(ApexPages.StandardController controller) 
    {
        //set the project
        p = (Project__c)controller.getRecord();    
        
        //get time off details
        tod = [SELECT Id, DateRequested__c, EarningCode__c, Hours__c FROM TimeOffDetail__c WHERE Project__c = :p.Id ORDER BY DateRequested__c];
        
        //get time off detail record type based on the project type
        recrdTyp = [SELECT Id FROM RecordType WHERE sObjectType = 'TimeOffDetail__c' AND Name = :p.ProjectType__c LIMIT 1].id;
        
        //initialize list
        todToDelete = new List<TimeOffDetail__c>();

    }
    
    public PageReference Save()
    {
        //check if tod list is empty
        if(!tod.isEmpty())
        {
            //loop through list to check validations.  All displayed fields are required
            for(TimeOffDetail__c t:tod)
            {
                if(t.DateRequested__c == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Date Requested cannot be blank.'));
                    return null;
                }
                
                if(t.EarningCode__c == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Earning Code cannot be NONE.'));
                    return null;
                }
                
                if(t.Hours__c == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Hours cannot be blank.'));
                    return null;
                }
            }
        
            upsert tod;
        }
        
        //check if any records available to delete
        if(!todToDelete.isEmpty())
        {
            delete todToDelete;
        }
        
        //return to project page
        PageReference projectPage = new PageReference('/' + p.Id);
        projectPage.setRedirect(false);
        
        return projectPage;
    }
    
    public PageReference Cancel()
    {
        //return to project page
        PageReference projectPage = new ApexPages.StandardController(p).view();
        projectPage.setRedirect(true);

        return projectPage;    
    }
    
    public void DeleteRow()
    {
        //get index from table        
        integer todId;     
        todId = integer.valueof(ApexPages.currentPage().getParameters().get('todInd'));
    
        //only add to records for deletion if it has an ID
        if(tod[todId].id != null)
        {
            todToDelete.add(tod[todId]);
        }
        
        //remove from time off detail list
        tod.remove(todId);   
    }
    
    public void AddRow()
    {
        //adds row to table
        
        //new tod record
        TimeOffDetail__c t = new TimeOffDetail__c();
        t.Project__c = p.Id;
        t.RecordTypeId = recrdTyp;
     
        tod.Add(t);   
    }
    
    public List<TimeOffDetail__c> TimeOffDetail
    {
        //gets the list for the table
        get
        {
            return tod;
        }
        set
        {
            tod = value;
        }
    }
    
    
}