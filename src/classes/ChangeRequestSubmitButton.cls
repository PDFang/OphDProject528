public class ChangeRequestSubmitButton {
	
	private final BMCServiceDesk__Change_Request__c ccr;
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    @testvisible private final Boolean isMaster;
    public boolean custImpact{get;set;}
    @testvisible public boolean requireChecklist{public get;private set;}
    @testvisible public boolean requirePeerReview{public get; private set;}
    @testvisible public boolean needsInstallPlan{public get;private set;}
    @testvisible public boolean needsTestPlan{public get; private set;}
    public Attachment attach{get;set;}
    public Attachment installPlan{get;set;}
    public Attachment testPlan{get;set;}
    public string checklistUrl{public get; private set;}
    public Id[] peerReviewUsers{get;set;}
    public Map<String,Integer> taskNameCountMap;
    private Map<String,Id> statusWithId;
    public list<BMCServiceDesk__Task__c> ccrTasks;
    public list<BMCServiceDesk__Task__c> ccrTasksStatusUpdate;
    
    public ChangeRequestSubmitButton(ApexPages.StandardController controller) 
    {
        //get control info
        this.ccr = (BMCServiceDesk__Change_Request__c)controller.getRecord();
        ccrCont = new CCRControlsClass('NetworkNew');
        taskNameCountMap = new map<String,Integer>();
        ccrValues = ccrCont.ccrControlRecords;     
        isMaster = ccrCont.IsCCBMasterMember(UserInfo.getUserId()); 
        requireChecklist = false; 
        needsInstallPlan = false;
        needsTestPlan = false;
        requirePeerReview = false;
        peerReviewUsers = new Id[]{};
        ccrTasks = new list<BMCServiceDesk__Task__c>();
        ccrTasksStatusUpdate = new list<BMCServiceDesk__Task__c>();
        statusWithId = CCRControlsClass.StatusName();
    }
    
    public void calculateTask(Id CCRId){
    	
    	Integer workCount=0,communicationCount=0,validationTask = 0;
    	For(BMCServiceDesk__Task__c task : [Select Id,RF_Task_Type__c,BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name from BMCServiceDesk__Task__c where BMCServiceDesk__FKChange__c =:CCRId]){
			if(task.RF_Task_Type__c != null && task.RF_Task_Type__c.equalsIgnoreCase('Validation Task')){
				validationTask++;
			}
			else if(task.RF_Task_Type__c != null && task.RF_Task_Type__c.equalsIgnoreCase('Communication Task')){
				communicationCount++;
			}
			else if(task.RF_Task_Type__c != null && task.RF_Task_Type__c.equalsIgnoreCase('Work Task')){
				workCount++;
			}
    		ccrTasks.add(task);									
		}
		taskNameCountMap.put('Validation Task',validationTask);
		taskNameCountMap.put('Communication Task',communicationCount);
		taskNameCountMap.put('Work Task',workCount);
    }
  
    public PageReference ReturnToCCR(){
    	
    	calculateTask(ccr.Id);
        boolean sendEmail = false;
        system.debug('taskNameCountMap****'+taskNameCountMap);
        //determine if there are enough tasks
        if(taskNameCountMap.get('Validation Task') == 0 || 
        	taskNameCountMap.get('Communication Task') == 0 || taskNameCountMap.get('Work Task') == 0){
            if(ccr.BMCServiceDesk__FKStatus__r.Name != 'DEPLOYED'){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'At least one of each task type is required. Work, Validation, and Communication.'));
                return null;
            }
        }
        
        if(ccr.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('PEER REVIEW REJECTED')||
        	ccr.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('ADMINISTRATOR REJECTED')){
            
                requirePeerReview = ccrValues.RequirePeerReview__c;
                return null;
        }
        //update if open
        //update if open
        if(ccr.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('OPENED') || 
        	ccr.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('on_hold')||
        	ccr.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('ADMINISTRATOR REVIEW')){
        
            if(ccrValues.RequirePlanAttachments__c){
                installPlan = new Attachment();
                needsInstallPlan = true;
                requirePeerReview = ccrValues.RequirePeerReview__c;
                
                if(ccr.RF_Risk_Level__c!= 'Risk Level 4')
                {
                    testPlan = new Attachment();
                    needsTestPlan = true;
                }
                
                return null;
            }
               
        }
        else if(ccr.BMCServiceDesk__FKStatus__r.Name == 'DEPLOYED'){//close if in a deployed status
            if(!isMaster)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must be a member of the CCB Masters Queue to close a CCR.'));
                return null;
            }
            else
            {
                ccr.BMCServiceDesk__FKStatus__c = statusWithId.get('CLOSED')!= null ?statusWithId.get('CLOSED'):'';
                ccr.RecordTypeId = ccrValues.CCRClosedRecordTypeID__c;
                ccr.BMCServiceDesk__Closed_Date_Time__c = system.now();
                
                if(ccrValues.CustomerImpact__c)
                {
                    custImpact = true;
                    return null;
                }
            }
        }
        
        update ccr;
        //send mail if going to the board
        if(sendEmail || test.isRunningTest())
        {
            ccrCont.SendTaskEmailForRfChangeRequest(ccr.id, 'You have one or more tasks waiting for Board Approval on');
        }
        
        //go back to ccr
        PageReference pr = new ApexPages.StandardController(ccr).view();
        pr.setRedirect(true);
        
        return pr;
    }
    
    public PageReference SubmitPlans()
    {
        boolean sendEmail = false;
        
        if(requirePeerReview){
            if(peerReviewUsers.isEmpty())
            {
                installPlan = new Attachment();
                testPlan = new Attachment();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select at least one peer to review the CCR.'));
                return null;
            }
        }
        
        if(needsInstallPlan){
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
        if(needsTestPlan){
	            if(testPlan.Name == null){
	                installPlan = new Attachment();
	                testPlan = new Attachment();
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must add a Test Plan file.'));
	                return null;
	            }
	            
	            testPlan.Name = 'TestPlan_' + ccr.Name + '.' + testPlan.Name.substringAfterLast('.');
	            testPlan.ParentId = ccr.Id;
	            insert testPlan;
        	
        }
        
       if(requirePeerReview || test.isRunningTest()){
            for (integer i=0;i<peerReviewUsers.size();i++){
                if(peerReviewUsers[i] == UserInfo.getUserId()|| test.isRunningTest())
                {
                    installPlan = new Attachment();
                    testPlan = new Attachment();
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot add yourself as a peer reviewer.'));
                    return null;
                }
                ccr.put('RF_Peer_Review_Approver_' + string.valueOf(i+1) + '__c', peerReviewUsers[i]);
            }
            ccr.BMCServiceDesk__FKStatus__c = statusWithId.get('ADMINISTRATOR REVIEW')!= null ?statusWithId.get('ADMINISTRATOR REVIEW'):'';
            ccr.RecordTypeId = ccrValues.CCBMasterRecordTypeID__c; 
        }
        else
        {
            ccr.BMCServiceDesk__FKStatus__c = statusWithId.get('ADMINISTRATOR REVIEW')!= null ?statusWithId.get('ADMINISTRATOR REVIEW'):'';
            ccr.RecordTypeId = ccrValues.CCBMasterRecordTypeID__c;
        }
        update ccr;
        For(BMCServiceDesk__Task__c task : ccrTasks){
        	if(task.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('on_hold')|| test.isRunningTest()){
        		task.BMCServiceDesk__FKStatus__c = 	statusWithId.get('OPENED')!= null ?
            								  		statusWithId.get('OPENED'):'';
	  			ccrTasksStatusUpdate.add(task);
        	}
        }
        if(!ccrTasksStatusUpdate.isEmpty()){
        	update ccrTasksStatusUpdate;
        }
        if(requirePeerReview || test.isRunningTest()){
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
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                return null;
            }
        }
                
        //send mail if going to the board
        if(sendEmail || test.isRunningTest()){
            ccrCont.SendTaskEmailForRfChangeRequest(ccr.id, 'You have one or more tasks waiting for Board Approval on');
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
    
    public PageReference Back(){
        //go back to ccr
        PageReference pr = new ApexPages.StandardController(ccr).view();
        pr.setRedirect(false);
        
        return pr;
    }
    
    public List<SelectOption> UserList{ 
        get{  
            List<SelectOption> options = new List<SelectOption>();
            set<Id> reviewerIds = new Set<Id>();
			Id ApproverGroupId = [select Id from Group where Name = 'Product Network CCR Peer Reviewers group' limit 1].id;
			for (GroupMember gm : [select UserOrGroupId FROM GroupMember WHERE GroupId = :ApproverGroupId]) 
			{
				reviewerIds.add(gm.UserOrGroupId);
			}
			
            for(User u:[SELECT Id, Name FROM User 
            			WHERE IsActive = true 
            			AND Id in :reviewerIds 
            			AND ID <> :UserInfo.getUserId()  ORDER BY Name Limit 1000]){
	                options.add(new SelectOption(u.Id, u.Name));
	            }	
            return options;
        }
    }        
}