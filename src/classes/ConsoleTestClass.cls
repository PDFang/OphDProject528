@isTest
private class ConsoleTestClass
{	
    
    
    static testMethod void Test_ConsoleIncidentActions()
    {
        Map<String,Schema.RecordTypeInfo> accountRecordTypes = Account.SObjectType.getDescribe().getRecordTypeInfosByName();        
        Map<String,Schema.RecordTypeInfo> caseRecordTypes = Case.SObjectType.getDescribe().getRecordTypeInfosByName(); 
        
        Id customerAccountRecordType = accountRecordTypes.get('Customers').getRecordTypeId();
        Id incidentCaseRecordType = caseRecordTypes.get('Incident').getRecordTypeId();
        
        //create test account
        Account acct = TestUtilities.CreateAccount('testName',customerAccountRecordType,true);
                
        //create contact
        Contact contact = TestUtilities.CreateContact(acct.Id, 'firstName', 'lastName', 'email@test.com', true);
        
        //create test case      
        Case incident = TestUtilities.CreateCase(acct.Id, contact.Id, incidentCaseRecordType, acct.Name);
        incident.Request_Type__c = 'Adds/Moves/Changes';
        incident.Product_or_Service__c = 'DIA';
        incident.Status = 'New';
        incident.Freqeuncy__c = 'Occasional';
        incident.Number_of_Customers_Affected__c = '1';
        incident.Severity__c = 'S4';
        
        insert incident;
        
        CaseArticle__c ca = new CaseArticle__c();
        ca.ArticleNumber__c = '100';
        ca.Case__c = incident.Id;
        ca.Summary__c = 'summary';
        ca.Title__c = 'title';
         
        insert ca;
        
        /* TEST JsonCaseArticles method on ConsoleRemoteActions */
        string articles = ConsoleRemoteActions.JsonCaseArticles(incident.Id);
        CaseArticle__c[] returnArticles = (CaseArticle__c[])JSON.deserialize(articles,CaseArticle__c[].class);
        
        system.assertEquals(ca.ArticleNumber__c, returnArticles[0].ArticleNumber__c);
        
        ConsoleRemoteActions.DeleteCaseArticle(ca.Id);
        ConsoleRemoteActions.SetAccountMood(acct.Id, 'Mad');
        
    }
    
    
    
    static testMethod void Test_CaseAttachments()
    {
    	
    	Case baseCase = new Case();
    	baseCase.Subject = 'subject';
    	baseCase.Steps_to_Recreate__c = 'steps to recreate';
    	baseCase.ProductImpacted__c = 'product';
    	baseCase.PlatformsImpacted__c = 'platforms';
    	
        
    	
    	//set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        
        
		baseCase.setOptions(dmo);
    	
    	
    	insert baseCase;
    	
        ApexPages.StandardController controller = new ApexPages.StandardController(baseCase);
        CaseAttachmentExtension extension = new CaseAttachmentExtension(controller);
        
        //create public file
        extension.fileToUpload.Body = Blob.valueOf( 'this is an attachment test' );
        extension.fileToUpload.Name = 'filename.csv';
        extension.CreateAttachment();
        
        //create internal file
        extension.fileToUpload.Body = Blob.valueOf( 'this is an attachment test' );
        extension.fileToUpload.Name = 'filename.csv';
        extension.isFileInternal = true;
        extension.CreateAttachment();
        
        CaseAttachment[] attachments = (CaseAttachment[])JSON.deserialize(ConsoleRemoteActions.JsonSelectCaseAttachments(baseCase.Id),CaseAttachment[].class);
        
		for(CaseAttachment ca: attachments)
		{
			ConsoleRemoteActions.UpdateVisibility(ca.attachmentId, !ca.IsPublic, baseCase.Id);
		}
        
    }
    
    
    static testMethod void Test_ConsoleCaseRightSidebarExtension()
    {
        Map<String,Schema.RecordTypeInfo> accountRecordTypes = Account.SObjectType.getDescribe().getRecordTypeInfosByName();        
        Map<String,Schema.RecordTypeInfo> caseRecordTypes = Case.SObjectType.getDescribe().getRecordTypeInfosByName(); 
        
        Id customerAccountRecordType = accountRecordTypes.get('Customers').getRecordTypeId();
        Id incidentCaseRecordType = caseRecordTypes.get('Incident').getRecordTypeId();
        
        //create test account
        Account acct = TestUtilities.CreateAccount('testName',customerAccountRecordType,true);
                
        //create contact
        Contact contact = TestUtilities.CreateContact(acct.Id, 'firstName', 'lastName', 'email@test.com', true);
        
        //create test case      
        Case incident = TestUtilities.CreateCase(acct.Id, contact.Id, incidentCaseRecordType, acct.Name);
        incident.Request_Type__c = 'Adds/Moves/Changes';
        incident.Product_or_Service__c = 'DIA';
        incident.Status = 'New';
        incident.Freqeuncy__c = 'Occasional';
        incident.Number_of_Customers_Affected__c = '1';
        incident.Severity__c = 'S4';
        incident.Urgency__c = 'Low';
        incident.Impact__c = 'Low';
        
        insert incident;
        
        //Test second half of the Trip_AttendeeExtension.SaveAttendee Method
        ApexPages.StandardController controller = new ApexPages.StandardController(incident);
        ConsoleCaseRightSidebarExtension extension = new ConsoleCaseRightSidebarExtension(controller);
        
        List<selectOption> queueList = extension.caseQueues;
        extension.UpdateQueue = queueList[0].getValue();
        
        system.assertEquals(queueList[0].getValue(), extension.UpdateQueue);
        
        List<Case> caseList = extension.SearchCases;
        //add more after adjusting tech support skill issue
        extension.caseForFields.TechSupportSkill__c = 'tech-support-skill';
        
        system.assertEquals(0,extension.CaseCount);
        
        extension.SetQueueCookie();
        extension.GetQueueCookie();
        
       
    }
    
    static testMethod void Test_ConsoleCaseControlsExtension()
    {
        Map<String,Schema.RecordTypeInfo> accountRecordTypes = Account.SObjectType.getDescribe().getRecordTypeInfosByName();        
        Map<String,Schema.RecordTypeInfo> caseRecordTypes = Case.SObjectType.getDescribe().getRecordTypeInfosByName(); 
        
        Id customerAccountRecordType = accountRecordTypes.get('Customers').getRecordTypeId();
        Id incidentCaseRecordType = caseRecordTypes.get('Incident').getRecordTypeId();
        
        //create test account
        Account acct = TestUtilities.CreateAccount('testName',customerAccountRecordType,true);
                
        //create contact
        Contact contact = TestUtilities.CreateContact(acct.Id, 'firstName', 'lastName', 'email@test.com', true);
        
        //create test case      
        Case incident = TestUtilities.CreateCase(acct.Id, contact.Id, incidentCaseRecordType, acct.Name);
        incident.Request_Type__c = 'Adds/Moves/Changes';
        incident.Product_or_Service__c = 'DIA';
        incident.Status = 'New';
        incident.Urgency__c = 'Low';
        incident.Impact__c = 'Low';
        
        insert incident;
        
        //Test second half of the Trip_AttendeeExtension.SaveAttendee Method
        ApexPages.StandardController controller = new ApexPages.StandardController(incident);
        ConsoleCaseControlsExtension extension = new ConsoleCaseControlsExtension(controller);
        
        CaseMilestone[] milestones = extension.getOpenMilestones();
    }
    
    static testMethod void Test_ConsoleAccountHighlightPanelExtension()
    {
        Map<String,Schema.RecordTypeInfo> accountRecordTypes = Account.SObjectType.getDescribe().getRecordTypeInfosByName();        
        Map<String,Schema.RecordTypeInfo> caseRecordTypes = Case.SObjectType.getDescribe().getRecordTypeInfosByName(); 
        
        Id customerAccountRecordType = accountRecordTypes.get('Customers').getRecordTypeId();
        Id incidentCaseRecordType = caseRecordTypes.get('Incident').getRecordTypeId();
        
        //create test account
        Account acct = TestUtilities.CreateAccount('testName',customerAccountRecordType,true);
                
        //create contact
        Contact contact = TestUtilities.CreateContact(acct.Id, 'firstName', 'lastName', 'email@test.com', true);
        
        //create test case      
        Case incident = TestUtilities.CreateCase(acct.Id, contact.Id, incidentCaseRecordType, acct.Name);
        incident.Request_Type__c = 'Adds/Moves/Changes';
        incident.Product_or_Service__c = 'DIA';
        incident.Status = 'New';
        incident.Urgency__c = 'Low';
        incident.Impact__c = 'Low';
        
        insert incident;
        
        //Test second half of the Trip_AttendeeExtension.SaveAttendee Method
        ApexPages.StandardController controller = new ApexPages.StandardController(acct);
        ConsoleAccountHighlightPanelExtension ext = new ConsoleAccountHighlightPanelExtension(controller);
        
        string gyrStatus = ext.GyrStatus;
        system.assertEquals('Green',gyrStatus);
        
        GYR__c gyr = TestUtilities.CreateGyr(acct.Id, 'Yellow', true);
        gyrStatus = ext.GyrStatus;
        system.assertEquals('Yellow',gyrStatus);
        
        string packageHours = ext.PsPackageHours;
        system.assertEquals('0.0', packageHours);
        system.assertEquals('1', ext.NumberOfOpenIncidents);
    }
    
    
    
    static testMethod void Test_ConsoleAccountRightSidebarExtension()
    {
        Map<String,Schema.RecordTypeInfo> accountRecordTypes = Account.SObjectType.getDescribe().getRecordTypeInfosByName();        
        Map<String,Schema.RecordTypeInfo> caseRecordTypes = Case.SObjectType.getDescribe().getRecordTypeInfosByName(); 
        
        Id customerAccountRecordType = accountRecordTypes.get('Customers').getRecordTypeId();
        Id incidentCaseRecordType = caseRecordTypes.get('Incident').getRecordTypeId();
        
        //create test account
        Account acct = TestUtilities.CreateAccount('testName',customerAccountRecordType,true);
                
        //create contact
        Contact contact = TestUtilities.CreateContact(acct.Id, 'firstName', 'lastName', 'email@test.com', true);
        
        //create test case      
        Case incident = TestUtilities.CreateCase(acct.Id, contact.Id, incidentCaseRecordType, 'subject');
        incident.Request_Type__c = 'Adds/Moves/Changes';
        incident.Product_or_Service__c = 'DIA';
        incident.Status = 'New';
        incident.Urgency__c = 'Low';
        incident.Impact__c = 'Low';
        
        insert incident;
        
        //Test second half of the Trip_AttendeeExtension.SaveAttendee Method
        ApexPages.StandardController controller = new ApexPages.StandardController(acct);
        ConsoleAccountRightSidebarExtension accountSidebar = new ConsoleAccountRightSidebarExtension(controller);
        
        system.assertEquals(1, accountSidebar.contactList.Size());
        system.assertEquals('lastName', accountSidebar.contactList[0].LastName);
        system.assertEquals(1, accountSidebar.caseList.Size());
        system.assertEquals('subject', accountSidebar.caseList[0].Subject);
    }
    
    
    
    static testMethod void Test_ConsoleBannerAlertController()
    {
        BannerAlert__c alert = new BannerAlert__c();
        alert.AlertMessage__c = 'alert-message';
        alert.AlertStart__c = system.now()-1;
        alert.Expires__c = system.now()+1000;
        insert alert;
        
        
        ConsoleBannerAlertController bannerController = new ConsoleBannerAlertController();
        string messages = bannerController.alertMessage;
        string remoteMessages = ConsoleBannerAlertController.GetAlertMessages();
        
        system.assertEquals(messages, remoteMessages);
    }

}