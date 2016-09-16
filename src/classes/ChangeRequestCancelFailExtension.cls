public with sharing class ChangeRequestCancelFailExtension {
	private  final BMCServiceDesk__Change_Request__c ccr;
    private final List<BMCServiceDesk__Task__c> CCRTasks;
    private final String ccrType;
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    private final Boolean isMaster;
    public Boolean fail{get;set;}
    private final String displayText;
    public Boolean custImpact{get;set;}
    private Map<String,Id> statusWithId;

    public ChangeRequestCancelFailExtension(ApexPages.StandardController controller) 
    {
        //get control information
        this.ccr = (BMCServiceDesk__Change_Request__c)controller.getRecord();
        ccrType = 'NetworkNew';
        ccrCont = new CCRControlsClass(ccrType);
        ccrValues = ccrCont.ccrControlRecords;     
        isMaster = ccrCont.IsCCBMasterMember(UserInfo.getUserId()); 
        
        //get tasks
        CCRTasks = [SELECT ID, BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name 
        			FROM BMCServiceDesk__Task__c 
        			WHERE BMCServiceDesk__FKChange__c = :ccr.Id];
        
        custImpact = ccrValues.CustomerImpact__c;
        fail = false;
        //detemine if this is in an open status
        if(ccr.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('READY FOR DEPLOYMENT'))
        {
            fail = true;
        }
        
        //detemine display text for vf page
        if(fail)
        {
            displayText = 'Are you sure you want to close this CCR as FAILED?';
        }
        else
        {
            displayText = 'Are you sure you want to CANCEL this CCR';
        }
        statusWithId = CCRControlsClass.StatusName();
    }
    
    public PageReference CloseCCR()
    {
        //get current status for later if statements
        string oldStatus = ccr.BMCServiceDesk__FKStatus__r.Name;
        boolean CCRexception = false;
        
        //update task statuses
        if(!CCRTasks.isEmpty())
        {
            for(BMCServiceDesk__Task__c t: CCRTasks)
            {
                if(fail)
                {
                    t.BMCServiceDesk__FKStatus__c = statusWithId.get('CCR FAILED')!= null ?
            								   			  statusWithId.get('CCR FAILED'):
            								              '';
                }
                else
                {
                    t.BMCServiceDesk__FKStatus__c = statusWithId.get('CANCELLED')!= null ?
            								   			  statusWithId.get('CANCELLED'):
            								              '';
                }
            }
            try{
            update CCRTasks;
            }
            catch(Exception e){
            	CCRexception = true;
            	 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,e.getMessage()));
            	
            }
        }
        
        //update ccr status
        if(fail)
        {
            ccr.BMCServiceDesk__FKStatus__c = statusWithId.get('CCR FAILED')!= null ?
            								   			  statusWithId.get('CCR FAILED'):
            								              '';
            
        }
        else
        {
            ccr.BMCServiceDesk__FKStatus__c = statusWithId.get('CANCELLED')!= null ?
							   			    statusWithId.get('CANCELLED'):
							                '';
        }
        
        //update ccr        
        ccr.BMCServiceDesk__Closed_Date_Time__c = system.now();
        ccr.RecordTypeId = ccrValues.CCRClosedRecordTypeID__c;
        try{
        	update ccr;
        }
        catch(Exception e){
        	system.debug('Inside exception'+e.getMessage());
        	CCRexception= true;
        	 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,e.getMessage()));
        }
        
        
        //if task list has already been sent out email
        if(oldStatus != 'OPENED' && oldStatus != 'ADMINISTRATOR REVIEW')
        {
            ccrCont.SendTaskEmailForRfChangeRequest(ccr.id, 'You have one or more tasks CANCELLED on');
        }
        
        //return to ccr
        if(!CCRexception){
        	PageReference pr = new ApexPages.StandardController(ccr).view();
        	pr.setRedirect(true);
        	return pr;
        }
        else{
        	Return Null;
        }
    }
    
    public PageReference Cancel()
    {
        //return to CCR
        PageReference pr = new ApexPages.StandardController(ccr).view();
        pr.setRedirect(false);
        
        return pr;
    }
    
    public String DisplayString
    {
        //return display text
        get{return displayText;}
    }  
}