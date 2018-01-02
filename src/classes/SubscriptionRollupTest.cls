@IsTest
private class SubscriptionRollupTest {

    static testMethod void testSubscriptionRollup() {

        test.startTest();
        ProjectRollupQueueable.doChainJob = false;

        SubscriptionReplica__c testSubscriptionReplica = [
                SELECT Id, Account__c, Product__c, Subscription__r.Project_Phase__c, Quantity__c, Subscription__c FROM SubscriptionReplica__c limit 1
        ];

        // create Project Subscription Allocation
        Project_Subscription_Allocation__c testprojectSubscriptionAllocation = new Project_Subscription_Allocation__c(
                Project__c = testSubscriptionReplica.Subscription__r.Project_Phase__c,
                Subscription__c  = testSubscriptionReplica.Id,
                Quantity_Allocation__c = 5
        );
        insert testprojectSubscriptionAllocation;

        // update Project Subscription Allocation
        testprojectSubscriptionAllocation.Phase_Implemented_Quantity__c = 5;
        testprojectSubscriptionAllocation.Implemented__c = true;
        SubscriptionReplicaTriggerHandler.InSubscriptionTrigger = false;
        update testprojectSubscriptionAllocation;

        // can’t chain queueable jobs in an Apex test so calling explicitly
        System.enqueueJob(new SubscriptionRollupQueueable(new Set<Id>{testSubscriptionReplica.Subscription__c}));
        test.stopTest();

        SBQQ__Subscription__c resultSubscription = [
                Select Id, Name, Total_Implemented_Quantity__c, SBQQ__Quantity__c, Contracted_MRR__c, Actual_MRR__c
                from SBQQ__Subscription__c where Id = :testSubscriptionReplica.Subscription__c
        ];

        Project__c resultPhaseProject = [
                Select Id, Name, Contracted_MRR__c, Actual_MRR__c
                from Project__c where Id = :testSubscriptionReplica.Subscription__r.Project_Phase__c
        ];

        // assert subscription contracted MMR and Actual MMR are the same as phase project
        system.assertEquals(resultSubscription.Contracted_MRR__c, resultPhaseProject.Contracted_MRR__c);
        system.assertEquals(resultSubscription.Actual_MRR__c, resultPhaseProject.Actual_MRR__c);

    } // end of testSubscriptionRollup()


    static testMethod void SubscriptionRollupSchedulableTest() {

        Datetime nextRun = system.now().addSeconds(5);
        String dateTimeFormat = '{0} {1} {2} {3} {4} ? {5}';
        String scheduledTime = string.format(
                dateTimeFormat,
                new String[]{
                        nextRun.second().format(),
                        nextRun.minute().format(),
                        nextRun.hour().format(),
                        nextRun.day().format(),
                        nextRun.month().format(),
                        nextRun.year().format().remove(',')
                }
        );
        system.debug('scheduleJob(): scheduledTime - ' + scheduledTime);

        String query = 'Select Id from SBQQ__Subscription__c';

        test.startTest();

        SubscriptionRollupSchedulable schedulable = new SubscriptionRollupSchedulable(5);
        schedulable = new SubscriptionRollupSchedulable(query, 5);

        String scheduledJobId = system.schedule('testProjectRollupSchedulable', scheduledTime, schedulable);

        test.stopTest();

        CronTrigger job = [Select Id, State, NextFireTime, CronExpression From CronTrigger where Id = :scheduledJobId];

        system.assertEquals(scheduledTime, job.CronExpression);

    } // end of SubscriptionRollupSchedulableTest()


    @TestSetup
    static void setupData(){

        // create Account
        Map<String, RecordTypeInfo> accountRecordTypes = Schema.sObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'SubscriptionRollupTest Customer',
                Type = 'Customer',
                RecordTypeId = accountRecordTypes.get('Customers').getRecordTypeId()
        );
        insert testAccount;

        // create Opportunity
        Map<String, RecordTypeInfo> opportunityRecordTypes = Schema.sObjectType.Opportunity.getRecordTypeInfosByName();
        Opportunity testOpportunity = new Opportunity(
                Name = 'ProjectAndOpportunityRollupTest',
                AccountId = testAccount.Id,
                Partner_Deal__c = 'NO',
                RecordTypeId = opportunityRecordTypes.get('Qualified Opportunity').getRecordTypeId(),
                StageName = '5 - Proposal / Negotiation',
                CloseDate = Date.today(),
                Contract_Type__c = 'New Customer'
        );
        insert testOpportunity;

        // create Parent Project
        Map<String, RecordTypeInfo> projectRecordTypes = Schema.sObjectType.Project__c.getRecordTypeInfosByName();
        Project__c testParentProject = new Project__c(
                RecordTypeId = projectRecordTypes.get('PS Parent Project - SaaS').getRecordTypeId(),
                Opportunity__c = testOpportunity.Id,
                Account__c = testAccount.Id
        );
        insert testParentProject;

        // create Phase
        Project__c testPhaseProject = new Project__c(
                RecordTypeId = projectRecordTypes.get('PS Project Phase SaaS').getRecordTypeId(),
                EstimatedProjectGoLiveDate__c = Date.today().addDays(7),
                ActualProjectGoLiveDate__c = Date.today().addDays(7),
                Summary__c = 'Phase 1',
                Opportunity__c = testParentProject.Opportunity__c,
                Account__c = testParentProject.Account__c,
                ParentProject__c = testParentProject.Id,
                Phase_Status__c = 'Open'
        );
        insert testPhaseProject;

        // create Product
        Product2 testProduct = new Product2(
                Name     = 'AssetTriggerHandlerTest 1',
                ProductCode ='1111',
                Category__c = 'Maintenance'
        );
        insert testProduct;

        // create Quote
        Id strRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.RecordTypeInfosByName.get('SaaS').RecordTypeId;
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
                SBQQ__Account__c = testOpportunity.AccountId,
                SBQQ__Opportunity2__c = testOpportunity.Id,
                SBQQ__Type__c = 'Quote',
                SBQQ__Status__c = 'Draft',
                RecordTypeId = strRecordtypeId,
                Usage_Rate_Type__c = 'Flat Usage Rates',
                Flat_Usage_Rates__c ='0.0140'
        );
        insert testQuote;

        // create Quoteline
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(
                SBQQ__Product__c = testProduct.Id,
                SBQQ__Existing__c = true,
                SBQQ__NetPrice__c  = 20.00,
                SBQQ__Quantity__c = 5,
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Bundled__c = false,
                SBQQ__ListPrice__c = 20
        );
        insert (testQuoteLine);

        // create Subscription
        SBQQ__Subscription__c testSubscription = new SBQQ__Subscription__c(
                SBQQ__Account__c =  testAccount.id,
                SBQQ__Quantity__c = 10,
                SBQQ__Product__c = testProduct.Id,
                Budgeted_Hours__c = 10,
                SBQQ__QuoteLine__c = testQuoteLine.id,
                Project_Phase__c = testPhaseProject.Id
        );
        insert testSubscription;
    }

}