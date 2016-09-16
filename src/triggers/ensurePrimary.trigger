trigger ensurePrimary on BigMachines_Quote__c (before insert) {

    // There is no standard scenario where multiple quotes are created in one
    // batch operation.  This trigger only operates for individual quote 
    // creation.  If multiple quotes are created at the same time (through 
    // the API, for example) this trigger will not do anything.

    ID oppId = Trigger.new[0].Opportunity__c;
    if (Trigger.size == 1 && oppId != null) {
        BigMachines_Quote__c[] primary = [select Id from BigMachines_Quote__c
                                          where Opportunity__c = :oppId
                                          and Is_Primary__c = true];    
        if (primary.size() == 0) {
            Trigger.new[0].Is_Primary__c = true; 
        }
    }
}