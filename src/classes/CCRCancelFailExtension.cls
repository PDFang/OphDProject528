public class CCRCancelFailExtension 
{
    private final ChangeControlRequest__c ccr;
    private final List<CCRTask__c> CCRTasks;
    private final String ccrType;
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    private final Boolean isMaster;
    public Boolean fail{get;set;}
    private final String displayText;
    public Boolean custImpact{get;set;}
    

    public CCRCancelFailExtension(ApexPages.StandardController controller) 
    {
        //get control information
        this.ccr = (ChangeControlRequest__c)controller.getRecord();
        ccrType = ccr.CCRType__c;
        ccrCont = new CCRControlsClass(ccrType);
        ccrValues = ccrCont.ccrControlRecords;     
        isMaster = ccrCont.IsCCBMasterMember(UserInfo.getUserId()); 
        
        //get tasks
        CCRTasks = [SELECT ID, Status__c FROM CCRTask__c WHERE ChangeControlRequest__c = :ccr.Id];
        
        custImpact = ccrValues.CustomerImpact__c;
        fail = false;
        
        //detemine if this is in an open status
        if(!ccrCont.openStatuses.contains(ccr.Status__c))
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
    }
    
    public PageReference CloseCCR()
    {
        //get current status for later if statements
        string oldStatus = ccr.Status__c;
        
        //update task statuses
        if(!CCRTasks.isEmpty())
        {
            for(CCRTask__c t: CCRTasks)
            {
                if(fail)
                {
                    t.Status__c = 'CCR Failed';
                }
                else
                {
                    t.Status__c = 'Cancelled';
                }
            }
            
            update CCRTasks;
        }
        
        //update ccr status
        if(fail)
        {
            ccr.Status__c = 'CCR Failed';
            
        }
        else
        {
            ccr.Status__c = 'Cancelled';
        }
        
        //update ccr        
        ccr.ClosedDateTime__c = system.now();
        ccr.RecordTypeId = ccrValues.CCRClosedRecordTypeID__c;
        update ccr;
        
        //if task list has already been sent out email
        if(oldStatus != 'Open' && oldStatus != 'CCB Master Review')
        {
            ccrCont.SendTaskEmail(ccr.id, 'You have one or more tasks CANCELLED on');
        }
        
        //return to ccr
        PageReference pr = new ApexPages.StandardController(ccr).view();
        pr.setRedirect(true);
        
        return pr;
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