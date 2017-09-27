public with sharing class CaseAccountHighlightsExtension 
{
    private final Case c;
    public String target{get;set;}
    public string URLForPage{public get;private set;}

    public CaseAccountHighlightsExtension(ApexPages.StandardController controller) 
    {
        this.c = [Select Id, Subject, JIRA_Description__c, Summary__c, Steps_to_Recreate__c, InternalNotes__c from Case where Id = :controller.getId()];
        URLForPage = ApexPages.currentPage().getHeaders().get('Host');
    }
    
    public void CreateJIRABug() {
        try {
            system.debug('CreateJIRABug(): case -  ' + c);

            c.JIRA_Description__c = 'Summary\n' + c.Summary__c
                    + '\n\nSteps to Recreate\n' + c.Steps_to_Recreate__c
                    + '\n\nInternal Notes\n' + c.InternalNotes__c;
            c.JIRA_Summary__c = c.Subject;
            c.JIRA_Key__c = CaseTriggerHandler.JIRA_KEY_TEMP;
            CaseTriggerHandler.createJiraBug = true;
            update c;

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