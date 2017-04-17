trigger PartnerDocumentManagerTrigger on Partner_Document_Manager__c (before insert, before update, after insert, after update) {

    new PartnerDocumentManagerTriggerHandler().run();

}