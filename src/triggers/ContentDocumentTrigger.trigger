trigger ContentDocumentTrigger on ContentDocument (after delete)
{
    new ContentDocumentTriggerHandler().run();
}