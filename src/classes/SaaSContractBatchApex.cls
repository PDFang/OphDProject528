//Batch Job for Processing the Records
global class SaaSContractBatchApex implements Database.Batchable<sobject>{
   
  //Start Method
  global Database.Querylocator start (Database.BatchableContext BC) {
   		//return the Contract record needed
 	 id theRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.RecordTypeInfosByName.get('SaaS').RecordTypeId;	
   
                
      return Database.getQueryLocator('select id, name, Auto_Renew__c, StartDate, EndDate, SBQQ__Quote__r.recordtypeId  from Contract  where Contract.Auto_Renew__c = true  and Contract.SBQQ__Quote__r.recordtypeId  = \'' +  theRecordTypeId + '\'' + ' and Contract.EndDate = last_month' );
   }

  //Execute method
  global void execute (Database.BatchableContext BC, List<Contract> scope) {
   
      List <Contract> theContractsWithNewValues = new  List <Contract>();
      
      system.debug('scope is here ============> '+ scope);
      
      if (scope.size() > 0){
           for(Contract c: scope){
               c.StartDate = date.today() ;
              theContractsWithNewValues.add(c);
          }
       }
          
      if (theContractsWithNewValues.size() > 0){
          update theContractsWithNewValues;
      }       
      
          
  }

  //Finish Method
  global void finish(Database.BatchableContext BC){
   
  }
}