public class XMNotificationTriggerHandler extends TriggerHandler{

    Static Integer eventServiceCounter = 0;

    public static final String REQUEST_TYPE_COMMENT = 'Public Comment';

    protected override void afterInsert(){

        callXMRestEventService(trigger.new);

    }

    protected override void afterUpdate(){

        updateCaseRecord( (List<xmNotification__c>)trigger.new, (Map<Id, xmNotification__c>)trigger.oldMap);

    }

    // update Case when the notification status is Completed
    private static void updateCaseRecord(List<xmNotification__c> notificationList, Map<Id, xmNotification__c> oldMap){

        if(oldMap == null){
            return;
        }

        system.debug('updateCaseRecord(): notificationList - ' + notificationList);

        Set<Id> caseIds = new Set<Id>();

        for(xmNotification__c notification : notificationList){

            if(notification.Status__c == 'Completed' && oldMap.get(notification.Id).Status__c != 'Completed'){
                if(notification.Request_Type__c == 'Maintenance Notification' || notification.Request_Type__c == 'Event Initial Confirmation')
                    caseIds.add(notification.Case__c);
            }
        }

        if(caseIds.isEmpty()){
            return;
        }

        Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Id maintenanceRecordTypeId = recordTypeMap.get('Maintenance Notification').getRecordTypeId();
        Id eventRecordTypeId = recordTypeMap.get('Event').getRecordTypeId();

        List<Case> caseList = new List<Case>();

        for(Case caseRecord : [Select Id, RecordTypeId, Status from Case where Id IN :caseIds]){
            if(caseRecord.RecordTypeId == maintenanceRecordTypeId ){
                caseRecord.Status = 'Notification Sent';
                caseList.add(caseRecord);
            }
            else if (caseRecord.RecordTypeId == eventRecordTypeId) {
                //set a flag saying the event confirmation has been sent
                caseRecord.xmEvent_Notification_Sent__c = true;
                caseList.add(caseRecord);
            }
        }

        system.debug('updateCaseRecord(): caseList - ' + caseList);

        if(caseList.size() > 0){
            Database.SaveResult[] results = Database.update(caseList, false);
            for(Database.SaveResult result : results){
                if(result.isSuccess() == false){
                    system.debug('updateCaseRecord(): record update failed - ' + result.getErrors()[0].getMessage());
                }
            }
        }

    }

    // calls XMRestEventService to create an event in xMatters
    private static void callXMRestEventService(List<xmNotification__c> notificationList) {

        system.debug('callXMRestEventService(): notificationList - '+ notificationList);
        if(notificationList.size() > 1){
            throw new LimitException('Too many xmNotification Request: '+notificationList.size());
        }
        Set<Id> notificationIdSet = new Set<Id>();
        for (xmNotification__c xmNotification : notificationList) {
            if(xmNotification.Status__c == 'New')
                notificationIdSet.add(xmNotification.Id);
        }
        if(notificationIdSet.size() > 0 && eventServiceCounter == 0 && !system.isFuture() && !system.isBatch()){
            callXMRestEventServiceFuture(notificationIdSet);
            eventServiceCounter++;
        }

    }

    @Future(callout=true)
    private static void callXMRestEventServiceFuture(Set<Id> notificationIdSet){

        List<xmNotification__c> notificationList = [
                Select Id, Case__c, Request_Date__c, Request_Type__c, xMatters_Form__c, Status__c,AddedPlatforms__c,
                        Notification_Group__r.xmGroupUID__c, Public_Comment__c
                From xmNotification__c
                Where Id IN :notificationIdSet
        ];

        if(notificationList.isEmpty()){
            return;
        }
        system.debug('callXMRestEventServiceFuture(): calling XMRestEventService for xmNotification - '+ notificationList[0]);

        try{
            XMRestEventService eventService = new XMRestEventService();
            String response = eventService.startExternalEventProcessing(notificationList[0]);

            system.debug('callXMRestEventServiceFuture(): XMRestEventService response - '+ response);
            notificationList[0].Status__c = 'Processed';
        }catch(Exception ex){
            system.debug('callXMRestEventServiceFuture(): Exception - '+ ex);
            sendErrorEmail(ex, notificationList[0].Case__c);
            notificationList[0].Status__c = 'Failed';
        }

        update notificationList;

    }

    private static void sendErrorEmail(Exception calloutException, String caseId){

        try{
            inContactBaseClass.SendErrorEmail(calloutException, CaseId);
        } catch (Exception ex){
            system.debug('Exception sending error email - '+ ex);
        }


    }

}