public without sharing class XMNotificationRetryController {


    public List<xmNotification__c> notificationList{get;set;}
    public Case caseRecord{get; private set;}
    public String selectedId{get;set;}

    private Map<Id, xmNotification__c> notificationMap;

    public XMNotificationRetryController(){

        notificationList = new List<xmNotification__c>();
        notificationMap = new Map<Id, xmNotification__c>();

        String caseId = ApexPages.currentPage().getParameters().get('caseId');

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

        for(xmNotification__c notification : [
                Select Id, AddedPlatforms__c, Case__c, Request_Date__c, Request_Type__c, Status__c, CreatedBy.Name, CreatedDate
                from xmNotification__c
                where Case__c = :caseId and Status__c = 'Failed'
        ]){
            notificationList.add(notification);
            notificationMap.put(notification.Id, notification);
        }

        if(notificationMap.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No notification requests available for retry.'));
            return;
        }

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

            xmNotification__c newNotification = new xmNotification__c(
                    Case__c = notification.Case__c,
                    Request_Date__c = system.now(),
                    Request_Type__c = notification.Request_Type__c,
                    AddedPlatforms__c = notification.AddedPlatforms__c,
                    Status__c = 'New'
            );
            insert newNotification;

            notification.Status__c = 'Retried';
            update notification;

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Notification request retry was Successfull.'));

        } catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to process your request. Please contact your administrator.'));
            system.debug('retry(): Exception - ' + ex);
            inContactBaseClass.SendErrorEmail(ex, (notification != null ? notification.Id : ' ') + ' - Notification retry request failed');
        }
        return null;

    }


}