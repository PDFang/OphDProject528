public class XMDeviceTimeframe {
    public String name {get;set;}
    public String startTime {get;set;}
    public Integer durationInMinutes {get;set;}
    public Boolean excludeHolidays {get;set;}
    public String timezone {get;set;}
    public List<string> days {get;set;}

    public XMDeviceTimeframe(){
        this.excludeHolidays = false;
    }
}