trigger ContentDocumentUpdateTrigger on ContentDocument (after delete)
{
    new ContentDocumentUpdateTriggerHandler().run();
}