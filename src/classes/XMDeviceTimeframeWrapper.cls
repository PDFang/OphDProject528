public class XMDeviceTimeframeWrapper {

    public String name {get;set;}
    public string timezone {get;set;}
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

    private transient static  Map<String, XmTimezones__c> timezoneMap = XmTimezones__c.getAll();

    private string getLocation(String timezone){

        return (timezoneMap != null && timezoneMap.containsKey(timezone))
                ? timezoneMap.get(timezone).Location__c : null;

    }

    public XMDeviceTimeframeWrapper(XMDeviceTimeframe timeframe, String userTimezone){


        this.timezone = timeframe.timezone;
        this.name = timeframe.name;

        system.debug('XMDeviceTimeframeWrapper():  name - '+ this.name);
        system.debug('XMDeviceTimeframeWrapper():  current timezone  - '+ this.timezone);
        system.debug('XMDeviceTimeframeWrapper():  user timezone - '+ userTimezone);

        // calculate offset
        Integer offset = offsetInMinutes();
        system.debug('XMDeviceTimeframeWrapper():  GMT offset in minutes - '+ offset);

        Integer hours = Integer.valueOf(timeframe.startTime.left(2));
        Integer minutes = Integer.valueOf(timeframe.startTime.right(2));
        Time startTime = Time.newInstance(hours, minutes, 0, 0);
        Datetime tempDate = Datetime.newInstanceGmt(system.now().dateGMT(), startTime);
        system.debug('XMDeviceTimeframeWrapper():  tempDate GMT - '+ tempDate);

        // add offset
        tempDate = tempDate.addMinutes(offset);
        system.debug('XMDeviceTimeframeWrapper():  tempDate with offset - '+ tempDate);

        this.startTime = tempDate.format('h:mm a', getLocation(userTimezone));
        system.debug('XMDeviceTimeframeWrapper():  Input - '+ timeframe.startTime + '\\n , output - ' + this.startTime);

        // calculate endtime
        tempDate = tempDate.addMinutes(timeframe.durationInMinutes);
        this.endTime = tempDate.format('h:mm a', getLocation(userTimezone));
        system.debug('XMDeviceTimeframeWrapper():  durationInMinutes - '+ timeframe.durationInMinutes + '\\n , endtime - ' + this.endTime);

        this.days = new Week();
        system.debug('XMDeviceTimeframeWrapper():  timeframe.days - '+ timeframe.days);
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

        system.debug('XMDeviceTimeframeWrapper():  timeframe - '+ this);

    }

    public XMDeviceTimeframe createModel(){

        system.debug('createModel:  name - '+ this.name);
        system.debug('createModel:  timezone - '+ this.timezone);

        XMDeviceTimeframe timeframeModel = new XMDeviceTimeframe();
        timeframeModel.name = this.name;
        timeframeModel.timezone = this.timezone;

        Datetime startDateTime = convertTextToDateTime(this.startTime);
        timeframeModel.startTime =  startDateTime.format('HH:mm', getLocation(this.timezone));

        system.debug('createModel:  timeframeModel.startTime - '+ timeframeModel.startTime);

        Datetime endDateTime = convertTextToDateTime(this.endTime);

        if(endDateTime == startDateTime){
            endDateTime = endDateTime.addDays(1);
        }
        system.debug('createModel:  endDateTime - '+ endDateTime.format('HH:mm', getLocation(this.timezone)) );

        timeframeModel.durationInMinutes = (Integer)(endDateTime.getTime() - startDateTime.getTime()) / 60 / 1000;
        system.debug('createModel:  durationInMinutes - ' +  timeframeModel.durationInMinutes);

        List<String> dayList = new List<string>();
        system.debug('createModel: days - ' +  this.days);
        if(this.days.sunday != null && this.days.sunday){
            dayList.add('SU');
        }
        if(this.days.monday != null && this.days.monday){
            dayList.add('MO');
        }
        if(this.days.tuesday != null && this.days.tuesday){
            dayList.add('TU');
        }
        if(this.days.wednesday != null && this.days.wednesday){
            dayList.add('WE');
        }
        if(this.days.thursday != null && this.days.thursday){
            dayList.add('TH');
        }
        if(this.days.friday != null && this.days.friday){
            dayList.add('FR');
        }
        if(this.days.saturday != null && this.days.saturday){
            dayList.add('SA');
        }
        timeframeModel.days = dayList;

        system.debug('createModel:  dayList - '+ dayList);
        system.debug('createModel:  timeframeModel - '+ timeframeModel);

        return timeframeModel;

    }

    private DateTime convertTextToDateTime(String timeText){

        system.debug('convertTextToDateTime:  timeText - '+ timeText);

        Integer hours = Integer.valueOf(timeText.substring(0, timeText.indexOf(':')));
        Integer minutes = Integer.valueOf(timeText.substring(timeText.lastIndexOf(':')+1, timeText.lastIndexOf(':')+3));
        if(timeText.right(2) == 'PM' && hours != 12){
            hours = hours + 12;
        }else if(timeText.right(2) == 'AM' && hours == 12){
            hours = 0;
        }

        Time newTime = Time.newInstance(hours, minutes, 0, 0);
        Datetime newDateTime = Datetime.newInstanceGmt(system.now().DateGMT(), newTime);

        Integer offset = offsetInMinutes();
        newDateTime = newDateTime.addMinutes(offset);
        system.debug('convertTextToDateTime:  newDateTime - '+ newDateTime);

        return newDateTime;

    }

    private Integer offsetInMinutes(){

        Timezone tz = system.Timezone.getTimeZone(getLocation(this.timezone));
        // calculate offset
        Datetime datetimeGmt = Datetime.newInstanceGmt( system.now().DateGMT(), Time.newInstance(0, 0, 0, 0));
        Integer offset = tz.getOffset(datetimeGmt) / (1000 * 60) * -1; // in minutes

        return offset;

    }


}