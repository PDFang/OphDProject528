trigger CCRTrigger on ChangeControlRequest__c (after update) {
    new CCRTriggerHandler().run();
}