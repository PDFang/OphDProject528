@isTest
public class WebserviceUpdateFromTFSTest {

    private static final string WORK_ITEM_TYPE_USER_STORY = 'User Story';
    private static final string PROJECT_TYPE_PSA = 'PSA Projects';
    
    
    
    private static ISTFSWorkItem__c CreateWorkItem(){        
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
    
    private static Project__c CreateProject(){
         
        Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c;
		Map<String,Schema.RecordTypeInfo> rtByNameMap = d.getRecordTypeInfosByName();
		

        Project__c testProject = new Project__c(
                TargetCompletionDate__c = system.today().addDays(5),
                Priority__c = 'High',
                Summary__c = 'Test Project',
                ProblemStatement__c = 'Need a feature',
                ProjectType__c = 'Corporate IT',
                ProjectSubType__c = 'Salesforce',
                What_kind_of_request__c = 'Feature Enhancement',
                ProjectStatus__c = 'New',
                Area__c = 'SalesForce',
                Team__c = 'Operations',               
                RecordTypeId = rtByNameMap.get(PROJECT_TYPE_PSA).getRecordTypeId(),
                RequestedDeliveryDate__c = system.today().addDays(7),
                SyncToTFS__c = false
        );
        insert testProject;        
        return testProject;
    }
    
    
    
    public static testMethod void testProjectUpdate()
    {
        Project__c testProject = CreateProject();
      //  ISTFSWorkItem__c testWorkItem = CreateWorkItem();
 
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
      	User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com');

        
        
        WebServiceUpdateFromTFS.WorkItemsWrapperParams wrapperParams = new WebServiceUpdateFromTFS.WorkItemsWrapperParams();
        wrapperParams.SalesforceRecordId = testProject.Id;
        wrapperParams.AssignedTo = 'Testing';
        wrapperParams.StackRank =  1258456325;
        wrapperParams.State =  'Active';
        wrapperParams.Description =  'Test Description';
        wrapperParams.Title =   'TEST PROJECT';   
        wrapperParams.Team =  'Avengers';
        wrapperParams.Priority = 'Normal';
 		wrapperParams.Iteration = 'TFS';
        wrapperParams.StoryPoints = '5';
        wrapperParams.Comment = '';
        wrapperParams.Tags = new list<string>{'TEST1', 'TEST2'};
        
        list<WebServiceUpdateFromTFS.WorkItemsWrapperParams> lstParams = new  list<WebServiceUpdateFromTFS.WorkItemsWrapperParams>();
        lstParams.add(wrapperParams);
        
        Test.startTest();
        
        WebServiceUpdateFromTFS.UpdateTFSItems(lstParams);
         
           Test.stopTest();  
            
    }
    
    
}