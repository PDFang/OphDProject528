@isTest
private class ChangeRequestTaskExtensionTest {

    static testMethod void validateCCRTaskCreate() {
       	TestUtilities.insertCCRControlCustomSetting();
        //Call this method to insert change Request.
      	BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       	insert changeRequest;
       	
       	BMCServiceDesk__Status__c statusvalop = [Select Id,Name from BMCServiceDesk__Status__c where Name='OPENED'];
       	List<BMCServiceDesk__Task__c> tasks = TestUtilities.createRFTaskRecords(changeRequest,statusvalop.Id); 
       	insert tasks;
       	BMCServiceDesk__Task__c tasktoSend = [Select Id,BMCServiceDesk__templateOrder__c,
       												 BMCServiceDesk__FKOpenBy__c,BMCServiceDesk__taskDescription__c,
       												 BMCServiceDesk__duration__c,BMCServiceDesk__FKStatus__c,
       												 BMCServiceDesk__FKStatus__r.Name,RF_Task_Type__c,
       												 BMCServiceDesk__FKChange__c 
   											  from BMCServiceDesk__Task__c 
   											  where id=: tasks[1].id];
       	System.debug('tasktoSend@@@@@'+tasktoSend);
       	
       	Attachment attach=new Attachment();   	
    	attach.Name='Unit Test Attachment';
    	Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    	attach.body=bodyBlob;
        attach.parentId=changeRequest.id;
        insert attach;
       	String jsonTask = '{"data":{"attributes":{"type":"BMCServiceDesk__Task__c","url":"/services/data/v36.0/sobjects/BMCServiceDesk__Task__c/aC65B00000000MbSAI"},"Id":"'+tasks[1].Id+'","BMCServiceDesk__FKChange__c":"'+changeRequest.Id+'","BMCServiceDesk__FKOpenBy__c":"'+userInfo.getUserId()+'","BMCServiceDesk__FKStatus__c":"OPENED","RF_Task_Type__c":"Validation Task","BMCServiceDesk__taskDescription__c":"w123","BMCServiceDesk__duration__c":1,"BMCServiceDesk__FKOpenBy__r":{"attributes":{"type":"User","url":"/services/data/v36.0/sobjects/User/0055B000000Hk7kQAC"},"Name":"Mitesh Giddia","Id":"'+userInfo.getUserId()+'"},"BMCServiceDesk__FKStatus__r":{"attributes":{"type":"BMCServiceDesk__Status__c","url":"/services/data/v36.0/sobjects/BMCServiceDesk__Status__c/aBw5B0000000001SAA"},"Name":"OPENED","Id":"aBw5B0000000001SAA"},"BMCServiceDesk__dueDateTime__c":null}}';
       	Test.setCurrentPage(Page.ChangeRequestTask);
       CCRControlsClass ccrCont = new CCRControlsClass('NetworkNew');
        //instaintiate and construct the controller class
        ChangeRequestTaskExtension extension = 
	       						new ChangeRequestTaskExtension(new ApexPages.Standardcontroller(changeRequest));
   		
   		List<Attachment> attachments = extension.attachments; 
   		extension.SaveAttachment();
   		ChangeRequestTaskExtension.JSONTasks(changeRequest.Id);
   		ChangeRequestTaskExtension.JsonUpdateTask(jsonTask);
   		ChangeRequestTaskExtension.JsonTaskAssignee();
   		string taskRecordAssignee = extension.TaskRecordTypes;
   		string currentStatusValue = extension.currentStatusValue; 
   		ChangeRequestTaskExtension.ValidateRecord(tasktoSend,changeRequest);
   		ChangeRequestTaskExtension.retChange(tasktoSend,changeRequest);
   		ChangeRequestTaskExtension.ProcessUpdates(tasktoSend,changeRequest,ccrCont);
   		Boolean AllowEdits = extension.AllowEdits;
   		Boolean IsCCBMaster = extension.IsCCBMaster; 
   		Boolean UseMaintenanceWindow = extension.UseMaintenanceWindow;
   		
    }
}