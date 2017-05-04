public class XMDeviceModel {

    public final String recipientType = 'DEVICE';

    public final String testStatus = 'TESTED';

    public String deviceType {get;set;}

    // Set this this to the xMatters Person Id (Guid)
    public String owner {get;set;}

    public String priorityThreshold = 'MEDIUM';

    public String name {get;set;}
}