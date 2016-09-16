trigger propogateModifications on Quote_Product__c (after insert, after update, after delete) {
    
    // There is no standard scenario where quote products from multiple quotes are
    // modified in one batch operation.  This trigger only operates when all quote 
    // products belong to the same quote.  If quote products from multiple quotes 
    // are modified in the same batch operation this trigger will not do anything

    boolean sameQuote = true;
    ID quoteId = null;
    if (Trigger.isDelete) {
        quoteId = Trigger.old[0].BigMachines_Quote__c;
        for (Integer i=0;i<Trigger.size;i++) {
            if (Trigger.old[i].BigMachines_Quote__c != quoteId) {
                sameQuote = false;
            }
        }
    } else {
        quoteId = Trigger.new[0].BigMachines_Quote__c;
        for (Integer i=0;i<Trigger.size;i++) {
            if (Trigger.new[i].BigMachines_Quote__c != quoteId) {
                sameQuote = false;
            }
        }
    }

    if (sameQuote) {
        BigMachines_Quote__c quote = [select Id, Is_Primary__c, Opportunity__c 
                                      from BigMachines_Quote__c where Id = :quoteId];
        if (quote.Is_Primary__c == true) {
            BigMachinesQuoting.syncQuoteWithOpty(quoteId, quote.Opportunity__c);
        }
    }
}