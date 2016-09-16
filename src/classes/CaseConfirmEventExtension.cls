public class CaseConfirmEventExtension 
{
    private final Case c;
    public Boolean success {get;set;}
    
    public CaseConfirmEventExtension(ApexPages.StandardController controller) 
    {
        this.c = (Case)controller.getRecord();
        success = false;
    }
    
    public void ConfirmEvent()
    {
        try
        {
            c.Status = 'Confirmed';
            c.IgnoreEventStatusLock__c = true;
            update c;
            success = true;
        }
        catch(DmlException ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
        }
        
    }
    
    public void RejectEvent()
    {
        try
        {
            c.Status = 'Non-Event';
            c.NonEvent__c = true;
            c.IgnoreEventStatusLock__c = true;
            c.OwnerId = '00G70000001ciRa';
            update c;
            success = true;
        }
        catch(DmlException ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
        }
    }
    


}