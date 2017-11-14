public class XMNotificationListControllerExtension {
    public List<xmNotification__c> notifications {get; set;}
    public String caseId {get; private set;}

    public XMNotificationListControllerExtension(ApexPages.StandardController controller) {
        Case c = (Case)controller.getRecord();

        caseId = c.Id;

        notifications = [select Name, Request_Type__c, xMatters_Form__c, Request_Date__c, Status__c, Related_Notification__c, CreatedBy.Name, CreatedBy.Id, CreatedDate
                        from xmNotification__c
                        where Request_Type__c != 'Maintenance Preview' and Case__c = :caseId];
    }
}