/**
*  ================================================================================================
*   Version    Date              Comment
*  ================================================================================================
*   v1.1      Dec-13-2016      * Test class of SaaSContractsSchedule and SaaSContractBatchApex class.
**/
@isTest
Private  class SaaSContractsSchedule_Test {
   // CRON expression: 1st of every month.
   // Because this is a test, job executes
   // immediately after Test.stopTest().

   public static String CRON_EXP = '0 0 0 1 * ?';

   /**
    * Test data for Account object record.
    */
   public static Account createAccountTestData() {
       Account objAccount = new Account();
       objAccount.Name = 'Test Account';
       insert objAccount;
       return objAccount;
   }

   /**
    * Test data for Opportunity object record.
    */
   public static Opportunity createOppTestData(Id strAccId) {
     Opportunity objOpp = new Opportunity();
     objOpp.AccountId = strAccId;
     objOpp.Name = 'Test Opportunity';
     objOpp.CloseDate = date.today().addDays(-395);
     objOpp.StageName = 'Closed Lost';
     objOpp.Description = 'Test Description';
     objOpp.Amount = 200000;
     //objOpp.CloseDate = date.today().addDays(-180);
     insert objOpp;
     return objOpp;
   }

   /**
    * Test data for SBQQ__Quote__c object record.
    */
   public static SBQQ__Quote__c createQuoteTestData(Id strRecordtypeId, Id strAccId) {
       SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
       objQuote.SBQQ__Account__c = strAccId;
       objQuote.SBQQ__Type__c = 'Quote';
       objQuote.SBQQ__Status__c = 'Draft';
       objQuote.RecordTypeId = strRecordtypeId;
       insert objQuote;
       return objQuote;
   }

   /**
    * Test data for Contract object record.
    */
   public static Contract createContractTestData(Opportunity objOpp, Id strQuoteId, Boolean isInsert) {
       Contract objContract = new Contract();
       objContract.AccountId = objOpp.AccountId;
       objContract.ContractTerm = 12;
       objContract.StartDate = objOpp.CloseDate;
       objContract.Auto_Renew__c = true;
       objContract.SBQQ__Quote__c = strQuoteId;
       objContract.GoLiveDate__c = date.today().addDays(-457);
       objContract.OwnerExpirationNotice = '30';
       objContract.Status = 'Draft';
       objContract.Auto_Renew__c = true;
       if(isInsert)
          insert objContract;
       return objContract;
   }

   /**
    * Test method to test update for Contracts
    */
   static testmethod void testContractRenewal() {
        Id strRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.RecordTypeInfosByName.get('SaaS').RecordTypeId;
        Date newDate = date.today();
        Account objAccount = createAccountTestData();
        Opportunity objOpp = createOppTestData(objAccount.Id);

       SBQQ__Quote__c objQuote = createQuoteTestData(strRecordTypeId,objAccount.Id);

       // Create the contract
       Contract objContract = createContractTestData(objOpp,objQuote.Id,true);

      Test.startTest();
      // Schedule the test job
      String jobId = System.schedule('SaaSContractsSchedule_Test',
                        CRON_EXP,
                        new SaaSContractsSchedule());

      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,
         NextFireTime
         FROM CronTrigger WHERE id = :jobId];

      // Verify the expressions are the same
      System.assertEquals(CRON_EXP, ct.CronExpression);

      // Verify the job has not run
      System.assertEquals(0, ct.TimesTriggered);

      // Verify the scheduled job hasn't run yet.
      List <Contract> theContractsBefore = ([Select id, name, Auto_Renew__c, StartDate, EndDate, SBQQ__Quote__r.recordtypeId
                                            from Contract
                                            where
                                            Contract.Auto_Renew__c = true
                                            AND Contract.SBQQ__Quote__r.recordtypeId  = :strRecordTypeId
                                            AND Contract.EndDate  = last_month
                                             ]);
      System.debug('top ===== > theContracts on the test class ======> ' +theContractsBefore );
      System.assertEquals(theContractsBefore.size(),1);

      SaaSContractBatchApex batch1  = new SaaSContractBatchApex();
      ID batchprocessid = Database.executeBatch(batch1);
      Test.stopTest();
      // Now that the scheduled job has executed after Test.stopTest(),
      List <Contract> theContractsAfter = ([Select id, name, Auto_Renew__c, StartDate, EndDate, SBQQ__Quote__r.recordtypeId
                                            from Contract
                                            where
                                            Contract.Auto_Renew__c = true
                                            AND Contract.SBQQ__Quote__r.recordtypeId  = :strRecordTypeId
                                            AND Contract.EndDate  = last_month
                                             ]);
     System.assertEquals(theContractsAfter.size(), 0);
   }

   /**
    * Test method to test bulk update for Contracts
    */
   static testmethod void testContractRenewalBulk() {
        Id strRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.RecordTypeInfosByName.get('SaaS').RecordTypeId;
        Date newDate = date.today();
        Account objAccount = createAccountTestData();
        Opportunity objOpp = createOppTestData(objAccount.Id);

       SBQQ__Quote__c objQuote = createQuoteTestData(strRecordTypeId,objAccount.Id);

       // Create the contracts in bulk
       List<Contract> lstContracts = new List<Contract>();
       for(Integer i=0;i<100;i++) {
         Contract objContract = createContractTestData(objOpp,objQuote.Id,false);
         lstContracts.add(objContract);
       }
       insert lstContracts;
       Contract objContract = createContractTestData(objOpp,objQuote.Id,false);
       objContract.Auto_Renew__c = false;
       insert objContract;

      Test.startTest();
      // Schedule the test job
      String jobId = System.schedule('SaaSContractsSchedule_Test',
                        CRON_EXP,
                        new SaaSContractsSchedule());

      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,
         NextFireTime
         FROM CronTrigger WHERE id = :jobId];

      // Verify the expressions are the same
      System.assertEquals(CRON_EXP, ct.CronExpression);

      // Verify the job has not run
      System.assertEquals(0, ct.TimesTriggered);

      // Verify the scheduled job hasn't run yet.
      List <Contract> theContractsBefore = ([Select id, name, Auto_Renew__c, StartDate, EndDate, SBQQ__Quote__r.recordtypeId
                                            from Contract
                                            where
                                            Contract.Auto_Renew__c = true
                                            AND Contract.SBQQ__Quote__r.recordtypeId  = :strRecordTypeId
                                            AND Contract.EndDate  = last_month
                                             ]);
      System.debug('top ===== > theContracts on the test class ======> ' +theContractsBefore );
      System.assertEquals(theContractsBefore.size(),100);

      SaaSContractBatchApex batch1  = new SaaSContractBatchApex();
      ID batchprocessid = Database.executeBatch(batch1);
      Test.stopTest();
      // Now that the scheduled job has executed after Test.stopTest(),
      List <Contract> theContractsAfter = ([Select id, name, Auto_Renew__c, StartDate, EndDate, SBQQ__Quote__r.recordtypeId
                                            from Contract
                                            where
                                            Contract.Auto_Renew__c = true
                                            AND Contract.SBQQ__Quote__r.recordtypeId  = :strRecordTypeId
                                            AND Contract.EndDate  = last_month
                                             ]);
     System.assertEquals(theContractsAfter.size(), 0);
   }
}