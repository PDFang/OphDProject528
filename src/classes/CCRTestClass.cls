@isTest
private class CCRTestClass {
	
	private static void CreateCcrControls(string ccrType, boolean requirePlans, boolean bypassMaster, boolean peerReview)
	{
		string recordTypeName;
    	Map<String,Schema.Recordtypeinfo> caseRecordTypes = Case.SObjectType.getDescribe().getRecordTypeInfosByName();  
    	
    	
    	CCRControls__c ccrCont = new CCRControls__c();
    	ccrCont.Name = ccrType;
    	ccrCont.BypassMasterReview__c = bypassMaster;
    	ccrCont.Environment__c = inContactConfiguration.Instance;
    	ccrCont.NumberOfApproversRequired__c = 1;
    	ccrCont.RequirePeerReview__c = peerReview;
    	ccrCont.RequirePlanAttachments__c = requirePlans;
    	
    	if(ccrType == 'Network'){ccrType = 'Product and Network';}
    	
    	for(Schema.Recordtypeinfo rti: caseRecordTypes.values())
    	{
    		recordTypeName = rti.getName();
    		    		
    		if(recordTypeName.startsWithIgnoreCase(ccrType))
    		{
    			if(recordTypeName.containsOnly(ccrType)){ccrCont.NewRecordTypeID__c = rti.getRecordTypeId();}
    			if(recordTypeName.endsWithIgnoreCase('Approved')){ccrCont.CCRApprovedRecordTypeID__c = rti.getRecordTypeId();}
    			if(recordTypeName.endsWithIgnoreCase('Board Review')){ccrCont.CCBBoardRecordTypeID__c = rti.getRecordTypeId();}
    			if(recordTypeName.endsWithIgnoreCase('CCB Master Review')){ccrCont.CCBMasterRecordTypeID__c = rti.getRecordTypeId();}
    			if(recordTypeName.endsWithIgnoreCase('Closed')){ccrCont.CCRClosedRecordTypeID__c = rti.getRecordTypeId();}
    			if(recordTypeName.endsWithIgnoreCase('Deployed')){ccrCont.CCRDeployedRecordTypeID__c = rti.getRecordTypeId();}
    			if(recordTypeName.endsWithIgnoreCase('Peer Review')){ccrCont.PeerReviewRecordTypeId__c = rti.getRecordTypeId();}
    		}
    	}
    	
    	string queueName = ccrType + ' CCB Masters';
    	string groupName = 'CCR Approvers - ' + ccrType;
    	
        ccrCont.CCBMastersQueue__c = [SELECT ID FROM Group WHERE Type = 'Queue' AND Name = :queueName].Id;
        ccrCont.CCBMembersGroupId__c = [SELECT ID FROM Group WHERE Type = 'Regular' AND Name = :groupName].Id;
    	
    	insert ccrCont;
	}
	
	
	static testMethod void TestGetReleaseValues()
	{
		
		//set mock for selecting TFS release values
		Test.setMock(WebServiceMock.class, new ITfsIntegrationProxy()); 
		
		String[] releaseValues = TfsAccess.TfsReleaseValues();
		system.assertEquals(releaseValues, new String[]{'test','test2'});
		
	}
	
    static testMethod void TestCcrCreatePage()
    {
    	CreateCcrControls('Network',true, true, true);
    	
    	
    	Map<String,Schema.Recordtypeinfo> ccrRecordTypes = ChangeControlRequest__c.SObjectType.getDescribe().getRecordTypeInfosByName(); 
        ID ccrRecordType = ccrRecordTypes.get('Product and Network').getRecordTypeId();
          
        Map<String,Schema.RecordTypeInfo> caseRecordTypes = Case.SObjectType.getDescribe().getRecordTypeInfosByName(); 
        

        Id incidentCaseRecordType = caseRecordTypes.get('Incident').getRecordTypeId();
        
        ChangeControlRequest__c ccr = new ChangeControlRequest__c();
        ccr.Summary__c = 'Test CCR';
        ccr.ReleaseDate__c = system.today();
        ccr.CCRStartTime__c = system.now();
        ccr.BusinessRiskAssessment__c = 'test'; 
        ccr.CCRType__c = 'Network';
        ccr.RecordTypeId = ccrRecordType;
        ccr.ContingencyPlan__c = 'test';
        ccr.Description__c = 'test';
        ccr.DescriptionOfTesting__c = 'test';
        ccr.RiskLevelOfCCR__c = 'Low';
        ccr.Status__c = 'Open';
		
		//insert ccr;
		
		//create test account
        Account a = TestUtilities.CreateAccount('name', true);                
                
        //create contact
        Contact ct = TestUtilities.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', true);
                  
        //create test case      
        Case c = TestUtilities.CreateCase(a.Id, ct.Id, incidentCaseRecordType, 'subject');
        c.Request_Type__c = 'Adds/Moves/Changes';
        c.Product_or_Service__c = 'DIA';
        c.Status = 'New';
        c.Urgency__c = 'Low';
        c.Impact__c = 'Low';
        
        insert c;
        
        
        Project__c p = new Project__c();
        p.Summary__c = 'Test Method';
        
        insert p;
        

		//initiate CaseWatchedCases page
        PageReference pageRef = Page.CCRCreate;
        Test.setCurrentPage(pageRef);

        //Test second half of the Trip_AttendeeExtension.SaveAttendee Method
        ApexPages.StandardController controller = new ApexPages.StandardController(ccr);
        
        CCRCreateExtension ext = new CCRCreateExtension(controller);
        
        
        ApexPages.currentPage().getParameters().put('caseId',c.Id);
        ApexPages.currentPage().getParameters().put('projectId',p.Id);
        
        ext.Save();
        string ccrType = ext.ccrType;
        boolean isCloned = ext.IsCloneRecord;
        boolean useClusterRelease = ext.UseClusterAndRelease;
        
        List<RecordType> taskRts = [SELECT ID FROM RecordType WHERE SobjectType = 'CCRTask__c'];
        List<CCRTask__c> ccrTasks = new List<CCRTask__c>();
        
        for(integer i=0;i<taskRts.Size();i++)
        {
            CCRTask__c t = new CCRTask__c();
            t.ChangeControlRequest__c = ccr.Id;
            t.Order__c = i + 1;
            t.RecordTypeId = taskRts[i].Id;
            t.AssignedTo__c = UserInfo.getUserId();
            t.Description__c = 'Test';
            t.Duration__c = 20;
            t.TaskDateTime__c = system.now();
            
            ccrTasks.add(t);
        }
        
        insert ccrTasks;
        
		ApexPages.currentPage().getParameters().put('clone','1');
		CCRCreateExtension ext2 = new CCRCreateExtension(controller);
		
		
      
        ApexPages.currentPage().getParameters().put('tlInd','0');
        ext2.DeleteRow();
		
		ext2.Save();
    }
    
    static testMethod void TestChangeControlRequests()
    {
    	CreateCcrControls('Network', true, true, true);
        
    	Map<String,Schema.Recordtypeinfo> ccrRecordTypes = ChangeControlRequest__c.SObjectType.getDescribe().getRecordTypeInfosByName();  
        ID ccrRecordType = ccrRecordTypes.get('Product and Network').getRecordTypeId();
        
        List<RecordType> taskRts = [SELECT ID FROM RecordType WHERE SobjectType = 'CCRTask__c'];
        String ccbMastQueue = [SELECT ID FROM Group WHERE Type = 'Queue' AND Name = 'Corporate IT CCB Masters'].Id;
        String ccbApprovers = [SELECT ID FROM Group WHERE Type = 'Regular' AND Name = 'CCR Approvers - Corporate IT'].Id;
        
        CCRControls__c uC = CCRControls__c.getInstance('Network');
        
        
        
        CCRControlsClass ccrCont;
        CCRControls__c ccrValues;
        List<CCRTask__c> ccrTasks = new List<CCRTask__c>();
        ID[] ccbApprove = new ID[]{};
        
        ChangeControlRequest__c ccr = new ChangeControlRequest__c();
        ccr.Summary__c = 'Test CCR';
        ccr.ReleaseDate__c = system.today();
        ccr.CCRStartTime__c = system.now();
        ccr.BusinessRiskAssessment__c = 'test';
        ccr.CCRType__c = 'Network';
        ccr.RecordTypeId = ccrRecordType;
        ccr.ContingencyPlan__c = 'test';
        ccr.Description__c = 'test';
        ccr.DescriptionOfTesting__c = 'test';
        ccr.RiskLevelOfCCR__c = 'Low';
        ccr.Status__c = 'Open';
        ccr.Experience__c = '2';
        ccr.RequiresUserEducation__c = '3';
        ccr.Documentation__c = '2';
        ccr.MaintenanceWindow__c = '4';
        ccr.Validation__c = '2';
        ccr.OutageScope__c = '2';
        ccr.PrepTimeRequired__c = '2';
        ccr.BusinessImpact__c = '2';
        ccr.ResourcesRequired__c = '2';
        ccr.Security__c = '2';
        ccr.Backout__c = '15';
        
        insert ccr;
        
        ccr = [SELECT NumberOfWorkTasks__c, NumberOfCommunicationTasks__c, NumberOfValidationTasks__c, Summary__c, Status__c, OwnerId, CCRType__c, RiskLevel__c, RecordTypeId FROM ChangeControlRequest__c WHERE Id = :ccr.Id ];
           
        Group G = new Group();
        G.Name = 'Product Network CCR Peer Reviewers group';
        insert G;
        
        
        
        //Test First Submit
        ApexPages.StandardController subMast = new ApexPages.StandardController(ccr);
        CCRSubmitButtonExtension subExt = new CCRSubmitButtonExtension(subMast);
        
        List<SelectOption> UserList = subExt.UserList;
        PageReference submitWithNoTasks = subExt.ReturnToCCR();
        
        for(integer i=0;i<taskRts.Size();i++)
        {
            CCRTask__c t = new CCRTask__c();
            t.ChangeControlRequest__c = ccr.Id;
            t.Order__c = i + 1;
            t.RecordTypeId = taskRts[i].Id;
            t.AssignedTo__c = UserInfo.getUserId();
            t.Description__c = 'Test';
            t.Duration__c = 20;
            t.TaskDateTime__c = system.now();
            
            ccrTasks.add(t);
        }
        
        insert ccrTasks;
        
        ccr = [SELECT NumberOfWorkTasks__c, NumberOfCommunicationTasks__c, NumberOfValidationTasks__c, Summary__c, Status__c, OwnerId, CCRType__c, RiskLevel__c, RecordTypeId FROM ChangeControlRequest__c WHERE Id = :ccr.Id ];
        
        ApexPages.StandardController subMast2 = new ApexPages.StandardController(ccr);
        CCRSubmitButtonExtension subExt2 = new CCRSubmitButtonExtension(subMast2);
        
        system.assertEquals(ccr.Status__c, 'Open');
        system.debug(ccr.Status__c);
        subExt2.ReturnToCCR();
        
        ccrCont = new CCRControlsClass(ccr.CCRType__c);
        ccrValues = ccrCont.ccrControlRecords;
        
        
        subExt2.SubmitPlans();
        
        //load files
        subExt2.testPlan.Name ='Unit Test Attachment';
        subExt2.testPlan.Body =Blob.valueOf('Unit Test Attachment Body');
        
        
        subExt2.SubmitPlans();
        
        subExt2.installPlan.Name ='Unit Test Attachment';
        subExt2.installPlan.Body =Blob.valueOf('Unit Test Attachment Body');
        subExt2.peerReviewUsers.add([SELECT Id FROM User WHERE IsActive = true AND UserType = 'Standard' AND Id <> :UserInfo.getUserId() LIMIT 1].Id);
        
        subExt2.SubmitPlans();
        //task page
        ApexPages.StandardController taskMast = new ApexPages.StandardController(ccr);
        CCRTaskPageExtension taskExt = new CCRTaskPageExtension(taskMast);
        
        //get record types        
        string taskRecordTypes = taskExt.TaskRecordTypes;
        boolean allowEdits = taskExt.AllowEdits;
        boolean isCcbMaster = taskExt.IsCCBMaster;
        boolean useMaintenanceWindow = taskExt.UseMaintenanceWindow;
        
        string assignees = CCRTaskPageExtension.JsonTaskAssignee();
        List<Attachment> attachments = taskExt.attachments;
        taskExt.SaveAttachment();
        
        string jsonTaks = CCRTaskPageExtension.JSONTasks(ccr.Id);
        
        
        PageReference firstSubmit = subExt2.ReturnToCCR();
        PageReference secondSubmit = subExt2.ReturnToCCR();
        PageReference backSubmit = subExt2.Back();
        subExt2.CloseCCR();
        
        //put on hold
        ApexPages.StandardController holdMast = new ApexPages.StandardController(ccr);
        CCRHoldExtension holdExt = new CCRHoldExtension(holdMast);
        
        holdExt.Save();
        
        //do approval
        ApexPages.StandardController approveMast = new ApexPages.StandardController(ccr);
        CCRApproversExtension approveExt = new CCRApproversExtension(approveMast);
        
        
        List<User> ccbMembers= [SELECT Id, Name FROM User WHERE Id IN(SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :ccrValues.CCBMembersGroupId__c) ORDER BY Name];
        for(User u:ccbMembers)
        {
            ccbApprove.Add(u.Id);
        }
        
        approveExt.SelectedApprovers = ccbApprove;
        ID[] listApprove = approveExt.SelectedApprovers;
        boolean render = approveExt.Rendered;
        PageReference approveSave = approveExt.Save();
        
        ccr.Status__c = 'Ready For Deployment';
        
        for(CCRTask__c t:ccrTasks)
        {
	        string returnJson = '{"data": {';
	        returnJson = returnJson + '"Id":"' + t.Id + '"';
	        returnJson = returnJson + ',"Order__c":"' + t.Order__c + '"';
	        returnJson = returnJson + ',"RecordTypeId":"' + t.RecordTypeId + '"';
	        returnJson = returnJson + ',"AssignedTo__c":"' + t.AssignedTo__c + '"';
	        returnJson = returnJson + ',"Description__c":"' + t.Description__c + '"';
	        returnJson = returnJson + ',"Duration__c":"' + t.Duration__c + '"';
	        returnJson = returnJson + ',"ChangeControlRequest__c":"' + t.ChangeControlRequest__c + '"';
	        returnJson = returnJson + ',"TaskDateTime__c":"' + string.valueOfGmt(t.TaskDateTime__c).replace(' ','T') + '.000Z"';
	        returnJson = returnJson + ',"Status__c":"Approved"';
	        returnJson = returnJson + '}}';
            
            CCRTaskPageExtension.JsonUpdateTask(returnJson);
            ccrCont.SendSingleTaskEmail(t.Id, t.Description__c);
        }
        
        //close ccr
        //ccr.Status__c = 'Deployed';
        ApexPages.StandardController subMast3 = new ApexPages.StandardController(ccr);
        CCRSubmitButtonExtension subExt3 = new CCRSubmitButtonExtension(subMast3);
        
        PageReference closeSubmit = subExt3.ReturnToCCR(); 
        
        //clone ccr
        ApexPages.StandardController cloneCCR = new ApexPages.StandardController(ccr);
        CCRCloneExtension cloneExt = new CCRCloneExtension(cloneCCR);
        
        List<CCRTask__c> cloneTasks = cloneExt.CCRTaskList;
        cloneExt.CCRTaskList = cloneTasks;
        
     
        boolean useMainWindow = cloneExt.UseMaintenanceWindow;
         
        //PageReference cloneSave = cloneExt.Save();
        
        //create ccr to cancel
        ChangeControlRequest__c ccrCancel = new ChangeControlRequest__c();
        ccrCancel.Summary__c = 'Test CCR';
        ccrCancel.ReleaseDate__c = system.today();
        ccrCancel.CCRStartTime__c = system.now();
        ccrCancel.BusinessRiskAssessment__c = 'test';
        ccrCancel.CCRType__c = 'Network';
        ccrCancel.RecordTypeId = ccrRecordType;
        ccrCancel.ContingencyPlan__c = 'test';
        ccrCancel.Description__c = 'test';
        ccrCancel.DescriptionOfTesting__c = 'test';
        ccrCancel.RiskLevelOfCCR__c = 'Low';
        ccrCancel.Status__c = 'Open';
                
        insert ccrCancel;
        
        ApexPages.StandardController cancelCCR = new ApexPages.StandardController(ccrCancel);
        CCRCancelFailExtension cancelExt = new CCRCancelFailExtension(cancelCCR);
        
        PageReference cancelClose = cancelExt.Cancel();
        String display = cancelExt.DisplayString;
        cancelExt.CloseCCR();
        
        //test CCR Calendar
        CCRCalendarController cal = new CCRCalendarController();
        
        String calType = cal.CCRTypeSelected;
        calType = 'Network';
        cal.CCRTypeSelected = calType;
        
        cal.CCRTypeChange();
        cal.AddMonth();
        cal.SubtractMonth();
        
        String calText = cal.calendarControl;
        String mon = cal.MonthString;
        CCRTask__c[] appTasks = cal.ApprovedTasks;
        List<selectOption> selList = cal.CCRTypeSelect;
    }
}