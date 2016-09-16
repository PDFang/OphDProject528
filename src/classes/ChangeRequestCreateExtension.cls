public class ChangeRequestCreateExtension {
    
    private BMCServiceDesk__Change_Request__c ccr;
    public final String ccrType{get;set;}
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    private final Boolean usesMaintenanceWindow;
    private Boolean isClone;
    private List<BMCServiceDesk__Task__c> ccrTasks;
    private final ApexPages.StandardController baseController;
    private String[] caseReleaseVals;
    private Map<String,Id> statusWithId;
    
    
    public ChangeRequestCreateExtension(ApexPages.StandardController controller) 
    {
        baseController = controller;
        this.ccr = (BMCServiceDesk__Change_Request__c)controller.getRecord();
        
        isClone = ApexPages.CurrentPage().getParameters().get('clone') == '1';
        ccrType = 'NetworkNew';
        ccrCont = new CCRControlsClass(ccrType);
        ccrValues = ccrCont.ccrControlRecords; 
        usesMaintenanceWindow = ccrValues.MaintenanceWindow__c;
        statusWithId = CCRControlsClass.StatusName();
        if(isClone)
        {
            ccr.RF_CCR_Start_Time__c = null;
            ccr.RF_Release_Date__c = null;
            ccr.RF_Maint_Window_End_Time__c = null;
            ccr.RF_Maint_Window_Start_Time__c  = null;
            ccr.RF_Contingency_Deadline__c = null;
            ccr.RF_Contingency_Owner__c = null;
            if(ccr.PreAuthorizedTemplate__c){
                ccr.BMCServiceDesk__Change_Type__c = 'PRE-AUTHORIZED';
            }
            
            //get tasks
            ccrTasks = [SELECT  BMCServiceDesk__templateOrder__c, BMCServiceDesk__FKOpenBy__c,RF_Task_Type__c, 
            				    BMCServiceDesk__taskDescription__c, BMCServiceDesk__dueDateTime__c,
            				    BMCServiceDesk__duration__c FROM BMCServiceDesk__Task__c WHERE BMCServiceDesk__FKChange__c = :ccr.id ORDER BY BMCServiceDesk__templateOrder__c]; 
            for(BMCServiceDesk__Task__c t: ccrTasks)
            {
                //remove fields not to clone
                t.BMCServiceDesk__dueDateTime__c = null;
            }
            ccr.Id = null;
        }
        else
        {
            BMCServiceDesk__Change_Request__c defaults = (BMCServiceDesk__Change_Request__c)BMCServiceDesk__Change_Request__c.sObjectType.newSObject(ccrValues.NewRecordTypeId__c, true);
            ccr.RecordTypeId = defaults.RecordTypeId;
        }
    }
    
    //save newly cloned ccr
    public PageReference Save()
    {
        if(isClone)
        {
            //do validations on all tasks
            for(BMCServiceDesk__Task__c ccrt:ccrTasks)
            {
                if(ccrt.BMCServiceDesk__FKOpenBy__c == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Assigned To field cannot be blank.'));
                    return null;
                }
            
                if(ccrt.BMCServiceDesk__taskDescription__c == null || ccrt.BMCServiceDesk__taskDescription__c == '')
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Description field cannot be blank.'));
                    return null;
                }
            
                if(ccrt.BMCServiceDesk__dueDateTime__c == null && ccrt.BMCServiceDesk__duration__c == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Must fill out either a Task Date/Time or Duration.'));
                    return null;
                }
            }
            ccr.BMCServiceDesk__FKStatus__c = statusWithId.get('OPENED')!= null ?
							   			    statusWithId.get('OPENED'):
							                '';
            ccr.RecordTypeId = ccrValues.NewRecordTypeId__c;
            ccr.BMCServiceDesk__FKUrgency__c = CCRControlsClass.urgencyName(ccr.UrgencyPicklist__c);
            ccr.BMCServiceDesk__FKImpact__c = CCRControlsClass.ImpactName(ccr.ImpactPicklist__c);
            if(ccr.PreAuthorizedTemplate__c)
            {
                ccr.TemplateCCR__c = ApexPages.CurrentPage().getParameters().get('id');            
                ccr.PreAuthorizedTemplate__c = false;
            }
        }
        else{
        	ccr.BMCServiceDesk__FKUrgency__c = CCRControlsClass.urgencyName(ccr.UrgencyPicklist__c);
            ccr.BMCServiceDesk__FKImpact__c = CCRControlsClass.ImpactName(ccr.ImpactPicklist__c);
        }
		
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
            List<BMCServiceDesk__Task__c> taskClone = new List<BMCServiceDesk__Task__c>();
            
            for(BMCServiceDesk__Task__c t: ccrTasks)
            {
                BMCServiceDesk__Task__c nTask = new BMCServiceDesk__Task__c();
                nTask = t.clone();
                nTask.BMCServiceDesk__FKChange__c = ccr.id;
                nTask.BMCServiceDesk__FKStatus__c = statusWithId.get('OPENED')!= null ?
							   			    statusWithId.get('OPENED'):
							                '';
                
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
            ccrTasks[i].BMCServiceDesk__templateOrder__c = i + 1;
        }
       
    }
    
   		 public List<BMCServiceDesk__Task__c> CCRTaskList{
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
    
    public Boolean IsCloneRecord
    {
        get{return isClone;}
    }
}