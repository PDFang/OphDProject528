trigger ContactTrigger on Contact(before insert, before update, after insert, after update, after delete) {

    new ContactTriggerHandler().run();

}