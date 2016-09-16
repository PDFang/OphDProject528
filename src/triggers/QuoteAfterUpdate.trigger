trigger QuoteAfterUpdate on SBQQ__Quote__c (after update) {
     set<Id> stQuote = new set<Id>();
     set<Id> stOppToUpdateMAT = new set<Id>();
     set<string> stProdFam = new set<string>{'SOFTWARE MRC PRODUCTS', 'SOFTWARE USAGE PRODUCTS'};
     if(trigger.isUpdate){
            for(SBQQ__Quote__c quote : trigger.New){
                if(quote.SBQQ__Primary__c
                   && quote.SBQQ__Primary__c != trigger.oldMap.get(quote.Id).SBQQ__Primary__c){
                       // if there are software lines 
                	if(quote.Total_Software_Lines_Count__c > 0) {          	
                			  stQuote.add(quote.Id);			
               			}
                       // if no software lines call the method to update total mat with the sum of product info MATs
                       else {
                           stOppToUpdateMAT.add(quote.SBQQ__Opportunity2__c);
                       }
                   
                   }
                
            if(stQuote.size() > 0)            
                         UpdateTotalMATAmount.updateAmount(stQuote,stProdFam);
             
            if(stOppToUpdateMAT.size() > 0)
           			UpdateTotalMATAmount.updateTotalMATWithProductMATs(stOppToUpdateMAT);     
           }     
       }
}