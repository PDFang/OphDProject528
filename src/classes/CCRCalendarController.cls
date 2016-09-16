public class CCRCalendarController 
{    
    private Date selectedDate;
    private string selectedMonth;
    private List<ChangeControlRequest__c> ccrs;
    private final List<CCRControls__c> ccCont;
    private string CCRType;
    private CCRTask__c[] appTasks;
    private Map<String, String> img;

    public CCRCalendarController()
    {
        selectedDate = system.Today();
        selectedMonth = datetime.newInstance(selectedDate,time.newInstance(0,0,0,0)).format('MMMM') + ' ' + string.valueOf(selectedDate.year());
        ccCont = [SELECT Id, Name, CalendarImgUrl__c FROM CCRControls__c];
        ccrs = [SELECT Id, Summary__c, Name, ReleaseDate__c, CCRType__c, Status__c  FROM ChangeControlRequest__c WHERE CALENDAR_YEAR(ReleaseDate__c) = :selectedDate.year() AND CALENDAR_MONTH(ReleaseDate__c) = :selectedDate.month()];
        
        appTasks = [SELECT Id, Description__c, RecordType.Name, TaskDateTime__c, Duration__c, ChangeControlRequest__c, ChangeControlRequest__r.CCRStartTime__c FROM CCRTask__c WHERE Status__c = 'Approved' AND AssignedTo__c = :userInfo.getUserId()];
        
        img = new Map<String,String>();
        
        for(CCRControls__c cc:ccCont)
        {
            img.put(cc.Name, cc.CalendarImgUrl__c);
        }
    }
    
    public void CCRTypeChange()
    {
        if(CCRType == 'All')
        {
            ccrs = [SELECT Id, Summary__c, Name, ReleaseDate__c, CCRType__c, Status__c  FROM ChangeControlRequest__c WHERE CALENDAR_YEAR(ReleaseDate__c) = :selectedDate.year() AND CALENDAR_MONTH(ReleaseDate__c) = :selectedDate.month()];
        }
        else
        {
            ccrs = [SELECT Id, Summary__c, Name, ReleaseDate__c,CCRType__c, Status__c   FROM ChangeControlRequest__c WHERE CCRType__c = :CCRType AND CALENDAR_YEAR(ReleaseDate__c) = :selectedDate.year() AND CALENDAR_MONTH(ReleaseDate__c) = :selectedDate.month()];
        }
    }
    
    public void SubtractMonth()
    {
        selectedDate = selectedDate.addMonths(-1);
        selectedMonth = datetime.newInstance(selectedDate,time.newInstance(0,0,0,0)).format('MMMM') + ' ' + string.valueOf(selectedDate.year());
        CCRTypeChange();
    }
    
    public void AddMonth()
    {
        selectedDate = selectedDate.addMonths(1);
        selectedMonth = datetime.newInstance(selectedDate,time.newInstance(0,0,0,0)).format('MMMM') + ' ' + string.valueOf(selectedDate.year());
        CCRTypeChange();
    }
    
    public List<CCRControls__c> Legend
    {
        get
        {
                return ccCont;
        }
    }
    
    public List<selectOption> CCRTypeSelect
    {
            get 
            {
                    //new list for holding all of the picklist options
                    List<SelectOption> options = new List<SelectOption>();
                    options.add(new selectOption('All','All')); 
                    
                    for(CCRControls__c cc: ccCont)
                    {
                        options.add(new selectOption(cc.Name,cc.Name)); 
                    
                    }
                                             
                    return options;
            } 
    }
    
    public String CCRTypeSelected
    {
        get{return CCRType;}
        set{CCRType = value;}
    }
    
    public String MonthString
    {
        get{return selectedMonth;}
    }
    
    public String calendarControl
     {
         get
         {
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
             
             //table header
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
                 results = results + '<td style="width:75px">';
                 results = results + '<div class="date" >' + monthStart.format() + '</div>';
                 
                 
                 boolean wlMatch = false;
                 //loop through worklogs to see if any match the date
                 for(ChangeControlRequest__c ccr:ccrs)
                 {
                     if(monthStart == ccr.ReleaseDate__c)
                     {
                        results = results + '<a href="/' + ccr.Id + '" target="_blank"><img title="' + ccr.Name + ' - ' + ccr.Summary__c + ' (' + ccr.Status__c + ')" src="' + img.get(ccr.CCRType__c) + '" width="10" height="10"></a><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="1" height="10">';
                        wlMatch = true;
                     }
                 }
                 
                 if(!wlMatch)
                 {
                     results = results + '<img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="1" height="20">';
                 }
                 
                 
                 //close column
                 results = results + '</td>';
                 
                 //interate through date and days
                 monthStart = monthStart.addDays(1);
                 dayCount = dayCount + 1;
             }
             
             //close out calendar table
             results = results + '</tr>';
             results = results + '</table>';
             return results;   
         }
     }    
     
     public CCRTask__c[] ApprovedTasks
     {
         get{return appTasks;}
     }

}