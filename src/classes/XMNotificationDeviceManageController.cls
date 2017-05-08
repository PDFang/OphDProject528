/**
 * Created by arnab.karsarkar on 5/2/2017.
 */

global class XMNotificationDeviceManageController {

    public string contactId{get;set;}
    public XMNotificationDeviceManageController(ApexPages.StandardController controller){
                contactId = (string)controller.getId();
    }


    public string days
    {
        get
        {
            Schema.DescribeFieldResult F = NotificationTimeframe__c.Days__c.getDescribe();
            String[] dayList = new String[]{};

            for(Schema.PicklistEntry pl:F.getPicklistValues())
            {
                dayList.add(pl.getValue());
            }

            return JSON.Serialize(dayList);
        }
    }

    public string deviceTypes
    {
        get
        {
            Schema.DescribeFieldResult F = NotificationDevice__c.DeviceType__c.getDescribe();
            String[] types = new String[]{};

            for(Schema.PicklistEntry pl:F.getPicklistValues())
            {
                types.add(pl.getValue());
            }

            return JSON.Serialize(types);
        }
    }

    public string PriorityThresholds
    {
        get
        {
            Schema.DescribeFieldResult F = NotificationDevice__c.PriorityThreshold__c.getDescribe();
            String[] thresholds = new String[]{};

            for(Schema.PicklistEntry pl:F.getPicklistValues())
            {
                thresholds.add(pl.getValue());
            }

            return JSON.Serialize(thresholds);
        }
    }

    @RemoteAction
    public static string GetNotificationDevices(string contactId){

        list<XMNotificationDeviceClass> deviceClassLists = new list<XMNotificationDeviceClass>();

        List<NotificationDevice__c> deviceLists = [select Id, Active__c, DeviceType__c, Email__c, Phone__c, PriorityThreshold__c
                                                  From NotificationDevice__c where Contact__c = :contactId];

        for(NotificationDevice__c device : deviceLists){
            XMNotificationDeviceClass deviceClass = new XMNotificationDeviceClass();
            deviceClass.Active = device.Active__c;
            deviceClass.DeviceId = device.Id;
            deviceClass.DeviceType = device.DeviceType__c;
            deviceClass.PriorityThreshold = device.PriorityThreshold__c;
            deviceClass.DeviceValue = device.Email__c == null ? device.Phone__c : device.Email__c;
            deviceClassLists.add(deviceClass);
        }

       return JSON.serialize(deviceClassLists);

    }

    @RemoteAction
    Public static string GetTimeFramesForDevice(string DeviceId){
        list<XMNotificationTimeFrameClass> timeFrameLists = new list<XMNotificationTimeFrameClass>();
        for(NotificationTimeframe__c timeframe : [select ID, Days__c, StartTime__c, TimeframeName__c from NotificationTimeframe__c where NotificationDevice__c = :DeviceId]){
               // set<string> daySets = new set<string>();
               // daySets.addAll(timeframe.Days__c.split(';'));
                XMNotificationTimeFrameClass timeFrameClass
                        = new XMNotificationTimeFrameClass(
                               timeFrame.Id, timeframe.StartTime__c, timeframe.EndTime__c,timeframe.Days__c
                        );
                timeFrameLists.add(timeFrameClass);
        }
        return JSON.serialize(timeFrameLists);
    }



    public class XMNotificationDeviceClass{
        public boolean Active{get;set;}
        public string DeviceType{get;set;}
        public string DeviceValue{get;set;}
        public string PriorityThreshold{get;set;}
        public string DeviceId{get;set;}

        public XMNotificationDeviceClass(){

        }
    }
   public Class XMNotificationTimeFrameClass{
       public string TimeFrameId{get;set;}
       public string StartTime{get;set;}
       Public string EndTime{get;set;}
       Public string Days{get;set;}

     public XMNotificationTimeFrameClass(string tId, string stTime, string endTime,string setDays){
         TimeFrameId = tId;
         Days = setDays;
         StartTime = stTime;
         EndTime = endTime;
     }

   }

}