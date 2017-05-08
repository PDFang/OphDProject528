public virtual class XMDeviceModel {

    public XMDeviceModel(){
        testStatus = 'TESTED';
        priorityThreshold = 'MEDIUM';
    }

    public final String recipientType = 'DEVICE';

    public String testStatus {get;set;}

    public String deviceType {get;set;}

    // Set this this to the xMatters Person Id (Guid)
    public String owner {get;set;}

    public String priorityThreshold {get;set;}

    public String name {get;set;}

    public final boolean externallyOwned = true;

    public String description {get;set;}

    public String targetName {get;set;}
}
