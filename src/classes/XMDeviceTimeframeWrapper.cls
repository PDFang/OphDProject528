public class XMDeviceTimeframeWrapper {

    public String name {get;set;}
    //public string timezone {get;set;}
    public String startTime {get;set;}
    public String endTime {get;set;}
    public Week days {get;set;}

    public class Week{
        public boolean sunday{get;set;}
        public boolean monday{get;set;}
        public boolean tuesday{get;set;}
        public boolean wednesday{get;set;}
        public boolean thursday{get;set;}
        public boolean friday{get;set;}
        public boolean saturday{get;set;}

        public Week(){
            this.sunday = false;
            this.monday = false;
            this.tuesday = false;
            this.wednesday = false;
            this.thursday = false;
            this.friday = false;
            this.saturday = false;
        }
    }

    public XMDeviceTimeframeWrapper(XMDeviceTimeframe timeframe){

        this.name = timeframe.name;

        Integer hours = Integer.valueOf(timeframe.startTime.left(2));
        Integer minutes = Integer.valueOf(timeframe.startTime.right(2));
        Time startTime = Time.newInstance(hours, minutes, 0, 0);
        Datetime tempDate = Datetime.newInstance(system.today(), startTime);
        this.startTime = tempDate.format('h:mm a');

        Time endTime = startTime.addMinutes(timeframe.durationInMinutes);
        tempDate = Datetime.newInstance(system.today(), endTime);
        this.endTime = tempDate.format('h:mm a');

        days = new Week();
        for(String day : timeframe.days){
            if(day == 'SU'){
                days.sunday = true;
            } else if(day == 'MO'){
                days.monday = true;
            } else if(day == 'TU'){
                days.tuesday = true;
            } else if(day == 'WE'){
                days.wednesday = true;
            } else if(day == 'TH'){
                days.thursday = true;
            } else if(day == 'FR'){
                days.friday = true;
            } else if(day == 'SA'){
                days.saturday = true;
            }
        }

    }

}