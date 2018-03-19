public without sharing class XMNotificationRetryController {


    public List<xmNotification__c> notificationList{get;set;}
    public Case caseRecord{get; private set;}

    // cache failed notifications
    private Map<Id, xmNotification__c> notificationMap;

    public XMNotificationRetryController(ApexPages.StandardController controller){

        String caseId = ApexPages.currentPage().getParameters().get('caseId');

        if(caseId == null) {
            caseId = ((Case)controller.getRecord()).Id;
        }

        if(String.isBlank(caseId)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid URL: No Case ID found.'));
            return;
        }

        List<Case> caseList = [
                Select Id, CaseNumber
                from Case
                Where Id = :caseId
        ];

        if(caseList.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Case record found.'));
            return;
        }

        caseRecord = caseList[0];
        system.debug('XMNotificationRetryController(): caseRecord - ' + caseRecord);

        getNotifications(caseRecord.Id);

        if(notificationMap.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No notification requests available for retry.'));
            return;
        }

    }

    private void getNotifications(String caseId){

        notificationList = new List<xmNotification__c>();
        notificationMap = new Map<Id, xmNotification__c>();

        for(xmNotification__c notification : [
                Select Id, AddedPlatforms__c, Case__c, Request_Date__c, Request_Type__c, xMatters_Form__c, Status__c, CreatedBy.Name, CreatedDate, Public_Comment__c
                from xmNotification__c
                where Case__c = :caseId and Status__c = 'Failed'
        ]){
            notificationList.add(notification);
            notificationMap.put(notification.Id, notification);
        }

        system.debug('XMNotificationRetryController(): notificationList - ' + notificationList);

    }

    public pagereference retry(){

        String notificationId = ApexPages.currentPage().getParameters().get('notificationId');
        if(String.isBlank(notificationId)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a request.'));
            return null;
        }

        xmNotification__c notification = null;

        try{
            notification = notificationMap.get(notificationId);
            system.debug('retry(): notification - ' + notification);

            xmNotification__c newNotification = new xmNotification__c(
                    Case__c = notification.Case__c,
                    Request_Date__c = system.now(),
                    Request_Type__c = notification.Request_Type__c,
                    xMatters_Form__c = notification.xMatters_Form__c,
                    AddedPlatforms__c = notification.AddedPlatforms__c,
                    Status__c = 'New',
                    Related_Notification__c = notification.Id,
                    Public_Comment__c = notification.Public_Comment__c,
                    CommentId__c = notification.CommentId__c
            );
            insert newNotification;

            notification.Status__c = 'Retried';
            update notification;

            getNotifications(caseRecord.Id);

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Notification request retry was Successfull.'));

        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to process your request. Please contact your administrator.'));
            system.debug('retry(): Exception - ' + ex);
            inContactBaseClass.SendErrorEmail(ex, (notification != null ? notification.Id : ' ') + ' - Notification retry request failed');
        }
        return null;

    }

    public pagereference cancel(){

        return new pagereference('/'+ caseRecord.Id);
    }

}