@isTest
public class CorporateItWebServicesTests
{
    static testMethod void LogFeatureTime()
    {
        Project__c proj = new Project__c();
        proj.Summary__c = 'Unit Test';
        proj.TFSId__c = '99999';
        insert proj;

        CorporateItWebServices.CreateWorkLog('99999', 'Test', UserInfo.getUserEmail(), 2);
        CorporateItWebServices.CreateWorkLog('12345', 'Test', UserInfo.getUserEmail(), 2);  //test no project
        CorporateItWebServices.CreateWorkLog('99999', 'Test', UserInfo.getUserEmail(), 0);  //test 0 hours

        Worklog__c[] wl = [SELECT Id, Hours_Worked__c FROM Worklog__c WHERE Project__c = :proj.Id];
        system.assertEquals(wl.size(), 1);
        system.assertEquals(integer.valueOf(wl[0].Hours_Worked__c), 2);

    }
}