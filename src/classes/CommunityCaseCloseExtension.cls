public class CommunityCaseCloseExtension 
{
    private CaseComment comment;
    private ApexPages.StandardController control;
    public Case c {public get;private set;}
    

    public CommunityCaseCloseExtension(ApexPages.StandardController controller) 
    {
        control = controller;
        comment = (CaseComment)controller.getRecord();
        string caseId = ApexPages.currentPage().getParameters().get('parent_id');
        c = [SELECT Subject, Description, CaseNumber, Status, IsClosed, Id FROM Case WHERE Id = :caseId];
        
        if(c.IsClosed)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This Case is already closed.  Please open a new case if you have any outstanding issues.'));
        }
        
        comment.ParentId = caseId;
        comment.IsPublished = true;
    }
    
    public PageReference Save()
    {
        
        insert comment;
    
        c.Disposition__c = 'Customer Closed';
        c.Status = 'Closed';
        
        update c;
        
        //return to case page
        PageReference casePage = new PageReference('/' + c.Id);
        casePage.setRedirect(true);
        
        return casePage;
    }
    
    public PageReference Cancel()
    {
        
        //return to case page
        PageReference casePage = new PageReference('/' + c.Id);
        casePage.setRedirect(true);
        
        return casePage;
    }
 
}