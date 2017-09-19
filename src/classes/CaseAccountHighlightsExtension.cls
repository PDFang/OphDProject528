public with sharing class CaseAccountHighlightsExtension 
{
    private final Case c;
    public String target{get;set;}
    public string URLForPage{public get;private set;}

    public CaseAccountHighlightsExtension(ApexPages.StandardController controller) 
    {
        this.c = (Case)controller.getRecord();
        URLForPage = ApexPages.currentPage().getHeaders().get('Host');
    }
    
    public void CreateTfsItem()
    {
        
        TfsWorkItem__c workItem = new TfsWorkItem__c();
        workItem.Name = 'Processing...';
        workItem.Description__c = c.Summary__c;
        workItem.StepsToReproduce__c = c.Steps_to_Recreate__c;
        workItem.Title__c = c.Subject;
        workItem.FoundBy__c = c.FoundBy__c;
        workItem.ExistsIn__c = c.ExistsIn__c;
        insert workItem;
        
        try
        {
            TfsAccess.CreateTfsItem(workItem.Id, c.Summary__c, c.InternalNotes__c, c.Steps_to_Recreate__c,'inContact');
            c.TFSWorkItem__c = workItem.Id;
            update c;
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            inContactBaseClass.SendErrorEmail(ex,c.Id);
        }
    }

    public void CreateJIRABug() {
        try {
            JiraRestWrapper wrapper = new JiraRestWrapper();
            String jiraKey = wrapper.CreateJIRABug(c.Id);
            system.debug('Bug ' + jiraKey + ' created successfully.');
        }
        catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            inContactBaseClass.SendErrorEmail(ex,c.Id);
        }
    }

    
    public PageReference Save()
    {
        
        //return to case page
        PageReference casePage = new PageReference('/' + c.Id);
        casePage.setRedirect(true);
        
        return casePage;
    
    }

}