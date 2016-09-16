@isTest
private class CcrViewExtensionTest {

    static testMethod void validateCCRView() {
        //Insert a new custom setting
        TestUtilities.insertCCRControlCustomSetting();
      
        //Call this method to insert change Request.
      	BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       	insert changeRequest;
       	string ccrId = string.valueof(changeRequest.Id);
       	Test.setCurrentPage(Page.ChangeRequestView);
       
        //instaintiate and construct the controller class
        CcrViewExtension extension = 
	       						new CcrViewExtension(new ApexPages.Standardcontroller(changeRequest));
   		extension.ReleaseValueListfromAction();
   		CcrViewExtension.ReleaseValueList(ccrId);
    }
}