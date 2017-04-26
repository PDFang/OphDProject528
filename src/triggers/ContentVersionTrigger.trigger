trigger ContentVersionTrigger on ContentVersion (before insert, before update, after insert, after update)
{
    new ContentVersionTriggerHandler().run();

}