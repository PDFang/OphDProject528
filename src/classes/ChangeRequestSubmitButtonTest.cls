@isTest
private class ChangeRequestSubmitButtonTest {

    static testMethod void validateSubmitCCR() {
       //Insert a new custom setting
        TestUtilities.insertCCRControlCustomSetting();
        
        //Call this method to insert change Request.
      	BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       	insert changeRequest;
       	
       	//insert user to add in approvers 
       Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
       
      	User u1 = new User(Alias = 'test1', Email='test1@testorg.com', 
      	EmailEncodingKey='UTF-8', LastName='testTesting1', LanguageLocaleKey='en_US', 
      	LocaleSidKey='en_US', ProfileId = p.Id, 
      	TimeZoneSidKey='America/Los_Angeles', UserName='test176523454@testorg.com');
       	insert u1;
       	
       	BMCServiceDesk__Change_Request__c changeRequest2 = [Select Id,BMCServiceDesk__FKStatus__c,RF_Risk_Level__c,
       															   BMCServiceDesk__FKStatus__r.Name 
       														from BMCServiceDesk__Change_Request__c 
       														where Id=:changeRequest.Id];
   		
   		BMCServiceDesk__Status__c statusval = [Select Id,Name from BMCServiceDesk__Status__c where Name='OPENED'];
       	changeRequest2.BMCServiceDesk__FKStatus__c = statusval.Id;
       	changeRequest2.BMCServiceDesk__FKStatus__r.Name = statusval.Name;
       	update changeRequest2;
       	BMCServiceDesk__Status__c statusvalop = [Select Id,Name from BMCServiceDesk__Status__c where Name='OPENED'];
       	List<BMCServiceDesk__Task__c> tasks = TestUtilities.createRFTaskRecords(changeRequest2,statusvalop.Id); 
       	insert tasks;
       	Test.setCurrentPage(Page.ChangeRequestSubmit);
       	List<Id> peerList = new list<Id>();
       	peerList.add(u1.Id);
       	Attachment attach=new Attachment();   
       	
        //instaintiate and construct the controller class
        ChangeRequestSubmitButton extension = 
	       						new ChangeRequestSubmitButton(new ApexPages.Standardcontroller(changeRequest2));
	    extension.peerReviewUsers = peerList;
   	    extension.calculateTask(changeRequest2.Id);
   	    extension.ReturnToCCR();
   	    extension.needsTestPlan = true;
   	    extension.testPlan = attach;
   	    extension.SubmitPlans();
   	    extension.CloseCCR();
   	    extension.Back();
   	    List<SelectOption> selecopts = extension.UserList;
    }
    
    static testMethod void validateSubmitCCRForDeployed() {
       //Insert a new custom setting
        TestUtilities.insertCCRControlCustomSetting();
        
        //Call this method to insert change Request.
      	BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       	insert changeRequest;
       	
       	BMCServiceDesk__Change_Request__c changeRequest2 = [Select Id,BMCServiceDesk__FKStatus__c,RF_Risk_Level__c,
       															   BMCServiceDesk__FKStatus__r.Name 
       														from BMCServiceDesk__Change_Request__c 
       														where Id=:changeRequest.Id];
   		
   		BMCServiceDesk__Status__c statusval = [Select Id,Name from BMCServiceDesk__Status__c where Name='DEPLOYED'];
       	changeRequest2.BMCServiceDesk__FKStatus__c = statusval.Id;
       	changeRequest2.BMCServiceDesk__FKStatus__r.Name = statusval.Name;
       	update changeRequest2;
       	
       	system.debug('updateCCR '+changeRequest2.BMCServiceDesk__FKStatus__c);
       	BMCServiceDesk__Status__c statusvalop = [Select Id,Name from BMCServiceDesk__Status__c where Name='OPENED'];
       	List<BMCServiceDesk__Task__c> tasks = TestUtilities.createRFTaskRecords(changeRequest,statusvalop.Id); 
       	insert tasks;
       	Test.setCurrentPage(Page.ChangeRequestSubmit);
       
        //instaintiate and construct the controller class
        ChangeRequestSubmitButton extension = 
	       						new ChangeRequestSubmitButton(new ApexPages.Standardcontroller(changeRequest2));
   	    extension.ReturnToCCR();
   	    extension.SubmitPlans();
    }
    
     static testMethod void validateSubmitCCRForRejected() {
       //Insert a new custom setting
        TestUtilities.insertCCRControlCustomSetting();
        
        //Call this method to insert change Request.
      	BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       	insert changeRequest;
       	
       	BMCServiceDesk__Change_Request__c changeRequest2 = [Select Id,BMCServiceDesk__FKStatus__c,RF_Risk_Level__c,
       															   BMCServiceDesk__FKStatus__r.Name 
       														from BMCServiceDesk__Change_Request__c 
       														where Id=:changeRequest.Id];
   		
   		BMCServiceDesk__Status__c statusval = [Select Id,Name from BMCServiceDesk__Status__c where Name='PEER REVIEW REJECTED'];
       	changeRequest2.BMCServiceDesk__FKStatus__c = statusval.Id;
       	changeRequest2.BMCServiceDesk__FKStatus__r.Name = statusval.Name;
       	update changeRequest2;
       	
       	system.debug('updateCCR '+changeRequest2.BMCServiceDesk__FKStatus__c);
       	BMCServiceDesk__Status__c statusvalop = [Select Id,Name from BMCServiceDesk__Status__c where Name='OPENED'];
       	List<BMCServiceDesk__Task__c> tasks = TestUtilities.createRFTaskRecords(changeRequest,statusvalop.Id); 
       	insert tasks;
       	Test.setCurrentPage(Page.ChangeRequestSubmit);
       
        //instaintiate and construct the controller class
        ChangeRequestSubmitButton extension = 
	       						new ChangeRequestSubmitButton(new ApexPages.Standardcontroller(changeRequest2));
   	    extension.ReturnToCCR();
   	    extension.SubmitPlans();
    }
    static testMethod void validateSubmitCCRForNoValidation() {
       //Insert a new custom setting
        TestUtilities.insertCCRControlCustomSetting();
        
        //Call this method to insert change Request.
      	BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       	insert changeRequest;
       	
       	BMCServiceDesk__Change_Request__c changeRequest2 = [Select Id,BMCServiceDesk__FKStatus__c,RF_Risk_Level__c,
       															   BMCServiceDesk__FKStatus__r.Name 
       														from BMCServiceDesk__Change_Request__c 
       														where Id=:changeRequest.Id];
   		Attachment attach=new Attachment();  
   		BMCServiceDesk__Status__c statusval = [Select Id,Name from BMCServiceDesk__Status__c where Name='APPROVED'];
       	changeRequest2.BMCServiceDesk__FKStatus__c = statusval.Id;
       	changeRequest2.BMCServiceDesk__FKStatus__r.Name = statusval.Name;
       	update changeRequest2;
       	
       	Test.setCurrentPage(Page.ChangeRequestSubmit);
       
        //instaintiate and construct the controller class
        ChangeRequestSubmitButton extension = 
	       						new ChangeRequestSubmitButton(new ApexPages.Standardcontroller(changeRequest2));
   	    extension.ReturnToCCR();
   	    extension.testPlan = attach;
   	    extension.SubmitPlans();
    }
    static testMethod void validateSubmitCCRApproved() {
       //Insert a new custom setting
        TestUtilities.insertCCRControlCustomSetting();
        
        //Call this method to insert change Request.
      	BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       	insert changeRequest;
       	
       	BMCServiceDesk__Change_Request__c changeRequest2 = [Select Id,BMCServiceDesk__FKStatus__c,RF_Risk_Level__c,
       															   BMCServiceDesk__FKStatus__r.Name 
       														from BMCServiceDesk__Change_Request__c 
       														where Id=:changeRequest.Id];
   		
   		BMCServiceDesk__Status__c statusval = [Select Id,Name from BMCServiceDesk__Status__c where Name='APPROVED'];
       	changeRequest2.BMCServiceDesk__FKStatus__c = statusval.Id;
       	changeRequest2.BMCServiceDesk__FKStatus__r.Name = statusval.Name;
       	update changeRequest2;
       	
       	system.debug('updateCCR '+changeRequest2.BMCServiceDesk__FKStatus__c);
       	BMCServiceDesk__Status__c statusvalop = [Select Id,Name from BMCServiceDesk__Status__c where Name='OPENED'];
       	List<BMCServiceDesk__Task__c> tasks = TestUtilities.createRFTaskRecords(changeRequest,statusvalop.Id); 
       	insert tasks;
       	Test.setCurrentPage(Page.ChangeRequestSubmit);
       
        //instaintiate and construct the controller class
        ChangeRequestSubmitButton extension = 
	       						new ChangeRequestSubmitButton(new ApexPages.Standardcontroller(changeRequest2));
   	    extension.ReturnToCCR();
   	    extension.SubmitPlans();
    }
}