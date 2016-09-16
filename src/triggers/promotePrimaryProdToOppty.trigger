trigger promotePrimaryProdToOppty on BigMachines_Quote__c (after insert, after update) {

    // There is no standard scenario where multiple quotes are created in one
    // batch operation.  There are standard scenarios where multiple quotes
    // are updated in one batch operation.  This trigger only operates for 
    // individual quote creation or multiple quote modification.  If multiple
    // quotes are created at the same time (through the Data Loader, for 
    // example) this trigger will not do anything.  This trigger will fire, 
    // however, if multiple quotes are updated at the same time.

    //loop through trigger and find primary
    Integer index = -1;
    if (Trigger.isInsert) {
        //if a single quote is being created as primary, sync it with opty
        if ((Trigger.size == 1) && (Trigger.new[0].Is_Primary__c == true)) {
            index = 0;
        }
    } else {
        for (Integer i=0; i<Trigger.size; i++) {
            //loop through all updated quotes
            if ((Trigger.old[i].Is_Primary__c == false) && (Trigger.new[i].Is_Primary__c == true)) {
                //if a quote is changing to primary
                if (index == -1) {
                    // found first primary, mark to sync with opty
                    index = i;
                } else {
                    // found more than one primary, so don't sync with opty
                    index = -1;
                    break;
                }
            }
        } 
    } 

    if (index >= 0) {
        BigMachinesQuoting.syncQuoteWithOpty(Trigger.new[index].Id, Trigger.new[index].Opportunity__c);
    }
    
}