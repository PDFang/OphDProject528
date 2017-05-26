/**
 * Created by mohandaas.rangaswamy on 5/26/2017.
 */
public class XMNotificationTriggerHandler extends TriggerHandler{

    protected override void afterInsert(){

        callXMRestEventService(trigger.new);

    }

    private static void callXMRestEventService(List<xmNotification__c> notificationList) {

        system.debug('callXMRestEventService(): notificationList - '+ notificationList);
        if(notificationList.size() > 1){
            throw new LimitException('Too many xmNotification Request: '+notificationList.size());
        }
        Set<Id> notificationIdSet = new Set<Id>();
        for (xmNotification__c xmNotification : notificationList) {
            notificationIdSet.add(xmNotification.Id);
        }

    }

    @Future
    private static void callXMRestEventServiceFuture(Set<Id> notificationIdSet){

        List<xmNotification__c> notificationList = [
                Select Id, Case__c, Request_Date__c, Request_Type__c, Status__c
                From xmNotification__c
                Where Id IN :notificationIdSet
        ];
        system.debug('callXMRestEventServiceFuture(): calling XMRestEventService for xmNotification - '+ notificationList[0]);

        XMRestEventService eventService = new XMRestEventService();
        String response = eventService.startExternalEventProcessing(notificationList[0]);

        system.debug('callXMRestEventServiceFuture(): XMRestEventService response - '+ response);

    }
}