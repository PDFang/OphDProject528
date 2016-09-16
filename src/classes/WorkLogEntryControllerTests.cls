@isTest
public class WorkLogEntryControllerTests 
{
    
    static testMethod void TestWorkLogEntryController()
    {
        Project__c proj = new Project__c();
        proj.Summary__c = 'Test';
        
        insert proj;
        
        List<WorkLog__c> logs = new List<WorkLog__c>();
        for(Integer i=0;i<10;i++)
        {
            WorkLog__c wl = new WorkLog__c();
            wl.Date_of_Service__c = system.today();
            wl.Hours_Worked__c = 10 + i;
            wl.Project__c = proj.Id;
            logs.add(wl);
        }
        insert logs;
        
        WorkLogEntryController controller = new WorkLogEntryController();
        
        string jsonWorkTypes = controller.workTypes;
        string worklogsByDate = WorkLogEntryController.GetWorkLogsByDate(string.valueOf(system.today()));
        string searchProjects = WorkLogEntryController.SearchOpenProjects('searchString', null);
        
        logs[0].Hours_Worked__c = 1;
        update logs[0];
        
        string upsertString = WorkLogEntryController.UpsertWorkLog(JSON.serialize(logs[0]));
        
        WorkLog__c checkUpdate = [SELECT Hours_Worked__c FROM WorkLog__c WHERE Id = :logs[0].Id];
        system.assertEquals(1.0, checkUpdate.Hours_Worked__c);
        
        string deleteString = WorkLogEntryController.DeleteWorkLog(logs[0].Id);
        
        system.assertEquals(0,[SELECT Count() FROM WorkLog__c WHERE Id = :logs[0].Id]);
        string calendarString = WorkLogEntryController.calendarControl(string.valueOf(system.today()));
        
        
        
    }
    
    
    
}