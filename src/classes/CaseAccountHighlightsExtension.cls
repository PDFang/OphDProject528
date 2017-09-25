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