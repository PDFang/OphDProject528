trigger ContentDocumentUpdateTrigger on AcceptedEventRelation (after delete)
{
    new ContentDocumentUpdateTriggerHandler().run();

}