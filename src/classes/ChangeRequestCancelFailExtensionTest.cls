@isTest
private class ChangeRequestCancelFailExtensionTest {

    static testMethod void validateCCRCancel() {
        //Insert a new custom setting
        TestUtilities.insertCCRControlCustomSetting();
      
        //Call this method to insert change Request.
      	BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       	insert changeRequest;
       	
       	BMCServiceDesk__Change_Request__c changeRequest2 = [Select Id,BMCServiceDesk__FKStatus__c,RF_Risk_Level__c,
       															   BMCServiceDesk__FKStatus__r.Name 
       														from BMCServiceDesk__Change_Request__c 
       														where Id=:changeRequest.Id];
   		
   		BMCServiceDesk__Status__c statusval = [Select Id,Name from BMCServiceDesk__Status__c where Name='PEER REVIEW'];
       	changeRequest2.BMCServiceDesk__FKStatus__c = statusval.Id;
       	changeRequest2.BMCServiceDesk__FKStatus__r.Name = statusval.Name;
       	update changeRequest2;
       	BMCServiceDesk__Status__c statusvalop = [Select Id,Name from BMCServiceDesk__Status__c where Name='OPENED'];
       	List<BMCServiceDesk__Task__c> tasks = TestUtilities.createRFTaskRecords(changeRequest,statusvalop.id); 
       	insert tasks;
       	Test.setCurrentPage(Page.ChangeRequestCancelFail);
       
        //instaintiate and construct the controller class
        ChangeRequestCancelFailExtension extension = 
	       						new ChangeRequestCancelFailExtension(new ApexPages.Standardcontroller(changeRequest2));
   	    extension.CloseCCR();
   	    extension.cancel();
   	    String DisplayString = extension.DisplayString;
    }
    
     static testMethod void validateCCRFail() {
        //Insert a new custom setting
        TestUtilities.insertCCRControlCustomSetting();
        //Call this method to insert change Request.
      	BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       	insert changeRequest;
       	
       	BMCServiceDesk__Change_Request__c changeRequest2 = [Select Id,BMCServiceDesk__FKStatus__c,RF_Risk_Level__c,
       															   BMCServiceDesk__FKStatus__r.Name 
       														from BMCServiceDesk__Change_Request__c 
       														where Id=:changeRequest.Id];
   		
   		BMCServiceDesk__Status__c statusval = [Select Id,Name from BMCServiceDesk__Status__c where Name='READY FOR DEPLOYMENT'];
       	changeRequest2.BMCServiceDesk__FKStatus__c = statusval.Id;
       	changeRequest2.BMCServiceDesk__FKStatus__r.Name = statusval.Name;
       	update changeRequest2;
       	
       	BMCServiceDesk__Status__c statusvalop = [Select Id,Name from BMCServiceDesk__Status__c where Name='OPENED'];
       	List<BMCServiceDesk__Task__c> tasks = TestUtilities.createRFTaskRecords(changeRequest,statusvalop.id); 
       	insert tasks;
        Test.setCurrentPage(Page.ChangeRequestCancelFail);
       
        //instaintiate and construct the controller class
        ChangeRequestCancelFailExtension extension = 
       						new ChangeRequestCancelFailExtension(new ApexPages.Standardcontroller(changeRequest2));
   	    extension.CloseCCR();
   	    extension.cancel();
   	    String DisplayString = extension.DisplayString;
    }
}