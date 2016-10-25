@isTest
public class ISIntegrationHandlerClassTest {
	
    static final string PROJECT_TYPE_IT = 'IT Project Request';
    static final string PROJECT_TYPE_PSA = 'PSA Projects';
    static final string WORK_ITEM_TYPE_USER_STORY = 'User Story';
    public static final string DEFAULT_TEST_TFS_ID = '1234';    
    
    private static testmethod void  ProjectIntegrationTest(){
		
		Project__c testProject = CreateProject();
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new ISTFSINTEGRATIONCLASSMOCKTEST());
        testProject.TargetCompletionDate__c = system.today().addDays(5);
        testProject.SyncToTFS__c = true;
        update testProject;
        test.stopTest();
		
        Project__c result = [select TFSId__c, SyncToTFS__c, TFSError__c, LastSyncDate__c from Project__c where Id = :testProject.Id];        
        system.assertEquals(false, result.SyncToTFS__c);
        system.assertEquals(testProject.TFSId__c, result.TFSId__c);
        system.assertEquals(true, string.isBlank(result.TFSError__c));
        system.assertNotEquals(testProject.LastSyncDate__c, result.LastSyncDate__c);
        
        ISIntegrationHandlerClass.parseJSonstringtoId('{"Id" : 1234}');
    }
    
    private static testmethod void  ProjectCommentTest(){
        
        Project__c testProject = CreateProject();
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new ISTFSINTEGRATIONCLASSMOCKTEST(200));
        ProjectComment__c testProjectComment = new ProjectComment__c(
        		Comment__c = 'Test Integration',
            	Project__c = testProject.Id
        );
        
        insert testProjectComment;
        test.stopTest();		
        
        ProjectComment__c result = [select TFSId__c,  SyncToTFS__c, TFSError__c, LastSyncDate__c from ProjectComment__c where Id = :testProjectComment.Id];
        system.assertEquals(false, result.SyncToTFS__c);
        system.assertEquals(true, string.isBlank(result.TFSError__c));
        system.assertNotEquals(testProjectComment.LastSyncDate__c, result.LastSyncDate__c); 
        
        testProjectComment.Comment__c = 'New comment';
        testProjectComment.SyncToTFS__c = true;
        update testProjectComment;
    }
    
    private static testmethod void  WorkItemIntegrationTest(){		
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new ISTFSINTEGRATIONCLASSMOCKTEST());
        ISTFSWorkItem__c testWorkItem = CreateWorkItem();
        test.stopTest();		
        
         ISTFSWorkItem__c result = [select TFSId__c, SyncToTFS__c, TFSError__c, LastSyncDate__c from ISTFSWorkItem__c where Id = :testWorkItem.Id];        
        system.assertEquals(DEFAULT_TEST_TFS_ID, result.TFSId__c);
        system.assertEquals(false, result.SyncToTFS__c);
        system.assertEquals(true, string.isBlank(result.TFSError__c));
        system.assertNotEquals(testWorkItem.LastSyncDate__c, result.LastSyncDate__c); 
        // update work item
        testWorkItem.Team__c = 'Avengers';
		testWorkItem.SyncToTFS__c = true;
        update testWorkItem;
        
    }
	
	private static testmethod void  WorkItemCommentTest(){
        
        ISTFSWorkItem__c testWorkItem = CreateWorkItem();
    	
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new ISTFSINTEGRATIONCLASSMOCKTEST());
        ISTFSWorkItemComment__c testWorkItemComment = new ISTFSWorkItemComment__c(
        		Comment__c = 'Test Integration',
            	ParentId__c = testWorkItem.Id
        );
        
        insert testWorkItemComment;
        test.stopTest();		
        
		ISTFSWorkItemComment__c result = [select TFSId__c, SyncToTFS__c, TFSError__c, LastSyncDate__c from ISTFSWorkItemComment__c where Id = :testWorkItemComment.Id];        
        system.assertEquals(DEFAULT_TEST_TFS_ID, result.TFSId__c);
        system.assertEquals(false, result.SyncToTFS__c);
        system.assertEquals(true, string.isBlank(result.TFSError__c));
        system.assertNotEquals(testWorkItemComment.LastSyncDate__c, result.LastSyncDate__c);
        
        testWorkItemComment.Comment__c = 'New comment';
        testWorkItemComment.SyncToTFS__c = true;
        update testWorkItemComment;
    }
    
    private static testmethod void  ProjectTopicTest(){
        
        Project__c testProject = CreateProject();
        Topic testTopic = new Topic(
        	Name = 'Test Topic',
            Description = 'Test Topic'
        );
        insert testTopic;
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new ISTFSINTEGRATIONCLASSMOCKTEST());
        TopicAssignment newAssignment = new TopicAssignment(
        		EntityId = testProject.Id,
            	TopicId = testTopic.Id
        );        
        insert newAssignment;
        test.stopTest();		
        
    }

    private static testmethod void  IntegrationFailureTest(){
		
		Project__c testProject = CreateProject();
        
        test.startTest();
        // return status code 500
        Test.setMock(HttpCalloutMock.class, new ISTFSINTEGRATIONCLASSMOCKTEST(500));
        testProject.TargetCompletionDate__c = system.today().addDays(5);
        testProject.SyncToTFS__c = true;
        update testProject;
        test.stopTest();
		
		Project__c result = [select TFSId__c, SyncToTFS__c, TFSError__c, LastSyncDate__c from Project__c where Id = :testProject.Id];
        system.assertEquals(true, string.isNotBlank(result.TFSError__c));
        
    }
    
    static Project__c CreateProject(){
        
        Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c;
		Map<String,Schema.RecordTypeInfo> rtByNameMap = d.getRecordTypeInfosByName();
		
        // known issue - https://success.salesforce.com/issues_view?id=a1p300000008XHBAA2
        // No choice but not to use 'IT Project Request' record type as it sends an workflow email alert
        Project__c testProject = new Project__c(
                TargetCompletionDate__c = system.today().addDays(5),
                Priority__c = 'High',
                Summary__c = 'Test Project',
                ProblemStatement__c = 'Need a feature',
                ProjectType__c = 'Corporate IT',
                ProjectSubType__c = 'SalesForce',
                What_kind_of_request__c = 'Feature Enhancement',
                ProjectStatus__c = 'New',
                Area__c = 'SalesForce',
                Team__c = 'Operations',
                TFSId__c = DEFAULT_TEST_TFS_ID,
                RecordTypeId = rtByNameMap.get(PROJECT_TYPE_PSA).getRecordTypeId(),
            	//RecordTypeId = rtByNameMap.get(PROJECT_TYPE_IT).getRecordTypeId(),
                RequestedDeliveryDate__c = system.today().addDays(7),
                SyncToTFS__c = true
        );
        insert testProject;        
        return testProject;
    }	   
    
    static ISTFSWorkItem__c CreateWorkItem(){
        
        Project__c testProject = CreateProject();
        Schema.DescribeSObjectResult d = Schema.SObjectType.ISTFSWorkItem__c;
		Map<String,Schema.RecordTypeInfo> rtByNameMap = d.getRecordTypeInfosByName();
        
    	ISTFSWorkItem__c testWorkItem = new ISTFSWorkItem__c(
    		//AssignedTo__c, 
    		RecordTypeId = rtByNameMap.get(WORK_ITEM_TYPE_USER_STORY).getRecordTypeId(),
            Details__c = 'New work item', 
            Priority__c = 'High',
            Risk__c = 'High', 
            Area__c = 'SalesForce',
            PrivacyImpact__c = '1-None', 
            Project__c = testProject.Id, 
            StackRank__c = 10, 
            WorkItemTFSState__c = 'New', 
            StoryPoints__c = '1', 
            Team__c = 'Operations',
            Title__c = 'New work item'
		);
        
        insert testWorkItem;
        return testWorkItem;
	}
       
}