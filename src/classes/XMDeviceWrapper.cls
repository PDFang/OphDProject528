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
}