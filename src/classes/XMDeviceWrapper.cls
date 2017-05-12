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

        XMDeviceModel device;
        if(this.deviceType.contains('Email')){
            XMEmailDevice emailDevice = new XMEmailDevice();
            emailDevice.emailAddress = this.deviceValue;
            device = emailDevice;

        } else if(this.deviceType.contains('Phone')){
            XMSmsDevice smsDevice = new XMSmsDevice();
            smsDevice.phoneNumber = '+1' + this.deviceValue;
            device = smsDevice;
        }
        device.name = this.deviceType;
        device.id = this.deviceId;

        return device;
    }
}