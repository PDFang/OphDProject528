global class XMNotificationGroupBatch implements Database.Batchable<Sobject>, Database.AllowsCallouts, Database.Stateful{
    private String queryString;
    private String groupName;
    private String notificationGroupId;

    global XMNotificationGroupBatch(xmNotificationGroups__c notificationGroup){
        queryString = 'Select xmPerson__c from Contact where AccountId IN (Select Account from xmNotificationAccounts__c where Notfication_Group__c = \'' + notificationGroup.Id + '\')'
                + ' And xmPerson__c != null order by xmPerson__c ';

        groupName = notificationGroup.xmGroupUID__c;
        notificationGroupId = notificationGroup.Id;

        System.debug('queryString =>' + queryString);
        System.debug('xmNotificationGroups__c.Id ==> ' + notificationGroup.Id);
        System.debug('group name ==> ' + notificationGroup.xmGroupUID__c);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext BC, List<Contact> scope) {
        try {
            Set<String> xmPersonIds = new Set<String>();

            XMRestDeviceService deviceService = new XMRestDeviceService();
            XMRestGroup groupService = new XMRestGroup();

            Set<XMDeviceModel> devicesToAdd = new Set<XMDeviceModel>();

            for(Contact c : scope) {
                if(!xmPersonIds.contains(c.xmPerson__c)) {
                    String primaryDeviceId = getPrimaryEmailDeviceId(c.xmPerson__c, deviceService);
                    if (primaryDeviceId != null) {
                        //the method returns the Json, but it already logs it using System.debug in the method that is called
                        String resultJson = groupService.AddUserToGroup(groupName, primaryDeviceId, 'EMAIL');
                    }
                    xmPersonIds.add(c.xmPerson__c);
                }
            }
        }
        catch(Exception ex) {
            System.debug(ex);
        }
    }

    global void finish(Database.BatchableContext BC) {
        xmNotificationGroups__c notificationGroup = new xmNotificationGroups__c(
                Id = notificationGroupId,
                Status__c = 'Completed'
        );

        update notificationGroup;
    }

    private String getPrimaryEmailDeviceId(String xmPersonId, XMRestDeviceService service) {
        List<XMDeviceModel> devices = service.getAllDevicesByxMattersUserId(xmPersonId);

        String primaryDeviceId = null;
        for(XMDeviceModel device : devices) {
            if(device.deviceType == 'EMAIL') {
                XMEmailDevice emailDevice = (XMEmailDevice)device;
                if(emailDevice.name == 'Work Email') {
                    primaryDeviceId = emailDevice.id;
                    break;
                }
            }
        }

        return primaryDeviceId;
    }
}