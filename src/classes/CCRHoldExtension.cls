public class CCRHoldExtension 
{
    private final ChangeControlRequest__c ccr;
    private final List<CCRTask__c> CCRTasks;
    private final String ccrType;
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    private final Boolean isMaster;
    private Boolean renderPage = true;
    
    
    public CCRHoldExtension(ApexPages.StandardController controller) 
    {
    	//get control info
        this.ccr = (ChangeControlRequest__c)controller.getRecord();
        ccrType = ccr.CCRType__c;
        ccrCont = new CCRControlsClass(ccrType);
        ccrValues = ccrCont.ccrControlRecords;     
        isMaster = ccrCont.IsCCBMasterMember(UserInfo.getUserId()); 
        
        //get tasks
        CCRTasks = [SELECT ID, Status__c FROM CCRTask__c WHERE ChangeControlRequest__c = :ccr.Id];
        
        //check ccr status
        if(ccr.Status__c != 'Board Review')
        {
            Invalid();
            renderPage = false;
        }
        
    }
	
	//save page and put on hold
    public PageReference Save()
    {
    	//update task statuses
        if(!CCRTasks.isEmpty())
        {
            for(CCRTask__c t: CCRTasks)
            {
            	if(t.Status__c!='Cancelled')
            	{
                	t.Status__c = 'On Hold';
            	}
            }
            
            update CCRTasks;
        }
        
        //update ccr status
        ccr.Status__c = 'On Hold';
        update ccr;
        
        //go back to ccr
        PageReference pr = new ApexPages.StandardController(ccr).view();
        pr.setRedirect(true);
        
        return pr;
    }
    
    //returns error if invalid to put on hold
    public PageReference Invalid()
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This CCR is in an invalid status to put on HOLD.'));
        return null;  
    }
    
    //tells vf page whether to render or not
    public Boolean RenderPageInfo
    {
        get{return renderPage;}
    }
    
}