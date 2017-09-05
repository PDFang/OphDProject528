trigger ContentDocumentTrigger on ContentDocument (after delete)
{
    new ContentDocumentUpdateTriggerHandler().run();
}