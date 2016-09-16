trigger UpdateAMCPriceAfterUpdate on SBQQ__Quote__c (after update) {

        /* Calucalte the AMC-18 list unit price which is a product on the Enterprise WFO Bundle. 
         * The formula for this is  
         * AMC-18 product list price = ((list price of software A * Quanity) + (list price of software B * Quanity) + hardware)* 18%
         * Our assumption is that the net total hardprice will be used.This trigger will also use two quote roll-up fields
         * Sum_AMC_Software__c & Sum_of_all_HW_Net_Total__c
         */ 
         
        // Check that the quote has the Enterprise WFO Bundle on it. If so then check that it has the AMC-18 quoteline product on it.  
        Set<Id> currQuote = new Set<Id>();
       // TODO Bulkify! Assuming one quote only
        for (SBQQ__Quote__c q : Trigger.new) {
            currQuote.add(q.Id);
        }
    
        /* query for quote lines that belong to our quote(s) */
        SBQQ__QuoteLine__c[] quoteLines = [Select Name,Id,SBQQ__ProductName__c,SBQQ__ProductCode__c,SBQQ__ListPrice__c,SBQQ__Quote__c 
                                        from  SBQQ__QuoteLine__c Where SBQQ__Quote__c in :currQuote ]; 
        
        // Check if any ql matches our AMC product
        Boolean entWFOBundle = false;
        for (SBQQ__QuoteLine__c ql : quoteLines){
            if (ql.SBQQ__ProductCode__c == 'Enterprise WFO Bundle')
                entWFOBundle = true;
        }
         
        if (entWFOBundle){
            // Now check for AMC-18 product 
            for (SBQQ__QuoteLine__c ql : quoteLines){
                if (ql.SBQQ__ProductCode__c == 'AMC-18'){
                    // update list unit price based on roll-up field values. These need to be queried from the quote
                //   SBQQ__Quote__c[] quote = [Select Name,Id from SBQQ__Quote__c Where Id = currQuote.remove()
                }
            }
        }
           
       
}