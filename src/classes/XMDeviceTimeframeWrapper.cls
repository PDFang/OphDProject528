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

        this.days = new Week();
        system.debug('XMDeviceTimeframeWrapper:  timeframe.days - '+ timeframe.days);
        for(String day : timeframe.days){
            system.debug(' day  - '+day);
            if(day.containsIgnoreCase('SU')){
                this.days.sunday = true;
            } else if(day.containsIgnoreCase('MO')){
                this.days.monday = true;
            } else if(day.containsIgnoreCase('TU')){
                this.days.tuesday = true;
            } else if(day.containsIgnoreCase('WE')){
                this.days.wednesday = true;
            } else if(day.containsIgnoreCase('TH')){
                this.days.thursday = true;
            } else if(day.containsIgnoreCase('FR')){
                this.days.friday = true;
            } else if(day.containsIgnoreCase('SA')){
                this.days.saturday = true;
            }
        }

        system.debug('XMDeviceTimeframeWrapper:  timeframe - '+ this);

    }

    public XMDeviceTimeframe createModel(){

        XMDeviceTimeframe timeframeModel = new XMDeviceTimeframe();

        String startTimeText = this.startTime;
        Integer hours = Integer.valueOf(startTimeText.left(2));
        Integer minutes;
        if(startTimeText.right(2) == 'AM'){
            minutes = Integer.valueOf(startTimeText.substring(startTimeText.lastIndexOf(':')+1, startTimeText.lastIndexOf(':')+2));
        } else{
            minutes = Integer.valueOf(startTimeText.substring(startTimeText.lastIndexOf(':')+1, startTimeText.lastIndexOf(':')+2));
        }
        Time startTime = Time.newInstance(hours, minutes, 0, 0);
        Datetime startDateTime = Datetime.newInstance(system.today(), startTime);

        String endTimeText = this.endTime;
        hours = Integer.valueOf(endTimeText.left(2));
        if(endTimeText.right(2) == 'AM'){
            minutes = Integer.valueOf(endTimeText.substring(endTimeText.lastIndexOf(':')+1, endTimeText.lastIndexOf(':')+2));
        } else{
            minutes = Integer.valueOf(endTimeText.substring(endTimeText.lastIndexOf(':')+1, endTimeText.lastIndexOf(':')+2));
        }
        Time endTime = Time.newInstance(hours, minutes, 0, 0);
        Datetime endDateTime = Datetime.newInstance(system.today(), endTime);

        timeframeModel.name = this.name;
        timeframeModel.startTime =  startDateTime.format('h:mm');
        timeframeModel.durationInMinutes = (Integer)(endDateTime.getTime() - startDateTime.getTime()) / 60 / 1000;
        List<String> days = new List<string>();
        timeframeModel.days = days;
        if(this.days.sunday){
            days.add('SU');
        } else if(this.days.monday){
            days.add('MO');
        } else if(this.days.tuesday){
            days.add('TU');
        } else if(this.days.wednesday){
            days.add('WE');
        } else if(this.days.thursday){
            days.add('TH');
        } else if(this.days.friday){
            days.add('FR');
        } else if(this.days.saturday){
            days.add('SA');
        }

        system.debug('createModel:  timeframeModel - '+ timeframeModel);

        return timeframeModel;

    }

}