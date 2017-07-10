/**
 * Created by mohandaas.rangaswamy on 5/26/2017.
 */
public class XMNotificationTriggerHandler extends TriggerHandler{

    protected override void afterInsert(){

        callXMRestEventService(trigger.new);

    }

    protected override void afterUpdate(){

        // TBD: resend request to xMatters

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
        if(notificationIdSet.size() > 0)
            callXMRestEventServiceFuture(notificationIdSet);

    }

    @Future(callout=true)
    private static void callXMRestEventServiceFuture(Set<Id> notificationIdSet){

        List<xmNotification__c> notificationList = [
                Select Id, Case__c, Request_Date__c, Request_Type__c, Status__c,AddedPlatforms__c
                From xmNotification__c
                Where Id IN :notificationIdSet
        ];
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