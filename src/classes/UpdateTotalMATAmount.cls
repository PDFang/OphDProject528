public class UpdateTotalMATAmount {
    public static void updateAmount(set<Id> stQuotes, set<string> stProdFam){
         Schema.DescribeSObjectResult d = Schema.SObjectType.Opportunity; 
         Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
         //ID  wfo = rtMapByName.get('WFO Premise').getRecordTypeId();
        //Project #75777 - Label changed from 'WFO Premise' to 'Qualified WFO Premise'
        Set<Id> wfoRecordTypeIds = new Set<Id>();
        if(rtMapByName.containsKey('Qualified WFO Premise'))
            wfoRecordTypeIds.add(rtMapByName.get('Qualified WFO Premise').getRecordTypeId());
        if(rtMapByName.containsKey('New WFO Premise'))
            wfoRecordTypeIds.add(rtMapByName.get('New WFO Premise').getRecordTypeId());

         list<Opportunity> lstOpp = new list<Opportunity>();
          
         AggregateResult[] sumOfQuotelines 
                 = [select SBQQ__Quote__r.SBQQ__Opportunity2__c Opp, SUM(Customer_Price__c) Total
                   FROM SBQQ__QuoteLine__c
                   where SBQQ__Quote__c in : stQuotes 
                   and SBQQ__Quote__r.SBQQ__Opportunity2__r.RecordTypeId NOT IN :wfoRecordTypeIds
                   and SBQQ__Product__r.Family in : stProdFam
                   and SBQQ__Quote__r.SBQQ__Primary__c =: true
                   and SBQQ__Existing__c = false
                   Group By SBQQ__Quote__r.SBQQ__Opportunity2__c];
        try{
              for(AggregateResult agr : sumOfQuotelines){
                  string oppyId =  string.valueOf(agr.get('Opp'));
                  Double totalAmt = Double.valueOf(agr.get('Total'));
                    Opportunity UpdOpp = new Opportunity(Id = oppyId
                                                        ,Total_MAT_New__c = totalAmt);
                    lstOpp.add(UpdOpp);
                }
                
                if(lstOpp.size() > 0){
                    update lstOpp;
                }
            
           
        }
        Catch(Exception ex){
            
        }
    }
    
    public static void updateTotalMATWithProductMATs(set<Id> stOpportunities){
        list<Opportunity> updateOppList = new list<Opportunity>();
        for(Opportunity opp: [select Id, Total_MRC_Min__c, Total_MAT_New__c From Opportunity where Id in: stOpportunities]){
        	Opportunity newOpp = new Opportunity(Id = opp.Id);
            newOpp.Total_MAT_New__c = opp.Total_MRC_Min__c;
            updateOppList.add(newOpp);
        }
        
        if(updateOppList.size() > 0)
        	update updateOppList;
    }
    
    
}