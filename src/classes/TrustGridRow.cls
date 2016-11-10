/**
 * Created by mohandaas.rangaswamy on 11/9/2016.
 */

public class TrustGridRow {

    public String platformName;
    public String platformDescription;

    public Class TrustGridCell{
        public Date currentDate;
        public String dateString;
        public List<EventInfo> eventList;
        public TrustGridCell(Date dateParam){
            this.currentDate = dateParam;
            this.eventList = new List<EventInfo>();
        }
    }

    public Class EventInfo{
        public String eventType;
        public Datetime startDatetime;
        public Datetime endDateTime;

    }

}