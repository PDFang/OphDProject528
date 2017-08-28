trigger ContentVersionTrigger on ContentVersion (before insert, before update, after insert, after update, before delete, after delete)
{
    new ContentVersionTriggerHandler().run();

}