/**
 * Created by mohandaas.rangaswamy on 3/17/2017.
 */

@IsTest
private class AccountTriggerHandlerTest {

    static testMethod void testCalculateAccountNetScore() {

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'testCalculateAccountNetScore Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                IsPartner__c = false,
                CustomerSegment__c = 'Strategic',
                Brand_Visibility__c = 'Medium',
                Industry_Leadership_Vocality__c = 'Low',
                Social_Media_Presence__c = 'Yes',
                Risk_of_Leaving__c = null,
                Referenceable__c = false,
                GYRStatus__c = 'Green'
        );
        test.startTest();
        insert testAccount;
        test.stopTest();

        Account customer = [Select Account_Net_Score__c from Account where Id = :testAccount.Id];
        system.assert(customer.Account_Net_Score__c > 0);

    } // end of testCalculateAccountNetScore()

}