/**
 * Created by arnab.karsarkar on 11/8/2016.
 */

public without sharing class TrustGridController {

    public enum Month {Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec}

    @AuraEnabled
    public static list<Platforms> getPlatformInfo(string lastDate)
    {
        list<Platforms> lstPlatforms = new list<Platforms>();
        Date today = getFormattedDate(lastDate);
        list<EventDate> lstEvents = new list<EventDate>();
        list<string> platforms = new list<string>();
        list<EventCounts> lstCounts = new list<EventCounts>();
        platforms.add('C8 - Dialer');
        platforms.add('C8 - inContact');
        platforms.add('Intelligent Network');

        for(string pl : platforms)
        {
            lstEvents = new list<EventDate>();
            Platforms pla = new Platforms();
            pla.platformName = pl;

            if(pl=='C8 - Dialer')
            {
                pla.CurrentStatus = 'A';
            }
            else
            {
                pla.CurrentStatus = 'A';
            }

            for(integer i = 0; i < 7; i++)
            {
                EventDate event = new EventDate();
                dateTime currentDate = today.addDays(-i);
                String monthName= currentDate.format('MMMMM').substring(0,3);
                String formattedDate = monthName + ' ' +  currentDate.day();
                event.EventDt = formattedDate;
                lstCounts = new list<EventCounts>();

                if(i == 2 && pl == 'C8 - Dialer')
                {
                    EventCounts count2 = new EventCounts('D', 1);
                    lstCounts.add(count2);
                    event.EventCountLists = lstCounts;
                }
                else  if(i == 5 && pl == 'C8 - inContact')
                {

                    EventCounts count = new EventCounts('SI', 2);
                    lstCounts.add(count);
                    event.EventCountLists = lstCounts;
                }
                else
                {

                    EventCounts count = new EventCounts('', 0);
                    lstCounts.add(count);
                    event.EventCountLists = lstCounts;
                }
                lstEvents.add(event);

            }
            pla.EventLists = lstEvents;
            lstPlatforms.add(pla);
        }

        System.debug('lstPlatforms ==>' + lstPlatforms);

        return lstPlatforms;
    }


    public static date getFormattedDate(string lastDate)
    {
        Date today = system.today();
        if(lastDate == '' || lastDate == null)
            return today;


        integer theYear = today.year();
        integer theMonth = 0;
        string lastDayMonth = lastDate.substring(0,3);

        if(today.month() == 1 && lastDayMonth == 'Dec')
            theYear = theYear - 1;

        integer theDate = integer.valueOf(lastDate.substring(4).trim());


        for (Month m: Month.values())
        {
            if (m.name() == lastDayMonth)
            {
                theMonth = m.ordinal();
                theMonth++;
                break;
            }
        }

        Date d =  date.newinstance(theYear, theMonth, theDate);

        return d;
    }


    public class Platforms {
        @AuraEnabled
        public String platformName {get; set;}

        @AuraEnabled
        public list<EventDate> EventLists {get; set;}

        @AuraEnabled
        public String CurrentStatus {get; set;}

        //constructor
        public Platforms(){
            this.EventLists = new list<EventDate>();
            this.platformName = '';
            this.CurrentStatus = '';
        }
    }

    public class EventDate{
        @AuraEnabled
        public String EventDt {get; set;}

        @AuraEnabled
        public list<EventCounts> EventCountLists {get; set;}

        //constructor
        public EventDate(){

            this.EventDt = '';
            this.EventCountLists = new list<EventCounts>();
        }


    }

    public class EventCounts {

        @AuraEnabled
        public String EventName {get; set;}

        @AuraEnabled
        public integer Count {get; set;}

        //constructor
        public EventCounts(String EventName, integer count){

            this.EventName = EventName;
            this.Count = Count;
        }
    }



}