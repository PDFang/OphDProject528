public class ChangeRequestApproversExtensions {
    public BMCServiceDesk__Change_Request__c ccr;
    private List<CCRApprover__c> ccrApprove;
    private List<User> ccbMembers;
    private ID[] selectedMembers;
    private boolean renderPage = true;
    private final List<BMCServiceDesk__Task__c> ccrTasks;
    private final String ccrType;
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    private Map<String,Id> statusWithId;
    
    public ChangeRequestApproversExtensions(ApexPages.StandardController controller) 
    {
        //get control information
        this.ccr = (BMCServiceDesk__Change_Request__c)controller.getRecord();
        this.ccr = [Select Id,BMCServiceDesk__Change_Type__c,PreAuthorizedTemplate__c,RecordTypeId,BMCServiceDesk__FKStatus__c,
        				   BMCServiceDesk__FKStatus__r.Name,RF_Risk_Level__c,OwnerId 
        			from BMCServiceDesk__Change_Request__c 
         			where Id=:ccr.Id];
        ccrType = 'NetworkNew';
        
        ccrCont = new CCRControlsClass(ccrType);
        ccrValues = ccrCont.ccrControlRecords;
                
        //check if part of CCB Masters group        
        if(!ccrCont.IsCCBMasterMember(UserInfo.getUserId()))
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must be in the CCB Masters group to approve a CCR.'));
            renderPage = false;
        }
        else
        {
            renderPage = true;
        }
        
        //get list of Change control board 
        ccbMembers= [SELECT Id, Name FROM User WHERE Id IN(SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :ccrValues.CCBMembersGroupId__c) ORDER BY Name];
        
        
        //find any current approvers
        CCRApprover__c[] ccrA = new CCRApprover__c[]{};
        ccrApprove = [SELECT ID, Approver__c FROM CCRApprover__c WHERE RF_Change_Request__c = :ccr.Id];
        //add any previously selected members to the list
        selectedMembers = new Id[]{};
        if(ccrApprove.size() > 0)
        {
            for(CCRApprover__c c:ccrApprove )
            {
                selectedMembers.add(c.Approver__c);
            }
        }
        statusWithId = CCRControlsClass.StatusName();
        //get all the tasks associated to this request
        ccrTasks = [SELECT Id, BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name 
        			FROM BMCServiceDesk__Task__c 
        			WHERE BMCServiceDesk__FKChange__c = :ccr.Id AND BMCServiceDesk__FKStatus__r.Name <> 'CANCELLED'];
    }
    
    //save and approve CCR
    public PageReference Save()
    {
        List<CCRApprover__c> appToDelete = new List<CCRApprover__c>();
        List<CCRApprover__c> newAppList = new List<CCRApprover__c>();
        //Set<Id> existingApprovers = new Set<Id>();
        Set<Id> newApprovers = new Set<Id>();
        
        newApprovers.addAll(selectedMembers);
        ApexPages.StandardController controller = new ApexPages.StandardController(ccr);
        changeRequestSubmitButton submitButtonClass = new changeRequestSubmitButton(controller);
        submitButtonClass.calculateTask(ccr.Id);
        //validations to make sure there are enough tasks
        if(submitButtonClass.taskNameCountMap.get('Validation Task') == 0 || 
        	submitButtonClass.taskNameCountMap.get('Communication Task') == 0 || 
        	submitButtonClass.taskNameCountMap.get('Work Task') == 0)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'At least one of each task type is required. Work, Validation, and Communication.'));
            return null;
        }
        //validations to make sure there are enough approvers       
        if(newApprovers.size() < ccrValues.NumberOfApproversRequired__c)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must have at least ' + ccrValues.NumberOfApproversRequired__c + ' approvers for a CCR.'));
            return null;
        }
        //find any existing approvers to delete
        if(ccrApprove.size() > 0)
        {
        
            for(CCRApprover__c ccrA: ccrApprove)
            {
               if(newApprovers.contains(ccrA.Approver__c))
               {
                   //get existing users left so new record is not created
                   newApprovers.remove(ccrA.Approver__c);
               }
               else
               {
                   appToDelete.add(ccrA);
               }
            }
            
            if(appToDelete.size() > 0)
            {
                delete appToDelete;
            }
        }
        
        //remove existing users before saving
        //newApprovers.removeAll(existingApprovers);
        
        
        for(Id newApp:newApprovers )
        {
            CCRApprover__c c = new CCRApprover__c();
            c.Approver__c = newApp;
            c.RF_Change_Request__c = ccr.Id;
            c.ChangeControlRequest__c = CCRControlsClass.ChangeControlRequestId();
            
            newAppList.add(c);
        }
        
        if(!newAppList.isEmpty())
        {
            insert newAppList;
        }
        
        ApproveCcr();
        return GoToCcr();
    }
    
    public boolean SetTemplate
    {
        get
        {
            return ccr.PreAuthorizedTemplate__c;
        }
        set
        {
            ccr.PreAuthorizedTemplate__c = value;
        }
    }
    
    public PageReference Initialize()
    {
        if(ccr.BMCServiceDesk__Change_Type__c != 'PRE-AUTHORIZED')
        {
            return null;
        }
        
        ApproveCcr();
        return GoToCcr();
        
    }
    
    public void ApproveCcr()
    {
        
        //approve all open tasks
        for(BMCServiceDesk__Task__c cct: ccrTasks)
        {
           cct.BMCServiceDesk__FKStatus__c = statusWithId.get('APPROVED')!= null ?
            								   			  statusWithId.get('APPROVED'):
            								              '';
           
        }
        
        update ccrTasks;
        
        //update CCR
        ccr.BMCServiceDesk__FKStatus__c = statusWithId.get('READY FOR DEPLOYMENT')!= null ?
								   			   statusWithId.get('READY FOR DEPLOYMENT'):
								               '';
        ccr.RecordTypeId = ccrValues.CCRApprovedRecordTypeID__c;
        ccr.BMCServiceDesk__Review_Date__c = system.now();
        ccr.BMCServiceDesk__TemplateName__c = 'RF_Status Update for Ready for Deployment';
                
        update ccr;
        
        //send email to task owners
        ccrCont.SendTaskEmailForRfChangeRequest(ccr.id, 'You have one or more APPROVED tasks on');
    }
    
    public PageReference GoToCcr()
    {
        PageReference ccrPage = new PageReference('/' + ccr.Id);
        ccrPage.setRedirect(true);
        
        return ccrPage;
        
    }
    
    //list of all approvers
    public List<SelectOption> Approvers 
    {
        get
        {
            List<SelectOption> options = new List<SelectOption>();
            
            for(User u:ccbMembers)
            {
                options.add(new SelectOption(u.Id,u.Name));
            }
    
            return options;
        }
    }
    
    
    //list of selected approvers
    public Id[] SelectedApprovers
    {
        get
        {
            return selectedMembers;
        }
        set
        {
            selectedMembers = value;
        }
    }
    
    //to determine if the page should be rendered
    public Boolean Rendered
    {
        get{return renderPage;}
    }
    
}