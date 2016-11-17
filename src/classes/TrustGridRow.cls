/**
 * Created by mohandaas.rangaswamy on 11/9/2016.
 */

public class TrustGridRow {

    public String platformName{get; private set;}
    public String platformDescription{get; private set;}
    public String currentStatus{get; set;}
    public List<TrustGridCell> cellList{get; private set;}

    // constructor
    public TrustGridRow(String platform){
        this.platformName = platform;
        cellList = new List<TrustGridCell>();
        currentStatus = 'Active';
    }

    // inner class
    public Class TrustGridCell{
        public Date today{get; private set;}
        public String dateString{get; private set;}
        //public List<EventInfo> eventList{get; private set;}
        public Map<String, EventSummary> summaryMap{get; private set;}

        public TrustGridCell(Date dateParam){
            this.today = dateParam;
            this.dateString = DateTime.newInstanceGMT(today.year(), today.month(), today.day()).formatGMT('MMM d');
            //this.eventList = new List<EventInfo>();
            this.summaryMap = new Map<String, EventSummary>();
        }

        public void addEvent(Case event){
            EventSummary summary = summaryMap.get(event.EventType__c);
            if(summary == null){
                summary = new EventSummary(event);
                summaryMap.put(event.EventType__c, summary);
            }
            summary.noOfEvents++;
        }
    } // TrustGridCell

    // inner class
    public class EventSummary{
        public String eventType{get; private set;}
        public Integer noOfEvents{get; private set;}

        public EventSummary(Case event){
            this.eventType = event.EventType__c;
            this.noOfEvents = 0;
        }
    } // end of EventSummary

    // inner class
    public Class EventInfo{
        public String eventType{get; private set;}
        public Datetime startDatetime{get; private set;}
        public Datetime endDateTime{get; private set;}
        public EventInfo(Case c){
            this.eventType = c.EventType__c;
            this.startDatetime = c.EventStartDateTime__c;
            this.endDateTime = c.EventEndDateTime__c;
        }
    } // end of EventInfo()



}