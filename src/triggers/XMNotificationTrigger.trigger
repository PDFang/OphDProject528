trigger XMNotificationTrigger on xmNotification__c (before Insert, before Update, after Insert, after Update) {

    new XMNotificationTriggerHandler().run();

}