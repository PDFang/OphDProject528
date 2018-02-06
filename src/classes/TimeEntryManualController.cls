/**
 * Created by Arnab on 1/31/2018.
 */

public class TimeEntryManualController {

    public string comment{get;set;}
    public final static integer numberOfRows = 5;
    public string currentId{get; set;}
    public List<TimeEntryWrapperClass> TimeEntryList{get; set;}

    public TimeEntryManualController(ApexPages.StandardController controller){
        WorkIt2__Timing__c timing = (WorkIt2__Timing__c)controller.getRecord();
        currentId = timing.Id;
        refreshTableEntry();
    }

    public void refreshTableEntry(){
        TimeEntryList = new list<TimeEntryWrapperClass>();
        for(integer i = 0; i < numberOfRows; i++){
            TimeEntryList.add(new TimeEntryWrapperClass(i,null,'', ''));
        }
    }

    @RemoteAction
    public static string SaveTime(list<TimeEntryWrapperClass> wrapperClasses, string currentId){
        list<WorkIt2__Time_Entry__c> timeEntries = new list<WorkIt2__Time_Entry__c>();
        try{
            WorkIt2__Session_Type__c sessionType = [select Id from WorkIt2__Session_Type__c where Name = 'Default Session' Limit 1];
            for(TimeEntryWrapperClass timeEntrywrapper : wrapperClasses){
                WorkIt2__Time_Entry__c timeEntry = new WorkIt2__Time_Entry__c();
                timeEntry.WorkIt2__Timing__c = currentId;
                string startTime = timeEntrywrapper.TimeRange.substring(0, timeEntrywrapper.TimeRange.indexOf('~'));
                string endTime = timeEntrywrapper.TimeRange.substring(timeEntrywrapper.TimeRange.indexOf('~') + 1, timeEntrywrapper.TimeRange.length());
                timeEntry.WorkIt2__Start__c = getDateTimeFromString(timeEntrywrapper.EntryDate + ' ' + startTime);
                timeEntry.WorkIt2__Force_End__c = getDateTimeFromString(timeEntrywrapper.EntryDate + ' ' + endTime);
                if(endTime == '12:00 AM')
                    timeEntry.WorkIt2__Force_End__c =  timeEntry.WorkIt2__Force_End__c.addDays(1);
                timeEntry.WorkIt2__Session_Type__c = sessionType.Id;
                timeEntry.WorkIt2__Comment__c = timeEntrywrapper.Comment;
                timeEntries.add(timeEntry);
            }

            insert timeEntries;

            return 'Success';

        }catch (Exception ex){
            string message = ex.getMessage();
            if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                Integer occurence = message.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
                message = message.mid(occurence, message.length());
                occurence = message.lastIndexOf(':');
                message = message.mid(0, occurence);
            }
            else {
                message = ex.getMessage();
            }
            return message;
        }


    }

    private static dateTime getDateTimeFromString(string dateTimeString){
        DateTime theDate = DateTime.parse(dateTimeString);
      //  String convertedDate = theDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        System.debug('theDate ==> '+theDate);
        return theDate;
    }

    public class TimeEntryWrapperClass{
        public integer RowId{get;set;}
        public string  EntryDate{get;set;}
        public string TimeRange{get;set;}
        public string Comment{get;set;}

        public TimeEntryWrapperClass(integer rowIdInteger, string entryDateStr, string timeRangeString, string commentString){
            this.EntryDate = entryDateStr;
            this.TimeRange = timeRangeString;
            this.Comment = commentString;
            this.RowId = rowIdInteger;
        }

    }


}