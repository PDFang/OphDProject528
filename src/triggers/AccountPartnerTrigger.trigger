trigger AccountPartnerTrigger on Account_Partner__c (before insert, after insert, after delete) {
    new AccountPartnerTriggerHandler().run();
}