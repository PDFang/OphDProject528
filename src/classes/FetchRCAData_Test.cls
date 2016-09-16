@isTest(seealldata=false)
public class FetchRCAData_Test {
static testMethod void unitTest()
{
BMCServiceDesk__Category__c cat = new BMCServiceDesk__Category__c(Name='Test Category');
insert cat;
BMCServiceDesk__Category__c fetchCat = [Select Id from BMCServiceDesk__Category__c where Id=:cat.id];
BMCServiceDesk__Problem__c prb = new BMCServiceDesk__Problem__c(BMCServiceDesk__Problem_Source__c='Email',BMCServiceDesk__FKCategory__c=fetchCat.Id,Ca_Summary__c='XYZ',BMCServiceDesk__Problem_Description__c='Test',RF_Symptoms_Customer_Experience__c='QM-Security');
insert prb;
PageReference pref = Page.RF_RCA_Problem_Details;
    pref.getParameters().put('id',prb.id);
    Test.setCurrentPage(pref);
FetchRCAData testObj = new FetchRCAData();
testObj.sendPdf();
}
}