@isTest
private class ChangeRequestApproversExtensionsTest {

    static testMethod void ValidateCCRApprove() {
    	//Insert a new custom setting
       TestUtilities.insertCCRControlCustomSetting();
        
        //Call ChangeControlRequest object
        ChangeControlRequest__c changeControlRequest = 
       						new ChangeControlRequest__c(Summary__c = 'Test summary', 
       															  CCRStartTime__c= system.today(),
       															  ChangeReason__c = 'Fix'  ,
       															  Monitoring_set_up_on_device__c='Yes',
       															  Impact__c = 'SEV 1',
       															  Urgency__c = 'HIGH',
       															  RFCType__c = 'NORMAL',
       															  Cluster__c = 'B2;B3',
       															  Release__c = 'Future',
       															  ContingencyOwner__c = userInfo.getUserId(),
       															  ContingencyDeadline__c = system.today()+ 4,
       															  Description__c = 'Test summary',
       															  DescriptionOfTesting__c = 'Test summary',
       															  ContingencyPlan__c = 'Test summary',
       															  ReleaseDate__c = system.today() +4,
       															  SystemsAppsProcessesImpacted__c = 'Test summary',
       															  Experience__c = '0 - This has been successfully completed before',
       															  PrepTimeRequired__c = '3 - 15-30 days',
       															  RequiresUserEducation__c = '2 - Minimal',
       															  BusinessImpact__c ='3 - Major, not high profile' ,
       															  Documentation__c = '4 - Considerable amount',
       															  ResourcesRequired__c = '2 - 2 people, same group',
       															  MaintenanceWindow__c = '8 - Outside',
       															  Security__c = '2 - Access affected',
       															  Validation__c = '3 - Minor',
       															  Backout__c = '2 - In place, easy to do',
       															  OutageScope__c = '6 - Partial System'
       															  );
  
       insert changeControlRequest; 
       
       
       //insert user to add in approvers 
       Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
       
      	User u1 = new User(Alias = 'test1', Email='test1@testorg.com', 
      	EmailEncodingKey='UTF-8', LastName='testTesting1', LanguageLocaleKey='en_US', 
      	LocaleSidKey='en_US', ProfileId = p.Id, 
      	TimeZoneSidKey='America/Los_Angeles', UserName='test17654@testorg.com');
      	
      	User u2 = new User(Alias = 'test2', Email='test2@testorg.com', 
      	EmailEncodingKey='UTF-8', LastName='testTesting2', LanguageLocaleKey='en_US', 
      	LocaleSidKey='en_US', ProfileId = p.Id, 
      	TimeZoneSidKey='America/Los_Angeles', UserName='test298765@testorg.com');
      	insert u1;
      	insert u2;
        //Call this method to insert change Request.
       BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       insert changeRequest;
       
       BMCServiceDesk__Status__c statusvalop = [Select Id,Name from BMCServiceDesk__Status__c where Name='OPENED'];
       List<BMCServiceDesk__Task__c> tasks = TestUtilities.createRFTaskRecords(changeRequest,statusvalop.id); 
       insert tasks;
       CCRApprover__c approver1 = new CCRApprover__c(Approver__c= userinfo.getUserId(),
       												  ChangeControlRequest__c = changeControlRequest.Id,
       												  	RF_Change_Request__c = changeRequest.Id);
   	   CCRApprover__c approver2 = new CCRApprover__c(Approver__c= u1.Id,
       												  ChangeControlRequest__c = changeControlRequest.Id,
       												  	RF_Change_Request__c = changeRequest.Id);
   	   CCRApprover__c approver3 = new CCRApprover__c(Approver__c= u2.Id,
       												  ChangeControlRequest__c = changeControlRequest.Id,
       												  	RF_Change_Request__c = changeRequest.Id);
       insert approver1;
       insert approver2;
       insert approver3;
       Test.setCurrentPage(Page.ChangeRequestApprovers);
       
       //instaintiate and construct the controller class
       ChangeRequestApproversExtensions extension = 
       						new ChangeRequestApproversExtensions(new ApexPages.Standardcontroller(changeRequest));
   	   extension.Save();
   	   Boolean template = extension.SetTemplate;
   	   extension.Initialize();
   	   extension.ApproveCcr();
   	   extension.GoToCcr();
   	   List<SelectOption> approvers = extension.Approvers;
   	   List<Id> selectedApprover = extension.SelectedApprovers;
   	   Boolean renderedPage = extension.Rendered;
       
        
    }
}