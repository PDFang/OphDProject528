global class SandboxPostRefreshCleanup implements SandboxPostCopy 
{
	global void runApexClass(SandboxContext context)
	{
        string contactsQuery = 'SELECT ADFSGuid__c, Email FROM Contact';
        
        id batchinstanceid = database.executeBatch(new ContactFieldCleaner(contactsQuery, context.sandboxId()), 500);
	} 
}