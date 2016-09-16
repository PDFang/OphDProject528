public with sharing class CaseReassignExtension 
{
    public Case c{get; Set;}
    private Id crtQueue;
    private boolean isCrtAssignProfile;
    //public Id selectedUser {get;set;}
    public Id selectedQueue {get;set;}
    public boolean isPublicComment {get;set;}
    public boolean isCrt {public get; private set;}
    public string commentBody {get;set;}
    public String assignBy {get;set;}
    public List<Group> usersQueues {public get; private set;}
    private List<User> userList;
    private List<Group> allCaseQueues;
    // 27626 - Request to Modify Incident Reassign VF Page/Quick Action
    // Added three new fields and combined them all in one Comment.
    // Only apply changes for Incident record type or Incident-uptivity record type.
    public String troubleshootingSteps{get; Set;}
    public string stReason{get;Set;}
    public string stRequestedAction{get;Set;}
    public String caseRecordtyp{get;Set;} 
    public boolean isvisibleComment{get; Set;}
    public string URLForPage{get; Set;}

    public CaseReassignExtension(ApexPages.StandardController controller) 
    {
        
        URLForPage = ApexPages.currentPage().getHeaders().get('Host'); 
        this.c = (Case)controller.getRecord();
        userList = new List<User>([SELECT Id, Name FROM User WHERE IsActive = true AND UserType = 'Standard' ORDER BY Name]);
        allCaseQueues = new List<Group>([SELECT Id, Name FROM Group WHERE ID IN(SELECT QueueId FROM QueueSobject WHERE SobjectType = 'Case') ORDER BY Name]);
        isCrt = false;
        
        isCrtAssignProfile = ProfileSiteConfiguration__c.getInstance().AssignToCrtQueue__c;
        caseRecordtyp = [select RecordType.Name from Case where Id = :c.Id].RecordType.Name;
        isvisibleComment = true;
       if (caseRecordtyp == 'Incident' || caseRecordtyp == 'Incident - Premise') // Chnage Uptivity to premise
            isvisibleComment = false;

        for(integer i=0;i<allCaseQueues.size();i++)
        {
            Group g = allCaseQueues[i];
            
            if(g.Name == 'Sustaining Engineering Queue')
            {
                if(!isCrtAssignProfile)
                {
                    allCaseQueues.remove(i);
                }    
                crtQueue = g.Id;
            }
        }
        
        assignBy = 'Queue';
        c.Assigned_To__c = NULL;
    }
    
    
        public PageReference PublisherSave()
        {
            SaveReassign();
            selectedQueue = null;
            isPublicComment = false;
            commentBody = null;
            isCrt = false;
            c.WorkDuration__c = null;
            return null;
        }
    
    public PageReference Save()
    {
        SaveReassign();
        
        if(ApexPages.hasMessages())
        {
            return null;
        }
        //return to case page
        PageReference casePage = new PageReference('/' + c.Id);
        
        return casePage;
    }
    
    public void SaveReassign()
    {
    
        if(isCrt)
        {
            if(c.CrtRequestType__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Sustaining Engineering Request Type is required.'));
                return;
            }
            
            if(c.AgentAccountable__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Agent Accountable is required.'));
                return;
            }
        }
    
        if(assignBy == 'User')
        {
            if(c.Assigned_To__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'User is required.'));
                return;
            }
            
        }
        else
        {
            c.Assigned_To__c = NULL;
        }
        
        if(selectedQueue == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Queue is required.'));
            return;
        }
    
        c.OwnerId = selectedQueue;
        
        if ((commentBody == null || commentBody == '') && isvisibleComment)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Comment is required.'));
            return;
        }
        
        // added as per 27626
        if((troubleshootingSteps == null || troubleshootingSteps == '') && !isvisibleComment)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Troubleshooting Steps Taken is required.'));
            return;
        }

        if((stReason == null || stReason == '') && !isvisibleComment)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Reason for Case Transfer is required.'));
            return;
        }
        
        if((stRequestedAction == null || stRequestedAction == '') && !isvisibleComment)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Requested Action(s) is required.'));
            return;
        }

        
        CaseComment cc = new CaseComment();
        if (isvisibleComment) // Per project 27626
            cc.CommentBody = commentBody;
        else
            cc.CommentBody = 'Troubleshooting Steps Taken : ' + troubleshootingSteps + '\r\n' + 'Reason for Case Transfer : '
                            + stReason + '\r\n' + 'Requested Action(s) : ' + stRequestedAction; // As per Project - 27626 
        cc.IsPublished = isPublicComment;
        cc.ParentId = c.Id;
        
        try
        {
            update c;
            insert cc;
        }
        catch(DmlException ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
            return;
        }    
        
    }
    
    public List<SelectOption> ActiveUsers
    {
        
        
        get
        {
            List<User> users = userList;
        
            List<SelectOption> options = new List<SelectOption>(); 
            options.add(new SelectOption('','None')); 
            
            for(User u: users)
            {
                options.add(new SelectOption(u.Id, u.Name));
            }
            return options; 
        }
       
    }
    
    public List<SelectOption> AvailableQueues
    {
        get
        {
            List<Group> groups = new List<Group>();
            
            List<SelectOption> options = new List<SelectOption>(); 
                options.add(new SelectOption('','None')); 
            
            if(assignBy == 'Queue')
            {
                groups = allCaseQueues;
            }
            else
            {
        
                if(c.Assigned_To__c != null)        
                {
                    groups = usersQueues ;
                    
                    
                }
            }
            
            
            for(Group g: groups)
            {
                options.add(new SelectOption(g.Id, g.Name));
            }
            
            
            return options; 
            
        }
    }
    
    public void UpdateUsersQueue()
    {
            if(c.Assigned_To__c != null)
            {
                usersQueues = CaseAssignmentClass.UsersQueues(c.Assigned_To__c, 'Case');
                for(integer i=0;i<usersQueues .size();i++)
                {
                    Group g = usersQueues [i];
                    
                    if(g.Name == 'Sustaining Engineering Queue')
                    {
                        if(!isCrtAssignProfile)
                        {
                            usersQueues.remove(i);
                        }    
                    }
                }
            }
            else
            {
                usersQueues = null;
            }
        
    }
    
    public void CrtCheck()
    {
        if(selectedQueue == crtQueue)
        {
            isCrt = true;
            isPublicComment = false;
        }
        else
        {
            isCrt = false;
        }
    }

}