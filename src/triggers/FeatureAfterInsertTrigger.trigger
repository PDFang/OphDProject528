trigger FeatureAfterInsertTrigger on Feature__c (after insert) 
{
    
    for(Feature__c f:trigger.new)
    {
        if(f.TFSID__c != null)
        {
            CorporateItTfsAccess.SyncTfsFeatureAsync(f.Id,integer.valueOf(f.TFSID__c));
        }
    }
}