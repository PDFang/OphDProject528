/**
 * Created by mohandaas.rangaswamy on 3/17/2017.
 */

@IsTest
private class CustomerInfoTriggerHandlerTest {
    static testMethod void testBehavior() {

        Account customer = [Select Id from Account Limit 1];
        JBCXM__CustomerInfo__c customerInfo = new JBCXM__CustomerInfo__c(
                JBCXM__Account__c = customer.Id,
//                JBCXM__CurScoreId__c,
//                JBCXM__CurScoreId__r.JBCXM__Score__c,
                JBCXM__ASV__c = 1800000,
                JBCXM_CreatedCases__c = 15,
                JBCXM_OpenCases__c = 20,
                JBCXM_Credits__c = 2500,
                JBCXM_MTTR__c = 3
        );

        test.startTest();
        insert customerInfo;
        test.stopTest();

        customer = [Select GainSight_Net_Score__c from Account where Id = :customer.Id];
        system.assert(customer.GainSight_Net_Score__c > 0);
    }

    @TestSetup
    private static void createTestData(){

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'CustomerInfoTriggerHandlerTest Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId()
        );

        insert testAccount;
    }
}