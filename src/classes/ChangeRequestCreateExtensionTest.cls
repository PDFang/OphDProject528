@isTest
private class ChangeRequestCreateExtensionTest {

    static testMethod void validateNewCCRSubmission() {
       /*This test method validate the scenario where we creating a new change Request.*/
       
        TestUtilities.insertCCRControlCustomSetting();
        list<BMCServiceDesk__Urgency__c> urgencies = TestUtilities.createRFUrgencyRecords();
        list<BMCServiceDesk__Impact__c> impacts = TestUtilities.createRFImpactRecords();
        insert urgencies;
        insert impacts;
        //Call this method to insert change Request.
       BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       insert changeRequest;
       Test.setCurrentPage(Page.ChangeRequestCreate);
       ApexPages.currentPage().getParameters().put('clone','0');
       //instaintiate and construct the controller class
       ChangeRequestCreateExtension extension = 
       						new ChangeRequestCreateExtension(new ApexPages.Standardcontroller(changeRequest));
       //Use pageReference apex class to instantiate a page
       
       extension.save();
    }
    
    static testMethod void validatecloneCCRSubmissions() {
       /*This test method validate the scenario where we creating a new change Request.*/
       
        TestUtilities.insertCCRControlCustomSetting();
        list<BMCServiceDesk__Urgency__c> urgencies = TestUtilities.createRFUrgencyRecords();
        list<BMCServiceDesk__Impact__c> impacts = TestUtilities.createRFImpactRecords();
        insert urgencies;
        insert impacts;
        
        //Call this method to insert change Request.
       BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       insert changeRequest;
       BMCServiceDesk__Status__c statusvalop = [Select Id,Name from BMCServiceDesk__Status__c where Name='OPENED'];
       List<BMCServiceDesk__Task__c> tasks = TestUtilities.createRFTaskRecords(changeRequest,statusvalop.Id); 
       insert tasks;
       Test.setCurrentPage(Page.ChangeRequestCreate);
       ApexPages.currentPage().getParameters().put('clone','1');
       ApexPages.currentPage().getParameters().put('tlInd','2');
       //instaintiate and construct the controller class
       ChangeRequestCreateExtension extension = 
       						new ChangeRequestCreateExtension(new ApexPages.Standardcontroller(changeRequest));
       //Use pageReference apex class to instantiate a page
       
       extension.save();
       extension.DeleteRow();
       List<BMCServiceDesk__Task__c> tasksGetProperty = extension.CCRTaskList;
       String ReleaseValue = extension.ReleaseValues;
       Boolean useMaintenance = extension.UseMaintenanceWindow;
       Boolean cloneRecord = extension.IsCloneRecord;
    }
}