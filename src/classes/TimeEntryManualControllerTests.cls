/**
 * Created by jeremy.sparrell on 2/8/2018.
 */

@IsTest
private class TimeEntryManualControllerTests {
    static WorkIt2__Timing__c timing;
    static WorkIt2__Session_Type__c session_type;
    static list<WorkIt2__Time_Entry__c> timeEntryList;

    static testMethod void testController() {
        createTimingData();

        List<TimeEntryManualController.TimeEntryWrapperClass> entries = new List<TimeEntryManualController.TimeEntryWrapperClass>();

        Test.startTest();
        TimeEntryManualController.TimeEntryWrapperClass entry = new TimeEntryManualController.TimeEntryWrapperClass(0,'1/1/2017','10:00 AM~11:00 AM', 'Test');
        entries.add(entry);

        TimeEntryManualController controller = new TimeEntryManualController(new ApexPages.StandardController(timing));
        string savedTime = TimeEntryManualController.SaveTime(entries, timing.Id);
        Test.stopTest();
    }

    static void createTimingData() {
        session_type = new WorkIt2__Session_Type__c(
                Name = 'Default Session',
                WorkIt2__Priority__c = 50
        );

        insert session_type;

        Case newCase = new Case();

        insert newCase;

        timing = new WorkIt2__Timing__c(
            WorkIt2__Case__c = newCase.Id
        );

        insert timing;

        timeEntryList = new list<WorkIt2__Time_Entry__c>();

        WorkIt2__Time_Entry__c time_entry1 = new WorkIt2__Time_Entry__c(
                WorkIt2__Session_Type__c = session_type.Id,
                WorkIt2__Start__c = System.now().addHours(-1),
                WorkIt2__Timing__c = timing.Id
        );
        timeEntryList.add(time_entry1);

        insert timeEntryList;
    }
}