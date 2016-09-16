public class TfsWorkItemCommentCreateExtension 
{
    public string comment{get;set;}
    private final TfsWorkItem__c workItem;
    public boolean success{get;set;}
    
    public TfsWorkItemCommentCreateExtension(ApexPages.StandardController controller) 
    {
        this.workItem = (TfsWorkItem__c)controller.getRecord();
        success = false;
    }
    
    public void Save()
    {
        
         /*       
        if(comment.length() > 4000)
        {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Comment detail is too long. Detail must be 4000 characters or less.'));
                return ;
        }
		*/
        
        if(comment.length() == 0)
        {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Comment detail is required.'));
                return ;
        }
    
        try
        {
            TfsAccess.AddTfsComment(integer.valueOf(workItem.TFSExternalID__c),comment, workItem.Id);
        
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            inContactBaseClass.SendErrorEmail(ex, workitem.Id );
            return ;
        }
        
        
        success = true;
    }

}