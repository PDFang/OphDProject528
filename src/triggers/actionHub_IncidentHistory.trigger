trigger actionHub_IncidentHistory on BMCServiceDesk__IncidentHistory__c bulk (after insert,after update) {

    if(!system.isFuture())
    {
        System.debug('**** Starting actionHub_IncidentHistory');
        String source = 'Cloudaction Dev 3';
        CloudactionInt.EventHandler handler = new CloudactionInt.EventHandler();
        handler.objectSaveEvent(trigger.old, trigger.new, source);
        System.debug('**** Completing actionHub_IncidentHistory');
    }
}