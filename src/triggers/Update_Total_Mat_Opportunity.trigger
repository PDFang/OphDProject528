trigger Update_Total_Mat_Opportunity on SBQQ__QuoteLine__c (after insert, after update) {
   
    set<Id> stQuote = new set<Id>();
    set<string> stProdFam = new set<string>{'SOFTWARE MRC PRODUCTS', 'SOFTWARE USAGE PRODUCTS'};
    string errorStr = '';
    
    if(trigger.isUpdate){
        for(SBQQ__QuoteLine__c ql : trigger.New){
            if( stProdFam.contains(ql.SBQQ__ProductFamily__c)
                && (ql.SBQQ__ProductFamily__c != trigger.oldMap.get(ql.Id).SBQQ__ProductFamily__c
                    || ql.SBQQ__NetTotal__c != trigger.oldMap.get(ql.Id).SBQQ__NetTotal__c)
              )           	
                    stQuote.add(ql.SBQQ__Quote__c);
			
   	       }
        if(stQuote.size() > 0)            
           			 UpdateTotalMATAmount.updateAmount(stQuote,stProdFam);
    }
    
    if(trigger.isInsert){
        for(SBQQ__QuoteLine__c ql : trigger.New){
            if( stProdFam.contains(ql.SBQQ__ProductFamily__c)
                 && ql.SBQQ__NetTotal__c > 0)           	
                    stQuote.add(ql.SBQQ__Quote__c);
            
   	       }
        if(stQuote.size() > 0)
           		UpdateTotalMATAmount.updateAmount(stQuote,stProdFam);
    }
    
}