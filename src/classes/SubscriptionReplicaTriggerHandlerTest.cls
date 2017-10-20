@IsTest
private class SubscriptionReplicaTriggerHandlerTest {
    private static Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
    private static Date actualGoLiveDate = Date.today();

    static void addSubscriptions() {
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

        Opportunity testOpportunity = new Opportunity(
                Account = testAccount,
                Amount = 5.0,
                Name = 'Test Opportunity',
                StageName = 'One',
                CloseDate = Date.today(),
                AccountId = testAccount.Id
        );

        insert testOpportunity;

        ImplementedProduct__c testProduct = new ImplementedProduct__c(
                Account__c = testAccount.Id,
                Status__c = 'New',
                Product__c = 'Dialer',
                Opportunity__c = testOpportunity.Id
        );

        insert testProduct;

        Project__c testProject = new Project__c(
                Account__c = testAccount.Id,
                ActualProjectGoLiveDate__c = actualGoLiveDate
        );

        insert testProject;

        List<SBQQ__Subscription__c> subscriptions = new List<SBQQ__Subscription__c>();
        subscriptions.add(new SBQQ__Subscription__c(
                SBQQ__Account__c = testAccount.Id,
                SBQQ__Discount__c = 2.05,
                SBQQ__AdditionalDiscountAmount__c = 2500,
                SBQQ__Bundled__c = true,
                SBQQ__ListPrice__c = 50,
                SBQQ__Quantity__c = 200,
                Project_Phase__c = testProject.Id,
                Implemented_Product__c = testProduct.Id
        ));

        insert subscriptions;
    }

    static testMethod void testUpdatingCustomSubscriptionWillUpdateSubscriptionAndImplementedProduct() {
        //add Subscription objects
        addSubscriptions();
        List<SubscriptionReplica__c> subscriptionReplicas = [select Id, Status__c, Subscription__c from SubscriptionReplica__c limit 1];

        //When a (custom) subscription record is set to a status of '4-Delivered'
        subscriptionReplicas[0].Status__c = '4 - Delivered';

        Test.startTest();
        update subscriptionReplicas;
        Test.stopTest();

        SubscriptionReplica__c replica = [select Id, Status__c, Install_Date__c, Subscription__c, ImplementedProduct__c from SubscriptionReplica__c where Id = :subscriptionReplicas[0].Id];
        SBQQ__Subscription__c subscription = [select Id, Status__c, Install_Date__c, Implemented_Product__r.Status__c, Implemented_Product__r.GoLiveDate__c, Implemented_Product__c
                                                from SBQQ__Subscription__c
                                                where Id = :replica.Subscription__c][0];

        System.assertEquals(replica.ImplementedProduct__c, subscription.Implemented_Product__c, 'Implemented_Product__c does not match between Subscription and SubscriptionReplica__c');
        System.assertNotEquals(null, replica.ImplementedProduct__c, 'SubscriptionReplica__c ImplementedProduct__c is null');
        System.assertNotEquals(null, subscription.Implemented_Product__c, 'Subscription__c Implemented_Product__c is null');
        //The "parent" subscription record status is updated to '4-Delivered'
        System.assertEquals('4 - Delivered', subscription.Status__c, 'SBQQ__Subscription__c status was not correctly updated');
        //The "parent" subscription install date is set to the "Actual Go-Live Date" from the project phase
        System.assertEquals(actualGoLiveDate, subscription.Install_Date__c, 'SBQQ__Subscription__c Install_Date__c was not correctly updated');

        //The (custom) subscription install date is set to the "Actual Go-Live Date" from the project phase
        System.assertEquals(actualGoLiveDate, replica.Install_Date__c, 'SubscriptionReplica__c Install_Date__c was not correctly updated');

        //The status of the related implemented product is set to "Implemented"
        System.assertEquals('Implemented', subscription.Implemented_Product__r.Status__c, 'The Implemented Product status was not correctly updated');
        //The "Go Live Date" of the implemented product is set to the subscription "Install Date"
        System.assertEquals(actualGoLiveDate, subscription.Implemented_Product__r.GoLiveDate__c, 'The Implemented Product Go Live Date was not correctly updated');
    }

    static testMethod void testUpdatingCustomSubscriptionToDeliveredOnlyUpdatesFirstTime() {
        //add subscription objects
        addSubscriptions();

        SubscriptionReplica__c replica = [select Id, Status__c from SubscriptionReplica__c limit 1][0];

        //update the status and save it
        replica.Status__c = '4 - Delivered';

        update replica;

        replica = [select Id, Status__c from SubscriptionReplica__c where Id = :replica.Id][0];
        //change the status to something other than '4-Delivered'
        replica.Status__c = '1 - New';
        update replica;

        //now test that when the status is changed back to '4-Delivered' it doesn't do any of the updates
        //change the actual go live date to see if it is used
        Project__c testProject = [select ActualProjectGoLiveDate__c from Project__c limit 1][0];

        testProject.ActualProjectGoLiveDate__c = testProject.ActualProjectGoLiveDate__c.addDays(14);

        update testProject;

        replica = [select Id, Status__c from SubscriptionReplica__c where Id = :replica.Id][0];

        replica.Status__c = '4 - Delivered';

        Test.startTest();
        update replica;
        Test.stopTest();

        //the updates should only happen the first time the status is set to '4-Delivered'
        replica = [select Id, Status__c, Install_Date__c, Subscription__c from SubscriptionReplica__c where Id = :replica.Id];

        SBQQ__Subscription__c subscription = [select Id, Status__c, Install_Date__c, Implemented_Product__r.Status__c, Implemented_Product__r.GoLiveDate__c
                                                from SBQQ__Subscription__c
                                                where Id = :replica.Subscription__c][0];

        System.assertEquals('4 - Delivered', subscription.Status__c, 'Subscription status is incorrect');
        System.assertEquals(actualGoLiveDate, subscription.Install_Date__c, 'Subscription Install_Date__c should not be updated');
        System.assertEquals(actualGoLiveDate, replica.Install_Date__c, 'SubsriptionReplica__c Install_Date__c should not be updated');
        System.assertEquals('Implemented', subscription.Implemented_Product__r.Status__c, 'Implemented Product status should not be updated');
    }
}