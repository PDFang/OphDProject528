public class XMDeviceWrapper {
    public string name{get;set;}
    public string deviceType{get;set;}
    public string deviceValue{get;set;}
    public string priorityThreshold{get;set;}
    public string deviceId{get;set;}

    public List<XMDeviceTimeframeWrapper> timeframes{get;set;}

    public XMDeviceWrapper(){
        timeframes = new List<XMDeviceTimeframeWrapper>();
    }

    public XMDeviceModel createModel(){

        XMDeviceModel deviceModel;
        if(this.name.contains('Email')){
            XMEmailDevice emailDevice = new XMEmailDevice();
            emailDevice.emailAddress = this.deviceValue;
            deviceModel = emailDevice;

        } else if(this.name.contains('Phone')){
            XMSmsDevice smsDevice = new XMSmsDevice();
            smsDevice.phoneNumber = this.deviceValue;
            deviceModel = smsDevice;
        }
        deviceModel.name = this.name;
        deviceModel.id = this.deviceId;

        deviceModel.timeframes = new XMDeviceTimeframe[]{};
        for(XMDeviceTimeframeWrapper wrapper : this.timeframes){
            XMDeviceTimeframe timeframeModel = wrapper.createModel();
            deviceModel.timeframes.add(timeframeModel);
        }

        system.debug('createModel(): deviceModel - ' + deviceModel);
        return deviceModel;

    }
}