public class WorkLogEntryController 
{
    
    
    public string workTypes
    {
        get
        {
            Schema.DescribeFieldResult F = WorkLog__c.WorkPerformed__c.getDescribe();
            String[] wtList = new String[]{};
            
            for(Schema.PicklistEntry pl:F.getPicklistValues())
            {
                wtList.add(pl.getValue());
            }
            
            return JSON.Serialize(wtList);
        }
    }
    
    @RemoteAction
     public static string GetWorkLogsByDate(string selectedDate)
     {
        WorkLog__c[] worklogs = new WorkLog__c[]{};         
		
        worklogs = [Select w.WorkPerformed__c, w.WorkNotes__c, w.Project__c, w.Project__r.Name, w.Project__r.Summary__c, w.OwnerId, w.Name, w.Id, w.Hours_Worked__c, w.Date_of_Service__c From WorkLog__c w WHERE OwnerId=:UserInfo.getUserId() AND Date_of_Service__c = :date.valueOf(selectedDate + 'Z') AND Project__c <> NULL ORDER BY w.Project__r.Summary__c];
        system.debug(JSON.serialize(worklogs));
        return JSON.serialize(worklogs);       
     }
     
     @RemoteAction
     public static string UpsertWorkLog(string jsonWorkLog)
     {
         system.debug(jsonWorkLog);
         
         //work around for firefox
         map<string, object> aMap = (map<string, object>) Json.DeserializeUntyped(jsonWorkLog);
            aMap.remove('Project__c_input');
            aMap.remove('Project__r');
            string newJson = Json.serialize(aMap);
           WorkLog__c worklog = (WorkLog__c) Json.DeSerialize(newJson, WorkLog__c.class);
           
         //all other browsers work with the following line
         //WorkLog__c worklog = (WorkLog__c)JSON.deserialize(jsonWorkLog,WorkLog__c.class);
         
         
         if(string.valueOf(worklog.Id) == '')
         {
             worklog.Id = null;
         }
         
         upsert worklog;
         return JSON.serialize(worklog);
     }
     
     
     @RemoteAction
     public static string DeleteWorkLog(string workLogId)
     {
         string jsonResponse;
         
         WorkLog__c worklog = new WorkLog__c();
         worklog.Id = workLogId;
         
         jsonResponse = JSON.serialize(worklog);
         
         delete worklog;
         
         return jsonResponse;
     }
     
     @RemoteAction
     public static string SearchOpenProjects(string searchString, string currentId)
     {
         Project__c[] projects = new Project__c[]{};
     
     
         if(searchString.length() < 2)
         {
             if(currentId != '')
             {
                 projects = [SELECT Id, Name, Summary__c  FROM Project__c WHERE Id = :currentId OR (OwnerId=:UserInfo.getUserId() AND ClosedDate__c = NULL) ORDER BY LastModifiedDate DESC LIMIT 10];
             }
             else
             {
                 projects = [SELECT Id, Name, Summary__c  FROM Project__c WHERE OwnerId=:UserInfo.getUserId() AND ClosedDate__c = NULL ORDER BY LastModifiedDate DESC LIMIT 10];
             }
         }
         else
         {
             
             List<List<SObject>> searchList = [FIND :searchString IN ALL FIELDS
                                                 RETURNING Project__c (Id,Name, Summary__c WHERE ClosedDate__c = NULL) 
                                                 LIMIT 20];
             projects = (Project__c[])searchList[0];
         }
                         
         List<DropDown> options = new List<DropDown>(); 
        
        for(Project__c p:projects)
        {
            options.add(new DropDown(p.Id, p.Name + ' - ' + p.Summary__c)); 
        
        }
                                 
        return JSON.serialize(options);
        //return 'dummy';
     }
    

     
     @RemoteAction
     public static String calendarControl(string stringDate)
     {
             date selectedDate = date.valueOf(stringDate);
             //start table string        
             string results = '<table class="calendar" cellspacing="0" >';
             
             //get first date of the month
             Date monthStart = selectedDate.toStartOfMonth();
             //determine how many days in the month
             Integer numberDays = date.daysInMonth(selectedDate.Year(),selectedDate.Month());
             //days to skip determines the DOW of the first day of the month and how many columns to skip before entering the first value
             Integer daysToSkip = monthStart.toStartOfWeek().daysBetween(monthStart);
             //iterators
             Integer dayCount = daysToSkip;
             Double totalHours = 0;
             date previousMonth = selectedDate.addMonths(-1).toStartOfMonth();
             date nextMonth = selectedDate.addMonths(1).toStartOfMonth();
             
             List<AggregateResult> monthWorkLogs = new List<AggregateResult>();
             monthWorkLogs = [SELECT Date_of_Service__c sDate, SUM(Hours_Worked__c) Hours FROM WorkLog__c WHERE OwnerId=:UserInfo.getUserId() AND CALENDAR_YEAR(Date_of_Service__c) = :selectedDate.year() AND CALENDAR_MONTH(Date_of_Service__c) = :selectedDate.month() GROUP BY Date_of_Service__c ORDER BY Date_of_Service__c];
                 
             
             //table header
             results = results + '<tr>';
             results = results + '<th ><a class="datelink" href="#" onclick="setFormDate(new Date(' + String.valueOf(previousMonth.year()) + ',' + String.valueOf(previousMonth.month()-1) + ',' + String.valueOf(previousMonth.day()) + '))"><<</a></th>';
             results = results + '<th colspan="5">' + datetime.newInstance(selectedDate,time.newInstance(0,0,0,0)).format('MMMM') + ' ' + string.valueOf(selectedDate.year()) + '</th>';
             results = results + '<th ><a class="datelink" href="#" onclick="setFormDate(new Date(' + String.valueOf(nextMonth.year()) + ',' + String.valueOf(nextMonth.month()-1) + ',' + String.valueOf(nextMonth.day()) + '))">>></a></th>';
             results = results + '</tr>';
             results = results + '<tr><th style="width:75px">Sunday</th><th style="width:75px">Monday</th><th style="width:75px">Tuesday</th><th style="width:75px">Wednesday</th><th style="width:75px">Thursday</th><th style="width:75px">Friday</th><th style="width:75px">Saturday</th></tr></thead><tr>';
             
             //if the month doesn't start on a sunday add a column to span the number of days before the first
             if(daysToSkip != 0)
             {
                     results = results + '<td colspan="' + daysToSkip + '"></td>';

             }
             
             //loop through each day of the month
             for(integer i=1;i <= numberDays;i++)
             {
                 //make a new row when daycount hits a multiple of 7
                 if(dayCount == 7 || dayCount == 14 || dayCount == 21 || dayCount == 28 || dayCount == 35)
                 {
                     results = results + '</tr><tr>';
                 }
                 
                 //add column with date 
                 results = results + '<td >';
                 //results = results + '<div ><a class="datelink" href="/apex/worklogentry?date=' + EncodingUtil.urlEncode(String.valueOf(monthStart),'UTF-8') + '">'  + monthStart.format() + '</a></div>';
                 results = results + '<div ><a class="datelink" href="#" onclick="setFormDate(new Date(' + String.valueOf(monthStart.year()) + ',' + String.valueOf(monthStart.month()-1) + ',' + String.valueOf(monthStart.day()) + '))">'  + monthStart.format() + '</a></div>';
                 
                 boolean wlMatch = false;
                 //loop through worklogs to see if any match the date
                 
                 if(monthStart == selectedDate){
                     results = results + '<div class="selected-date">';
                 } else {
                     results = results + '<div>';
                 }
                 
                 //parse out aggregate results into new class for display
                 
                    List<MonthlyWorklogs> mWorklogs = new List<MonthlyWorklogs>();
                    
                    for(AggregateResult ar:monthWorkLogs)
                    {
                        MonthlyWorklogs mwl = new MonthlyWorklogs();
                        mwl.ServiceDate = (Date)ar.get('sDate');
                        mwl.HoursWorked = (Double)ar.get('Hours');
                        mWorkLogs.add(mwl);
                    }    
                 for(MonthlyWorkLogs ml:mWorkLogs)
                 {
                     if(monthStart == ml.ServiceDate)
                     {
                        results = results + string.valueOf(ml.HoursWorked);
                        totalHours = totalHours + ml.HoursWorked;
                        //flag there is a match
                        wlMatch = true;
                     }
                 }
                 
                 //if no worklogs match the date put in 0.0
                 if(!wlMatch)
                 {
                      results = results + '0.0';
                 }
                 
                 //close column
                 results = results + '</div></td>';
                 
                 //interate through date and days
                 monthStart = monthStart.addDays(1);
                 dayCount = dayCount + 1;
             }
             
             //close out calendar table
             results = results + '</tr>';
             results = results + '<tr><td colspan="7">Total Hours: ' + string.valueOf(totalHours) + '</td></tr>';
             results = results + '</table>';
             return results;   
   
     }    

     
     
     public Class DropDown
    {
        public string label;
        public string value;
        
        public DropDown(string valueString, string labelString)
        {
            label = labelString;
            value = valueString;
        }
    }
    
    
     //class to store values from aggregate results of worklogs
     public class MonthlyWorklogs
     {
         public Date serviceDate {get;set;}
         public Double hoursWorked {get;set;}
        
     }
     

}