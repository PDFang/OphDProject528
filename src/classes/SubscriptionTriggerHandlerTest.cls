@IsTest
private class SubscriptionTriggerHandlerTest {

    static testMethod void testUpdateSubscriptionReplica() {

        ImplementedProduct__c ip = [Select Account__c, Id from ImplementedProduct__c limit 1];

        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(
                SBQQ__Account__c = ip.Account__c,
                SBQQ__Discount__c = 2.05,
                SBQQ__AdditionalDiscountAmount__c = 2500,
                SBQQ__Bundled__c = true,
                SBQQ__ListPrice__c = 50,
                SBQQ__Quantity__c = 200,
                Implemented_Product__c = ip.Id,
                Status__c = '1 - New'
        );

        insert subscription;

        Test.startTest();

        subscription.Status__c = '2 - Ordered';
        update subscription;

        Test.stopTest();

        SubscriptionReplica__c[] newReplicas = [select Status1__c from SubscriptionReplica__c where Subscription__c = :subscription.Id];
        system.assertEquals(subscription.Status__c, newReplicas[0].Status1__c);

    }

    static testMethod void testInsertSubscriptionReplica() {

        ImplementedProduct__c ip = [Select Account__c, Id from ImplementedProduct__c limit 1];

        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(
                SBQQ__Account__c = ip.Account__c,
                SBQQ__Discount__c = 2.05,
                SBQQ__AdditionalDiscountAmount__c = 2500,
                SBQQ__Bundled__c = true,
                SBQQ__ListPrice__c = 50,
                SBQQ__Quantity__c = 200,
                Implemented_Product__c = ip.Id
        );

        Test.startTest();

        insert subscription;

        Test.stopTest();

        SubscriptionReplica__c[] newReplicas = [select Id, Implemented_Product__c from SubscriptionReplica__c where Subscription__c = :subscription.Id];
        system.assertEquals(1, newReplicas.size());
        system.assertEquals(subscription.Implemented_Product__c, newReplicas[0].Implemented_Product__c);

    }

    static testMethod void testInsertSubscriptionReplicaFailure() {

        list<SBQQ__Subscription__c> lstSubscriptions = new list<SBQQ__Subscription__c>{
                new SBQQ__Subscription__c()
        };

        Test.startTest();

        SubscriptionTriggerHandler.InsertSubscriptionReplica(lstSubscriptions);
        Test.stopTest();

    }

    static testMethod void scheduleSubscriptionRollupTest(){

        ImplementedProduct__c ip = [Select Account__c, Id from ImplementedProduct__c limit 1];

        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(
                SBQQ__Account__c = ip.Account__c,
                SBQQ__Discount__c = 2.05,
                SBQQ__AdditionalDiscountAmount__c = 2500,
                SBQQ__Bundled__c = true,
                SBQQ__ListPrice__c = 50,
                SBQQ__Quantity__c = 200,
                Implemented_Product__c = ip.Id
        );

        insert subscription;

        Test.startTest();

        SubscriptionTriggerHandler.scheduleSubscriptionRollup(new Set<Id>{subscription.Id});

        Test.stopTest();

    }

    @TestSetup
    static void createTestData(){
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

        Map<String, RecordTypeInfo> oppRecordTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Id oppRTId = oppRecordTypeMap.get('Education Request').getRecordTypeId();

        Opportunity opp = new Opportunity(
                Name = 'Test',
                AccountId = testAccount.Id,
                StageName = 'Assigned',
                CloseDate = Date.today(),
                RecordTypeId = oppRTId,
                PM_Estimated_Go_Live__c = system.today(),
                PM_Go_Live_Date__c  = null
        );

        insert opp;

        ImplementedProduct__c ip = new ImplementedProduct__c(
                Account__c = testAccount.Id,
                Opportunity__c = opp.Id
        );

        insert ip;

    }
}