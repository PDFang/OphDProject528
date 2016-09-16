public class TfsWorkItemCreateExtension 
{
    public TfsWorkItem__c workItem {public get; private set;}
    public Case c {public get; private set;}
    public boolean renderPage {public get; private set;}
    private string caseId;
    private final string origCaseStatus;
    public boolean success {get; set;}
   
    
    public TfsWorkItemCreateExtension(ApexPages.StandardController controller) 
    {
        renderPage = true;
        workItem = (TfsWorkItem__c)controller.getRecord();
        GetRelatedCase();
        
        if(c != null)
        {
            origCaseStatus = c.Status;
        }
    }

    private void GetRelatedCase()
    {
        caseId = ApexPages.CurrentPage().getParameters().get('caseId');
        
        if(caseId == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This page must be opened from a Case.  No Case ID found.'));
            renderPage = false;
            return;
        }
        
        try
        {
            c = [SELECT Subject, CaseNumber, Status, Description, RecordTypeId, RecordType.Name, TfsWorkItem__c  FROM Case WHERE Id = :caseId];
        }
        catch(Exception ex)
        {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This page must be opened from a Case.  Case ID is invalid.'));
            renderPage = false;
            return;
        }
        
        if(c.TfsWorkItem__c != null)
        {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This case is already associated to a TFS Bug.'));
            renderPage = false;
            return;
        }
        
        workItem.Title__c = c.Subject;
        workItem.StepsToRecreate__c = c.Description;
    }
    
    public PageReference SaveWorkItem()
    {
        insert workItem;
        c.TfsWorkItem__c = workItem.Id;
        c.Status = 'Engineering Review';
        update c;
        
        return null;
    }
    
    public PageReference CreateTfsItem()
    {
    
        TfsAssignment__c tfsTeam = tfsAssignment__c.getValues('Uptivity Incident');
    
        try
        {
            TfsAccess.CreateTfsItem(workItem.Id, null, null, workItem.StepsToRecreate__c, tfsTeam.Team__c);
            
        }
        catch(Exception ex)
        {
            delete workItem;
            workItem.Id = null;
            
            c.TfsWorkItem__c = null;
            c.Status = origCaseStatus;
            update c;
            
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to create TFS Item.  Please try again later.\r\n' + ex));
            inContactBaseClass.SendErrorEmail(ex, c.Id );
        }
        
        success = true;
        return null;
    }
    
    public PageReference GoToCase()
    {
            
        //return to case page
        PageReference casePage = new PageReference('/' + c.Id);
        casePage.setRedirect(true);
    
        return casePage;
    }
}