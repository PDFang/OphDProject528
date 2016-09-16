public class PSImplementationCalendarController 
{
    public Date selectedDate{get;set;}
    private string selectedMonth;
    private List<Opportunity> opps;
    public List<Opportunity> selectedOpps {public get; private set;}

    public PSImplementationCalendarController ()
    {
        selectedDate = system.Today();
        selectedMonth = datetime.newInstance(selectedDate,time.newInstance(0,0,0,0)).format('MMMM') + ' ' + string.valueOf(selectedDate.year());
        opps = [SELECT Id, Name, Account.Name, PM_Estimated_Go_Live__c  FROM Opportunity WHERE CALENDAR_YEAR(PM_Estimated_Go_Live__c) = :selectedDate.year() AND CALENDAR_MONTH(PM_Estimated_Go_Live__c) = :selectedDate.month()];
        selectedOpps = new List<Opportunity>();
    }
    
    public void SetOpps()
    {
        opps = [SELECT Id, Name, Account.Name, PM_Estimated_Go_Live__c  FROM Opportunity WHERE CALENDAR_YEAR(PM_Estimated_Go_Live__c) = :selectedDate.year() AND CALENDAR_MONTH(PM_Estimated_Go_Live__c) = :selectedDate.month()];
    }
   
    
    public void SubtractMonth()
    {
        selectedDate = selectedDate.addMonths(-1);
        selectedMonth = datetime.newInstance(selectedDate,time.newInstance(0,0,0,0)).format('MMMM') + ' ' + string.valueOf(selectedDate.year());
        SetOpps();
    }
    
    public void AddMonth()
    {
        selectedDate = selectedDate.addMonths(1);
        selectedMonth = datetime.newInstance(selectedDate,time.newInstance(0,0,0,0)).format('MMMM') + ' ' + string.valueOf(selectedDate.year());
        SetOpps();
    }
    
    public void UpdateSelectedOpps()
    {
               
        selectedOpps = [SELECT Id,AccountId, Name, Total_MRC_Min__c, PSConsultant__c, inContact__c, WFO__c,WFM__c,Quality_Management__c,Screen__c,Virtual_PBX__c,ECHO__c, Hiring__c FROM Opportunity WHERE PM_Estimated_Go_Live__c = :selectedDate];
    }
    
    public boolean RenderList
    {
        get
        {
            return !selectedOpps.isEmpty();
        }
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
                 results = results + '<td style="width:150px">';
                 results = results + '<div class="date" ><a href="#" onclick="UpdateOpps(\'' + monthStart.format() + '\')">' + monthStart.format() + '</a></div>';
                 
                 
                 boolean wlMatch = false;
                 //loop through worklogs to see if any match the date
                 for(Opportunity opp:opps)
                 {
                     if(monthStart == opp.PM_Estimated_Go_Live__c)
                     {
                        results = results + opp.Account.Name + '</br>';
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
     
}