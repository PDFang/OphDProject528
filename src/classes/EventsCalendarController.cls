public class EventsCalendarController 
{
    public List<Case> events {public get;private set;}
    public Date selectedDate {get;set;}
    public string selectedMonth {get;set;}
    public string eventType {get;set;}
    
    public EventsCalendarController()
    {
        selectedDate = system.Today();
        selectedMonth = datetime.newInstance(selectedDate,time.newInstance(0,0,0,0)).format('MMMM') + ' ' + string.valueOf(selectedDate.year());
        
        eventType = 'All';
        SetEvents();
    }
    
    public void SetEvents()
    {
        if(eventType == 'All')
        {
            events = [SELECT EventStartDateTime__c, EventEndDateTime__c, Subject, EventType__c, Status, IsClosed, CaseNumber,InternalEvent__c,ProductImpacted__c,PlatformsImpacted__c FROM Case WHERE RecordType.Name = 'Event' AND ((CALENDAR_YEAR(EventStartDateTime__c) = :selectedDate.year() AND CALENDAR_MONTH(EventStartDateTime__c) = :selectedDate.month()) )];
        }
        else
        {
            string platforms = '';
        
            if(eventType == 'inContact' || eventType == 'Dialer')
            {
                for(String cluster:inContactConfiguration.clusters)
                {
                    if(platforms== '')
                    {
                        platforms = '\'' + cluster + ' - ' + eventType + '\'';
                    }
                    else
                    {
                        platforms = platforms + ',' + '\'' + cluster + ' - ' + eventType + '\'';
                    }
                }
            }
            else
            {
                platforms = '\'' + eventType + '\'';
            }
                      
            string query = 'SELECT EventStartDateTime__c, EventEndDateTime__c, Subject, EventType__c, Status, IsClosed, CaseNumber,InternalEvent__c,ProductImpacted__c,PlatformsImpacted__c FROM Case WHERE PlatformsImpacted__c includes(' + platforms + ') AND RecordType.Name = \'Event\' AND ((CALENDAR_YEAR(EventStartDateTime__c) = ' + string.valueOf(selectedDate.year()) + ' AND CALENDAR_MONTH(EventStartDateTime__c) = ' + string.valueOf(selectedDate.month()) + '))';
            events = Database.query(query);
        }
    }
    
    
    public void SubtractMonth()
    {
        selectedDate = selectedDate.addMonths(-1);
        selectedMonth = datetime.newInstance(selectedDate,time.newInstance(0,0,0,0)).format('MMMM') + ' ' + string.valueOf(selectedDate.year());
        SetEvents();
    }
    
    public void AddMonth()
    {
        selectedDate = selectedDate.addMonths(1);
        selectedMonth = datetime.newInstance(selectedDate,time.newInstance(0,0,0,0)).format('MMMM') + ' ' + string.valueOf(selectedDate.year());
        SetEvents();
    }

    public String calendarControl
     {
         get
         {
             string titleString;
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
                 results = results + '<div class="date" >' + monthStart.format() + '</div>';
                 
                 
                 boolean wlMatch = false;
                 //loop through worklogs to see if any match the date
                 for(Case event:events)
                 {
                     if(monthStart == event.EventStartDateTime__c.date())
                     {
                         string platformColor;
                         
                         if(!event.IsClosed)
                         {
                             platformColor = 'red';
                         }
                         else if(event.PlatformsImpacted__c.contains(' - inContact') && event.PlatformsImpacted__c != 'TF - inContact')
                         {
                             platformColor = InContactConfiguration.platformColors.get('inContact');
                         }
                         else if(event.PlatformsImpacted__c.contains(' - Dialer'))
                         {
                             platformColor = InContactConfiguration.platformColors.get('Dialer');
                         }
                         else
                         {
                             platformColor = InContactConfiguration.platformColors.get(event.PlatformsImpacted__c);
                         }
                         
                         titleString = event.CaseNumber + ' - ' + event.Subject + ' (' + event.ProductImpacted__c + ': ' + event.PlatformsImpacted__c;
                         
                     
                        results = results + '<a title="' + titleString.replace('"','\'') + ')" href="/' + event.Id + '" target="_blank"><img src="https://service.incontact.com/Images/transparent.png" style="background-color:' + platformColor + ';" width="10" height=10"></a><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="1" height="10"/>';
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
     
     public Map<String,String> PlatformColors
     {
         get
         {
             return InContactConfiguration.platformColors;
         }
     }
     
     public List<String> AvailablePlatforms
     {
         get
         {
             return InContactConfiguration.platforms;
         }
     }
     
     public List<selectOption> EventTypeSelect
    {
            get 
            {
                    //new list for holding all of the picklist options
                    List<SelectOption> options = new List<SelectOption>();
                    options.add(new selectOption('All','All')); 
                    for(String s:InContactConfiguration.platforms)
                    {
                       options.add(new selectOption(s,s)); 
                    }
                    return options;
            } 
    }
}