public without sharing class CCRCloneExtension 
{
    private final ChangeControlRequest__c ccr;
    private final String ccrType;
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    private final Boolean usesMaintenanceWindow;
    private final Boolean isMaster;
    private List<CCRTask__c> ccrTasks;
    
    public CCRCloneExtension(ApexPages.StandardController controller) 
    {
        //get control information
        this.ccr = (ChangeControlRequest__c)controller.getRecord();
        ccrType = ccr.CCRType__c;
        ccrCont = new CCRControlsClass(ccrType);
        ccrValues = ccrCont.ccrControlRecords;     
        isMaster = ccrCont.IsCCBMasterMember(UserInfo.getUserId());
        usesMaintenanceWindow = ccrValues.MaintenanceWindow__c;
        
        //get tasks
        ccrTasks = [SELECT RecordTypeId, Order__c, AssignedTo__c, Description__c, TaskDateTime__c, Duration__c FROM CCRTask__c WHERE ChangeControlRequest__c = :ccr.id ORDER BY Order__c]; 
        for(CCRTask__c t: ccrTasks)
        {
            //remove fields not to clone
            t.TaskDateTime__c = null;
        }
        
        //remove fields not to clone
        ccr.ReleaseDate__c = null;
        ccr.CCRStartTime__c = null;
        ccr.MaintenanceWindowStartTime__c = null;
        ccr.MaintenanceWindowEndTime__c = null;
        ccr.ContingencyDeadline__c = null;
        ccr.Build__c = null;
    }
    
    //deletes new tasks added
    public void DeleteRow()
    {
        //get index from table        
        integer tlId;     
        tlId = integer.valueof(ApexPages.currentPage().getParameters().get('tlInd'));
        
        //update the order
        for(integer i=tlId;i<ccrTasks.size();i++)
        {
            ccrTasks[i].Order__c = ccrTasks[i].Order__c -1;
        }
        
            
        //remove from task list
        ccrTasks.remove(tlId);   
        
    }
    
    //save newly cloned ccr
    public PageReference Save()
    {
        //do validations on all tasks
        for(CCRTask__c ccrt:ccrTasks)
        {
            if(ccrt.AssignedTo__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Assigned To field cannot be blank.'));
                return null;
            }
            
            if(ccrt.Description__c == null || ccrt.Description__c == '')
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Description field cannot be blank.'));
                return null;
            }
            
            if(ccrt.TaskDateTime__c == null && ccrt.Duration__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Must fill out either a Task Date/Time or Duration.'));
                return null;
            }
        }
        
        //clone ccr
        ChangeControlRequest__c ccrClone = new ChangeControlRequest__c();
        ccrClone = ccr.Clone();
        ccrClone.Status__c = 'Open';
        ccrClone.RecordTypeId = ccrValues.NewRecordTypeID__c;
        
        insert ccrClone;
        
        //clone tasks
        List<CCRTask__c> taskClone = new List<CCRTask__c>();
        
        for(CCRTask__c t: ccrTasks)
        {
            CCRTask__c nTask = new CCRTask__c();
            nTask = t.clone();
            nTask.ChangeControlRequest__c = ccrClone.id;
            nTask.Status__c = 'Open';
            
            taskClone.add(nTask);
        }
        
        if(!taskClone.isEmpty())
        {
            insert taskClone;
        }
    
        //return to ccr page
        PageReference ccrPage = new PageReference('/' + ccrClone.Id);
        ccrPage.setRedirect(true);
        
        return ccrPage;
    }
    
    public List<CCRTask__c> CCRTaskList
    {
        //used for ccr task table on vf page
        get{return ccrTasks;}
        set{ccrTasks=value;}
    }
    
    public List<selectOption> TaskAssignee
    {//list of all active users for task assignto field
            get 
            {
                    //new list for holding all of the picklist options
                    List<SelectOption> options = new List<SelectOption>();
                    options.add(new selectOption('', '- Select a User -')); 
                    
                    for(User u: [SELECT Id, Name FROM User WHERE UserType = 'Standard' and IsActive = true ORDER BY Name])
                    {
                        options.add(new selectOption(u.Id, u.Name)); 
                    
                    }
                                             
                    return options;
            } 
    }
    
    //used to determine if it should show the maintenance window information
    public Boolean UseMaintenanceWindow
    {
        get{return usesMaintenanceWindow;}
    }

}