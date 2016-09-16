public class ChangeRequestHoldExtension {
	
	public BMCServiceDesk__Change_Request__c ccr;
    private final List<BMCServiceDesk__Task__c> CCRTasks;
    private final String ccrType;
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    private final Boolean isMaster;
    private Boolean renderPage = true;
    private Map<String,Id> statusWithId;
    
    public ChangeRequestHoldExtension(ApexPages.StandardController controller) 
    {
    	//get control info
        this.ccr = (BMCServiceDesk__Change_Request__c)controller.getRecord();
        ccrType = 'NetworkNew';
        ccrCont = new CCRControlsClass(ccrType);
        ccrValues = ccrCont.ccrControlRecords;     
        isMaster = ccrCont.IsCCBMasterMember(UserInfo.getUserId()); 
        
        //get tasks
        CCRTasks = [SELECT ID, BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name 
        			FROM BMCServiceDesk__Task__c 
        			WHERE BMCServiceDesk__FKChange__c = :ccr.Id];
        
        //check ccr status
        if(ccr.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('Deployed') || 
           ccr.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('Closed'))
        {
            Invalid();
            renderPage = false;
        }
        statusWithId = CCRControlsClass.StatusName();
    }
	
	//save page and put on hold
    public PageReference Save()
    {
    	//update task statuses
        if(!CCRTasks.isEmpty())
        {
            for(BMCServiceDesk__Task__c t: CCRTasks)
            {
            	if(t.BMCServiceDesk__FKStatus__r.Name!='CANCELLED')
            	{
                	t.BMCServiceDesk__FKStatus__c = statusWithId.get('ON_HOLD')!= null ?
            								   			  statusWithId.get('ON_HOLD'):
            								              '';
            	}
            }
            
            update CCRTasks;
        }
        
        //update ccr status
        ccr.BMCServiceDesk__FKStatus__c = statusWithId.get('ON_HOLD')!= null ?
            							  statusWithId.get('ON_HOLD'):
            							  '';
        ccr.RecordTypeId = ccrValues.NewRecordTypeID__c;
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