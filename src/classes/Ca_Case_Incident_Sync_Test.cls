@isTest (SeeAllData=false)
private class Ca_Case_Incident_Sync_Test {
    static void createxMConfigRec() {
        xMatters_Config__c configRec = new xMatters_Config__c( name='xMConfig' );
        
        configRec.Remedy_Inbound_URL__c           = 'https://inboundurl';
        configRec.Remedy_Password__c              = 'Password1234';
        configRec.Remedy_Username__c              = 'RFusername';
        configRec.xMatters_Group_Endpoint__c      = 'https://company.instance.xmatters.com/path/reapi';
        configRec.xMatters_Individual_Endpoint__c = 'https://company.instance.xmatters.com/path/reapi';
        configRec.xMatters_Password__c            = 'Password22222';
        configRec.xMatters_Username__c            = 'xMUsername';
        configRec.Use_Response_Callback__c        = true;
        configRec.Payload_Fields__c       = 'Account;Category;Client ID;Impact;Last Name;First Call Resolution;Opened Date;Closed Date;Last Queue';
        configRec.Notifiable_Priorities__c        = '1;2';
        configRec.Notifiable_Statuses__c          = 'UPDATED;OPENED';
        
        insert configRec;
        
    }
	static testMethod void myUnitTest() 
	{
        //Create a test Case 
        
        Test.startTest();
        
        Boolean bCheck = Ca_Case_Incident_Sync.hasTriggerName('TestTriggerName');	
		bCheck = Ca_Case_Incident_Sync.hasTriggerName('TestTriggerName');	
		bCheck = Ca_Case_Incident_Sync.runOnce();
		bCheck = Ca_Case_Incident_Sync.runOnce();
		
		//Without Case Comment action first (testing early break)
		List<CaseComment> newTriggerComments = new List<CaseComment>();
		Ca_Case_Incident_Sync.CaseComment_executeTrigger(newTriggerComments);
        
        //Create the "Case Comment" action
		BMCServiceDesk__Action__c commentNote  = new BMCServiceDesk__Action__c(Name ='Case Comment', BMCServiceDesk__appliesToIncident__c = TRUE ); 
		insert commentNote;
        
        SiteConfiguration__c c = new SiteConfiguration__c();
        c.AutoEventEmails__c=true;
        //c.Name= '00D5B0000008bzr';
        c.Name=''+UserInfo.getOrganizationId().substring(0,15);
        insert c;
        System.Debug('***ORG ID c***'+c);
        System.Debug('***ORG ID***'+UserInfo.getOrganizationId());
       
        RecordType rt = [SELECT id,Name FROM RecordType WHERE SobjectType='Case' AND Name='Event'];
		Case newCase = new Case(
			Origin = 'Phone',
			Status = 'Opened',
			Priority = 'P3',
			EventType__c='testCat',
			ProductImpacted__c='ASR',
			CustomersMayExperienceTheFollowing__c='Test',
			CustomerAction__c='Test',
			SecurityEventStatus__c='Test',
			NonEvent__c=true,			
			Description = 'Test Case description',
			Subject='Test',
			InternalEvent__c=True,
            RecordTypeId=rt.id,
            PlatformsImpacted__c='C1 - inContact; C2 - inContact'
		);
		insert newCase;
        
        // Creating Change Client  
        sObject profile = [ select id from profile where Name = 'Standard User' LIMIT 1 ];
        User testUser = new User (

        Username='createestuser@test.ca.com',
        Email='createtestuser@test.ca.com',
        Lastname='createuser',
        Firstname='createtest',
        Alias='CTest',
        CommunityNickname = 'createtest',
        ProfileId = (ID) profile.get('Id'),
        //CurrencyIsoCode = 'USD',
        TimeZoneSidKey = 'GMT',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'ISO-8859-1',
        LanguageLocaleKey = 'en_US'

        );
        insert testUser;
        
        // Creating Impact and Urgency
        BMCServiceDesk__Impact__c testImpact = new BMCServiceDesk__Impact__c(Name='SEV4');
        insert testImpact;   
        BMCServiceDesk__Urgency__c testUrgency = new BMCServiceDesk__Urgency__c(Name='LOW');
        insert testUrgency;
        
        //Creating Category           
        BMCServiceDesk__Category__c testCat = new BMCServiceDesk__Category__c(
        	Name='Performance Issue', 
            BMCServiceDesk__AvailableForIncidents__c= true
        );
        Insert testcat;
       
        BMCServiceDesk__Status__c testStatusVal = new BMCServiceDesk__Status__c(
        Name='Validation', 
        BMCServiceDesk__appliesToIncident__c = true,  
        BMCServiceDesk__appliesToTask__c =TRUE
        );  
		 insert testStatusVal;
        
        //Change owner test
            List<Group> g = [ SELECT Name, Id FROM Group WHERE Name = 'Network' LIMIT 1 ];
        
                        createxMConfigRec();
        
        Map<String, String> configMap = xMattersRESTHelper.getConfigMap();                
        BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c (
            BMCServiceDesk__FKClient__c = testUser.Id,
            BMCServiceDesk__FKImpact__c = testImpact.Id,
            BMCServiceDesk__FKCategory__c = testCat.Id,
            BMCServiceDesk__FKUrgency__c = testUrgency.Id,
            BMCServiceDesk__FKStatus__c = testStatusVal.id,           
            BMCServiceDesk__incidentDescription__c = 'Test',
            RF_Product_Impacted__c='ASR',            
            RF_Customers_May_Experience_following__c='Testing',
            RF_Customer_Action__c='Testing',
           RF_Platform_s_Impacted__c='C1 - inContact; C2 - inContact', 
            Create_Case__c=true,
            OwnerId = g[0].Id
           // End_Date__c = System.today() + 1
        );
        insert inc;
        
        
        //Get the Incident reference
		newCase = [select Id,Related_Incident__c,PlatformsImpacted__c  from Case where Id = : newCase.id][0];
        
		if(newCase.Related_Incident__c == null)
		{
			newCase.Related_Incident__c = inc.id;
            newCase.PlatformsImpacted__c ='C1 - inContact; C5 - inContact';
			upsert newCase;
		}
         //Create a case comment for the case, to be pushed to the Incident
		CaseComment newComment = new CaseComment
		(
		CommentBody = '<RF> Test Comment',
		ParentId = newCase.Id
		);
		insert newComment;
        
        CaseComment newComment1 = new CaseComment
		(
		CommentBody = ' Test Comment1',
		ParentId = newCase.Id
		);
		insert newComment1;
        
        inc = [select Id,Source_Case__c,RF_Platform_s_Impacted__c  from BMCServiceDesk__Incident__c where Id = : inc.id][0];
        if(inc.Source_Case__c == null)
		{
			inc.Source_Case__c = newCase.id;
           System.Debug('*****update null inside');
			update inc;
		}
        
		if(inc.Source_Case__c != null)
		{
            actionHub_CaseIncidentHandler.firedActionHubCaseIncident= false;
			 System.Debug('*****update  not null inside');
            inc.RF_Platform_s_Impacted__c  ='C1 - inContact; C4 - inContact';
            inc.BMCServiceDesk__incidentDescription__c = 'Test updated';
			update inc;
		}
        
        
        //Create a Incident History Record for the Incident
 		BMCServiceDesk__IncidentHistory__c hInc = new BMCServiceDesk__IncidentHistory__c(
            BMCServiceDesk__FKIncident__c = inc.Id, 
            BMCServiceDesk__FKAction__c = commentNote.Id, 
            BMCServiceDesk__description__c='Test', 
            BMCServiceDesk__note__c='Test' 
        );
        insert hInc;
        
       
        
        
        Attachment attach=new Attachment();   	
            attach.Name='Unit Test Attachment';
            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            attach.body=bodyBlob;
            attach.parentId=newCase.id;
        insert attach;
        
		List<Attachment> attaches = new List<Attachment>();
		attaches.add(attach);
		Ca_Case_Incident_Sync.executeTrigger(attaches);
        
        if(newCase.Related_Incident__c != null)
		{
			System.debug('**** inserting test incident Attachment.');
			attach=new Attachment();   	
			attach.Name='Unit Test Attachment';
			attach.body=bodyBlob;
			attach.parentId=newCase.Related_Incident__c;
			insert attach;
			System.debug('**** Saved incident Attachment.');
			attaches = new List<Attachment>();
			attaches.add(attach);
			Ca_Case_Incident_Sync.executeTrigger(attaches);
			
		}

        Test.stopTest();
	}
}