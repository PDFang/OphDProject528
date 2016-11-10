/**
 * Created by arnab.karsarkar on 11/8/2016.
 */

public without sharing class TrustGridController {

    @AuraEnabled
    public static list<Platforms> getPlatformInfo()
    {
        list<Platforms> lstPlatforms = new list<Platforms>();
        Date today = system.today();
        list<EventDate> lstEvents = new list<EventDate>();
        list<string> platforms = new list<string>();
        list<EventCounts> lstCounts = new list<EventCounts>();
        platforms.add('Platforms');
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
                pla.CurrentStatus = 'D';
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