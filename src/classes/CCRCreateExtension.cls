public class CCRCreateExtension 
{
    private ChangeControlRequest__c ccr;
    public final String ccrType{get;set;}
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    private final Boolean usesMaintenanceWindow;
    private final Boolean usesClusterAndRelease;
    private Boolean isClone;
    private List<CCRTask__c> ccrTasks;
    private final ApexPages.StandardController baseController;
    private String[] caseReleaseVals;
    public boolean isPSCCR{get; set;}
    
    public CCRCreateExtension(ApexPages.StandardController controller) 
    {
        baseController = controller;
        this.ccr = (ChangeControlRequest__c)controller.getRecord();
        isClone = ApexPages.CurrentPage().getParameters().get('clone') == '1';
        string recordtypeId = ApexPages.CurrentPage().getParameters().get('RecordType');
        
        if(recordtypeId == '01270000000QDB4')
            isPSCCR = true;
        else
            isPSCCR = false;
        if(isClone)
        {
            ccr.CCRStartTime__c = null;
            ccr.ReleaseDate__c = null;
            ccr.Build__c = null;
            ccr.MaintenanceWindowEndTime__c = null;
            ccr.MaintenanceWindowStartTime__c = null;
            ccr.ContingencyDeadline__c = null;
            ccr.ContingencyOwner__c = null;
            
            if(ccr.PreAuthorizedTemplate__c){
                ccr.RFCType__c = 'Pre-Authorized';
            }
            
            //get tasks
            ccrTasks = [SELECT RecordTypeId, Order__c, AssignedTo__c, Description__c, TaskDateTime__c, Duration__c FROM CCRTask__c WHERE ChangeControlRequest__c = :ccr.id ORDER BY Order__c]; 
            for(CCRTask__c t: ccrTasks)
            {
                //remove fields not to clone
                t.TaskDateTime__c = null;
            }
            
            ccr.Id = null;
        }
        else
        {
            ChangeControlRequest__c defaults = (ChangeControlRequest__c)ChangeControlRequest__c.sObjectType.newSObject(ccr.RecordTypeId, true);
            ccr.CCRType__c = defaults.CCRType__c;
        }
        
        
        ccrType = ccr.CCRType__c;
        ccrCont = new CCRControlsClass(ccrType);
        ccrValues = ccrCont.ccrControlRecords; 
        usesMaintenanceWindow = ccrValues.MaintenanceWindow__c;
        usesClusterAndRelease = ccrValues.Cluster_and_Release__c;
    }
    
    //save newly cloned ccr
    public PageReference Save()
    {
        if(isClone)
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
            ccr.Status__c = 'Open';
            ccr.RecordTypeId = ccrValues.NewRecordTypeId__c;
            if(ccr.PreAuthorizedTemplate__c)
            {
                ccr.TemplateCcr__c = ApexPages.CurrentPage().getParameters().get('id');            
                ccr.PreAuthorizedTemplate__c = false;
            }
        }
        
        //clone ccr
        //baseController.Save();
        //this.ccr = (ChangeControlRequest__c)baseController.getRecord();
        
        try
        {
            
            insert ccr;
        }
        catch(DmlException ex)
        {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
                return null;
        }
    
        if(isClone)
        {
            //clone tasks
            List<CCRTask__c> taskClone = new List<CCRTask__c>();
            
            for(CCRTask__c t: ccrTasks)
            {
                CCRTask__c nTask = new CCRTask__c();
                nTask = t.clone();
                nTask.ChangeControlRequest__c = ccr.id;
                nTask.Status__c = 'Open';
                
                taskClone.add(nTask);
            }
            
            if(!taskClone.isEmpty())
            {
                try
                {
                    insert taskClone;
                }
                catch(DmlException ex)
                {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
                        return null;
                }
            }
        }
        
        if(ApexPages.currentPage().getParameters().get('caseId') != NULL)
        {
            CCRLinks__c link = new CCRLinks__c();
            link.ChangeControlRequest__c = ccr.Id;
            link.Case__c = ApexPages.currentPage().getParameters().get('caseId');
            
            try
            {
                insert link;
            }
            catch(DmlException ex)
            {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
                        return null;
            }
        }
        
        if(ApexPages.currentPage().getParameters().get('projectId') != NULL)
        {
            CCRLinks__c link = new CCRLinks__c();
            link.ChangeControlRequest__c = ccr.Id;
            link.Project__c = ApexPages.currentPage().getParameters().get('projectId');
            
            try
            {
                insert link;
            }
            catch(DmlException ex)
            {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
                        return null;
            }
        }
        
        
        //return to ccr page
        PageReference ccrPage = new PageReference('/' + ccr.Id);
        ccrPage.setRedirect(true);
        
        return ccrPage;
    }

    
    //deletes new tasks added
    public void DeleteRow()
    {
        //get index from table        
        integer tlId;     
        tlId = integer.valueof(ApexPages.currentPage().getParameters().get('tlInd'));
              
            
        //remove from task list
        ccrTasks.remove(tlId); 
          
        //update the order
        for(integer i=0;i<ccrTasks.size();i++)
        {
            ccrTasks[i].Order__c = i + 1;
        }
        
    }
    
    public List<CCRTask__c> CCRTaskList
    {
        //used for ccr task table on vf page
        get{return ccrTasks;}
        set{ccrTasks=value;}
    }
    
    public string ReleaseValues
    {
        get { 
                
            try
            {
                caseReleaseVals = TfsAccess.TfsReleaseValues();
            }
            catch(Exception ex)
            {
                
                caseReleaseVals = new String[]{};
                inContactBaseClass.SendErrorEmail(ex,ccr.Id);
            }
            return JSON.serializePretty(caseReleaseVals);
        }
    }
    
    public Boolean UseMaintenanceWindow
    {
        get{return usesMaintenanceWindow;}
    }
    
    
    public Boolean UseClusterAndRelease
    {
        get{return usesClusterAndRelease;}
    }
    
    public Boolean IsCloneRecord
    {
        get{return isClone;}
    }
}