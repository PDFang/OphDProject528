public class CCRSubmitButtonExtension 
{
    
    private final ChangeControlRequest__c ccr;
    private final String ccrType;
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    private final Boolean isMaster;
    public boolean custImpact{get;set;}
    public boolean requireChecklist{public get;private set;}
    public boolean requirePeerReview{public get; private set;}
    public boolean needsInstallPlan{public get;private set;}
    public boolean needsTestPlan{public get; private set;}
    public Attachment attach{get;set;}
    public Attachment installPlan{get;set;}
    public Attachment testPlan{get;set;}
    public string checklistUrl{public get; private set;}
    public Id[] peerReviewUsers{get;set;}

    public CCRSubmitButtonExtension(ApexPages.StandardController controller) 
    {
        //get control info
        this.ccr = (ChangeControlRequest__c)controller.getRecord();
        ccrType = ccr.CCRType__c;
        ccrCont = new CCRControlsClass(ccrType);
        ccrValues = ccrCont.ccrControlRecords;     
        isMaster = ccrCont.IsCCBMasterMember(UserInfo.getUserId()); 
        requireChecklist = false; 
        needsInstallPlan = false;
        needsTestPlan = false;
        requirePeerReview = false;
        peerReviewUsers = new Id[]{};
    }
  
    public PageReference ReturnToCCR()
    {
        boolean sendEmail = false;
        
        //determine if there are enough tasks
        if(ccr.NumberOfWorkTasks__c == 0 || ccr.NumberOfCommunicationTasks__c == 0 || ccr.NumberOfValidationTasks__c == 0)
        {
            if(ccr.Status__c != 'Deployed')
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'At least one of each task type is required. Work, Validation, and Communication.'));
                return null;
            }
        }
        
        if(ccr.Status__c == 'Peer Review Rejected')
        {
            
                requirePeerReview = ccrValues.RequirePeerReview__c;
                return null;
        }
        
        //update if open
        if(ccr.Status__c == 'Open')
        {
            if(ccrValues.RequirePlanAttachments__c)
            {
                installPlan = new Attachment();
                needsInstallPlan = true;
                
                requirePeerReview = ccrValues.RequirePeerReview__c;
                
                if(ccr.RiskLevel__c != 'Risk Level 4')
                {
                    testPlan = new Attachment();
                    needsTestPlan = true;
                }
                
                return null;
            }
                if(ccrValues.RequireChecklist__c)
                {
                        attach = new Attachment();
                        requireChecklist = true;
                        checklistUrl = ccrValues.ChecklistUrl__c;
                        return null;
                }
                else
                {
                    if(ccrValues.BypassMasterReview__c)
                    {
                        ccr.Status__c = 'Board Review';
                        ccr.RecordTypeId = ccrValues.CCBBoardRecordTypeID__c;   
                        sendEmail = true;
                    }  
                    else
                    {
                        ccr.Status__c = 'CCB Master Review';
                        ccr.RecordTypeId = ccrValues.CCBMasterRecordTypeID__c;
                    }
            
                    ccr.OwnerId = ccrValues.CCBMastersQueue__c;
                }
        }
        else if(ccr.Status__c == 'CCB Master Review')
        {//send to board if in master review
            if(!isMaster)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must be a member of the CCB Masters Queue to submit a CCR to the board.'));
                return null;
            }
            else
            {
                if(ccr.RFCType__c == 'Pre-Authorized')
                {
                    PageReference approvePage= Page.CCRApprovers;
                    approvePage.getParameters().put('id',ccr.id);
                    approvePage.setRedirect(true);
                    
                    return approvePage;
                }
                else
                {
                    ccr.Status__c = 'Board Review';
                    ccr.RecordTypeId = ccrValues.CCBBoardRecordTypeID__c;
                    sendEmail = true;
                }
            }
        }
        else if(ccr.Status__c == 'Deployed')
        {//close if in a deployed status
            if(!isMaster)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must be a member of the CCB Masters Queue to close a CCR.'));
                return null;
            }
            else
            {
                ccr.Status__c = 'Closed';
                ccr.RecordTypeId = ccrValues.CCRClosedRecordTypeID__c;
                ccr.ClosedDateTime__c = system.now();
                
                if(ccrValues.CustomerImpact__c)
                {
                    custImpact = true;
                    return null;
                }
            }
        }
           
        update ccr;
        
        //send mail if going to the board
        if(sendEmail)
        {
            ccrCont.SendTaskEmail(ccr.id, 'You have one or more tasks waiting for Board Approval on');
        }
        
        
        //go back to ccr
        PageReference pr = new ApexPages.StandardController(ccr).view();
        pr.setRedirect(true);
        
        return pr;
    }
    
    public PageReference SubmitPlans()
    {
        boolean sendEmail = false;
        
        ccr.OwnerId = ccrValues.CCBMastersQueue__c;
        
        
        if(requirePeerReview)
        {
            if(peerReviewUsers.isEmpty())
            {
                installPlan = new Attachment();
                testPlan = new Attachment();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select at least one peer to review the CCR.'));
                return null;
            }
        }
        
        if(needsInstallPlan)
        {
            if(installPlan.Name == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must add an Install Plan file.'));
                
                installPlan = new Attachment();
                testPlan = new Attachment();
                return null;
            }
            
            installPlan.Name = 'InstallPlan_' + ccr.Name + '.' + installPlan.Name.substringAfterLast('.');
            installPlan.ParentId = ccr.Id;
            insert installPlan;
        }
        
        
        if(needsTestPlan)
        {
            if(testPlan.Name == null)
            {
                installPlan = new Attachment();
                testPlan = new Attachment();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must add a Test Plan file.'));
                return null;
            }
            
            testPlan.Name = 'TestPlan_' + ccr.Name + '.' + testPlan.Name.substringAfterLast('.');
            testPlan.ParentId = ccr.Id;
            insert testPlan;
        }
        
        if(requirePeerReview)
        {
            for (integer i=0;i<peerReviewUsers.size();i++) 
            {
                if(peerReviewUsers[i] == UserInfo.getUserId())
                {
                    installPlan = new Attachment();
                    testPlan = new Attachment();
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot add yourself as a peer reviewer.'));
                    return null;
                }
                ccr.put('Approver' + string.valueOf(i+1) + '__c', peerReviewUsers[i]);
            }
            ccr.Status__c = 'Peer Review';
            ccr.RecordTypeId = ccrValues.PeerReviewRecordTypeId__c;
        }
        else if(ccrValues.BypassMasterReview__c)
        {
            ccr.Status__c = 'Board Review';
            ccr.RecordTypeId = ccrValues.CCBBoardRecordTypeID__c;   
            sendEmail = true;
        }  
        else
        {
            ccr.Status__c = 'CCB Master Review';
            ccr.RecordTypeId = ccrValues.CCBMasterRecordTypeID__c;
        }

        
           
        update ccr;
        
        
        if(requirePeerReview)
        {
            List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();

            
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();

                req.setComments('Approving an address change.');
                req.setComments('Please review the CCR.');
                req.setObjectId(ccr.id);

                requests.add(req);
                
            try
            {
                List<Approval.ProcessResult> results = Approval.process(requests);
            }
            catch(Exception ex)
            {
                installPlan = new Attachment();
                testPlan = new Attachment();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                return null;
            }
        }
                
        //send mail if going to the board
        if(sendEmail)
        {
            ccrCont.SendTaskEmail(ccr.id, 'You have one or more tasks waiting for Board Approval on');
        }
    
        //go back to ccr
        PageReference pr = new ApexPages.StandardController(ccr).view();
        pr.setRedirect(true);
        
        return pr;    
        
    }
    
    public PageReference SubmitChecklist()
    {
        boolean sendEmail = false;
        
        if(attach.Body == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must add the completed Release Checklist file.'));
            return null;
        }
        
        if(ccrValues.BypassMasterReview__c)
        {
            ccr.Status__c = 'Board Review';
            ccr.RecordTypeId = ccrValues.CCBBoardRecordTypeID__c;   
            sendEmail = true;
        }  
        else
        {
            ccr.Status__c = 'CCB Master Review';
            ccr.RecordTypeId = ccrValues.CCBMasterRecordTypeID__c;
        }

        ccr.OwnerId = ccrValues.CCBMastersQueue__c;
        
           
        update ccr;
        
        attach.ParentId = ccr.Id;
        insert attach;
        
        //send mail if going to the board
        if(sendEmail)
        {
            ccrCont.SendTaskEmail(ccr.id, 'You have one or more tasks waiting for Board Approval on');
        }
    
        //go back to ccr
        PageReference pr = new ApexPages.StandardController(ccr).view();
        pr.setRedirect(true);
        
        return pr;    
        
    }
    
    public PageReference CloseCCR()
    {
        update ccr;
        
        //go back to ccr
        PageReference pr = new ApexPages.StandardController(ccr).view();
        pr.setRedirect(true);
        
        return pr;
    }
    
    public PageReference Back()
    {
        //go back to ccr
        PageReference pr = new ApexPages.StandardController(ccr).view();
        pr.setRedirect(false);
        
        return pr;
    }
    
    public List<SelectOption> UserList
    {
        get
        {

            
            List<SelectOption> options = new List<SelectOption>();
            set<Id> reviewerIds = new Set<Id>();
			Id ApproverGroupId = [select Id from Group where Name = 'Product Network CCR Peer Reviewers group' limit 1].id;
			for (GroupMember gm : [select UserOrGroupId FROM GroupMember WHERE GroupId = :ApproverGroupId]) 
			{
				reviewerIds.add(gm.UserOrGroupId);
			}

            for(User u:[SELECT Id, Name FROM User WHERE IsActive = true AND Id in :reviewerIds AND ID <> :UserInfo.getUserId()  ORDER BY Name Limit 1000])
            {
                options.add(new SelectOption(u.Id, u.Name));
            }
            
            return options;
        }
    }
  
}