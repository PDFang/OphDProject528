/**
 * Created by ravish.chawla on 4/18/2017.
 */

@IsTest
private class SubscriptionTriggerHandlerTest {

        static testMethod void testSubscriptionAcceptance() {

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'testCalculateAccountNetScore Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                IsPartner__c = false,
                CustomerSegment__c = 'Strategic',
                Brand_Visibility__c = 'Yes',
                Industry_Leadership_Vocality__c = 'Yes',
                Social_Media_Presence__c = 'Yes',
                Risk_of_Leaving__c = 'Low',
                Referenceable__c = false,
                GYRStatus__c = 'Green'
        );

        insert testAccount;

        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(
                SBQQ__Account__c = testAccount.Id,
                SBQQ__Discount__c = 2.05,
                SBQQ__AdditionalDiscountAmount__c = 2500,
                SBQQ__Bundled__c = true,
                SBQQ__ListPrice__c = 50,
                SBQQ__Quantity__c = 200
        );

            Test.startTest();

            insert subscription;

            Test.stopTest();
            SubscriptionReplica__c newReplica = [select AdditionalDisc__c from SubscriptionReplica__c limit 1];
            system.assertEquals(2.05, newReplica.AdditionalDisc__c);

    }

    static testMethod void testSubscriptionAcceptanceFailure() {

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'testCalculateAccountNetScore Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                IsPartner__c = false,
                CustomerSegment__c = 'Strategic',
                Brand_Visibility__c = 'Yes',
                Industry_Leadership_Vocality__c = 'Yes',
                Social_Media_Presence__c = 'Yes',
                Risk_of_Leaving__c = 'Low',
                Referenceable__c = false,
                GYRStatus__c = 'Green'
        );

        insert testAccount;

        list<SBQQ__Subscription__c> lstSubscriptions = new list<SBQQ__Subscription__c>{
                new SBQQ__Subscription__c()
        };


        Test.startTest();

        SubscriptionTriggerHandler.InsertSubscriptionReplica(lstSubscriptions);
        Test.stopTest();

    }
}