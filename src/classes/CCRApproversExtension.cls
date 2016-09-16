public class CCRApproversExtension 
{
    
    private final ChangeControlRequest__c ccr;
    private List<CCRApprover__c> ccrApprove;
    private List<User> ccbMembers;
    private ID[] selectedMembers;
    private boolean renderPage = true;
    private final List<CCRTask__c> ccrTasks;
    private final String ccrType;
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    
    
    public CCRApproversExtension(ApexPages.StandardController controller) 
    {
        //get control information
        this.ccr = (ChangeControlRequest__c)controller.getRecord();
        ccrType = ccr.CCRType__c;
        
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
        ccrApprove = [SELECT ID, Approver__c FROM CCRApprover__c WHERE ChangeControlRequest__c = :ccr.Id];
        
        //add any previously selected members to the list
        selectedMembers = new Id[]{};
        if(ccrApprove.size() > 0)
        {
            for(CCRApprover__c c:ccrApprove )
            {
                selectedMembers.add(c.Approver__c);
            }
        } else if(Cache.Session.contains('ccrapprovers'))
        {
           selectedMembers.addAll((Id[])Cache.Session.get('ccrapprovers'));  
        }
        
        //get all the tasks associated to this request
        ccrTasks = [SELECT Id, Status__c FROM CCRTask__c WHERE ChangeControlRequest__c = :ccr.Id AND Status__c <> 'Cancelled'];
    }
    
    //save and approve CCR
    public PageReference Save()
    {
        List<CCRApprover__c> appToDelete = new List<CCRApprover__c>();
        List<CCRApprover__c> newAppList = new List<ccRApprover__c>();
        //Set<Id> existingApprovers = new Set<Id>();
        Set<Id> newApprovers = new Set<Id>();
        
        newApprovers.addAll(selectedMembers);
        
        
        //validations to make sure there are enough tasks
        if(ccr.NumberOfWorkTasks__c == 0 || ccr.NumberOfCommunicationTasks__c == 0 || ccr.NumberOfValidationTasks__c == 0)
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
            c.ChangeControlRequest__c = ccr.Id;
            
            newAppList.add(c);
        }
        
        if(!newAppList.isEmpty())
        {
            insert newAppList;
        }
        
        ApproveCcr();
        Cache.Session.put('ccrapprovers',selectedMembers);
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
        if(ccr.RFCType__c != 'Pre-Authorized')
        {
            return null;
        }
        
        ApproveCcr();
        return GoToCcr();
        
    }
    
    public void ApproveCcr()
    {
        
        //approve all open tasks
        for(CCRTask__c cct: ccrTasks)
        {
           cct.Status__c = 'Approved';
           
        }
        
        update ccrTasks;
        
        //update CCR
        ccr.Status__c = 'Ready For Deployment';
        ccr.RecordTypeId = ccrValues.CCRApprovedRecordTypeID__c;
                
        update ccr;
        
        //send email to task owners
        ccrCont.SendTaskEmail(ccr.id, 'You have one or more APPROVED tasks on');
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