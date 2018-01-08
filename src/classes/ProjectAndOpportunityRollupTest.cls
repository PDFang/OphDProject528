/**
 * Created by mohandaas.rangaswamy on 12/7/2017.
 */

@IsTest
private class ProjectAndOpportunityRollupTest {

    static testMethod void testGoLiveDateRollup() {

        Project__c parentProject = [
                Select Id, Account__c, Opportunity__c
                from Project__c where RecordType.Name = 'PS Parent Project - SaaS'
        ];

        test.startTest();

        ProjectRollupQueueable.doChainJob = false;

        List<Project__c> projectList = new List<Project__c>();

        Map<String, RecordTypeInfo> projectRecordTypes = Schema.sObjectType.Project__c.getRecordTypeInfosByName();

        Project__c phase1 = new Project__c();
        phase1.RecordTypeId = projectRecordTypes.get('PS Project Phase SaaS').getRecordTypeId();
        phase1.EstimatedProjectGoLiveDate__c = Date.today().addDays(7);
        phase1.ActualProjectGoLiveDate__c = Date.today().addDays(7);
        phase1.Summary__c = 'Phase 1';
        phase1.Opportunity__c = parentProject.Opportunity__c;
        phase1.Account__c = parentProject.Account__c;
        phase1.ParentProject__c = parentProject.Id;
        phase1.Phase_Status__c = 'Open';
        projectList.add(phase1);


        Project__c phase2 = new Project__c();
        phase2.RecordTypeId = projectRecordTypes.get('PS Project Phase SaaS').getRecordTypeId();
        phase2.EstimatedProjectGoLiveDate__c = Date.today().addDays(10);
        phase2.ActualProjectGoLiveDate__c = Date.today().addDays(10);
        phase2.Summary__c = 'Phase 2';
        phase2.Opportunity__c = parentProject.Opportunity__c;
        phase2.Account__c = parentProject.Account__c;
        phase2.ParentProject__c = parentProject.Id;
        phase2.Phase_Status__c = 'Open';
        projectList.add(phase2);

        insert projectList;

        // can’t chain queueable jobs in an Apex test so calling explicitly
        System.enqueueJob(new OpportunityRollupQueueable(new Set<Id>{parentProject.Opportunity__c}));

        test.stopTest();

        AggregateResult ar = [
                Select min(Original_Phase_Forecasted_Go_Live_Date__c) minForecastedPhaseGoLiveDate, sum(Times_Go_Live_Date_Changed__c) noOfTimesPhaseGoLiveDateChanged,
                        min(EstimatedProjectGoLiveDate__c) minEstimatedPhaseGoLiveDate, max(EstimatedProjectGoLiveDate__c) maxEstimatedPhaseGoLiveDate,
                        min(ActualProjectGoLiveDate__c) minActualPhaseGoLiveDate, max(ActualProjectGoLiveDate__c) maxActualPhaseGoLiveDate, sum(Is_Phase_Open__c) noOfOpenPhases
                from Project__c
                where ParentProject__c = :parentProject.Id
                group by ParentProject__c
        ];

        // assert parent project

        Project__c parent = [
                Select Original_Forecasted_Initial_Go_Live_Date__c, Estimated_Project_Initial_Go_Live_Date__c, Number_of_Open_Phases__c,
                        Estimated_Project_End__c, Actual_Initial_Phase_Go_Live__c, Actual_Latest_Go_Live_Date__c
                From Project__c where Id = :parentProject.Id
        ];

        // Original_Forecasted_Initial_Go_Live_Date displays earliest value saved for Field: Original_Phase_Forecasted_Go_Live_Date__c from all child PS Phase Project Saas records
        system.assertEquals((Date) ar.get('minForecastedPhaseGoLiveDate'), parent.Original_Forecasted_Initial_Go_Live_Date__c);
        // Estimated_Project_Initial_Go_Live_Date__c displays earliest value of Field EstimatedProjectGoLiveDate__c on all child PS Project Phase SaaS records
        system.assertEquals((Date) ar.get('minEstimatedPhaseGoLiveDate'), parent.Estimated_Project_Initial_Go_Live_Date__c);
        // Estimated_Project_End__c displays latest value of Field EstimatedProjectGoLiveDate__c on all child PS Project Phase SaaS records
        system.assertEquals((Date) ar.get('maxEstimatedPhaseGoLiveDate'), parent.Estimated_Project_End__c);
        // Actual_Initial_Phase_Go_Live__c displays the earliest value of Field ActualProjectGoLiveDate__c on all child PS Project Phase SaaS records
        system.assertEquals((Date) ar.get('minActualPhaseGoLiveDate'), parent.Actual_Initial_Phase_Go_Live__c);
        // Actual_Latest_Go_Live_Date__c displays the latest value of Field ActualProjectGoLiveDate__c] on all child PS Project Phase SaaS records
        system.assertEquals((Date) ar.get('maxActualPhaseGoLiveDate'), parent.Actual_Latest_Go_Live_Date__c);
        // no of child PS Project Phase records that are not in 'Closed' or 'Canceled' status
        system.assertEquals((Decimal) ar.get('noOfOpenPhases'), parent.Number_of_Open_Phases__c);

        // assert opportunity

        Opportunity testOpportunity = [Select Original_Forecasted_Initial_Go_Live_Date__c, PM_Estimated_Go_Live__c, PM_Go_Live_Date__c from Opportunity where Id = :parentProject.Opportunity__c];

        // Original_Forecasted_Initial_Go_Live_Date__c displays the earliest value of Field Original_Forecasted_Initial_Go_Live_Date from all related Projects with "PS Parent Project - Saas" record type
        system.assertEquals(parent.Original_Forecasted_Initial_Go_Live_Date__c, testOpportunity.Original_Forecasted_Initial_Go_Live_Date__c);
        // PM_Estimated_Go_Live__c displays the earliest value of Field Estimated_Project_Initial_Go_Live_Date__c from all related Projects with "PS Parent Project - Saas" record type
        system.assertEquals(parent.Estimated_Project_Initial_Go_Live_Date__c, testOpportunity.PM_Estimated_Go_Live__c);
        // PM_Go_Live_Date__c displays the earliest value of Field Actual_Initial_Phase_Go_Live__c from all related Projects with "PS Parent Project - Saas" record type
        system.assertEquals(parent.Actual_Initial_Phase_Go_Live__c, testOpportunity.PM_Go_Live_Date__c);

    }

    static testMethod void ProjectRollupSchedulableTest() {

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

        test.startTest();
        String scheduledJobId = system.schedule('testProjectRollupSchedulable', scheduledTime, new ProjectRollupSchedulable(5));
        String scheduledJobId2 = system.schedule('test2ProjectRollupSchedulable', scheduledTime, new ProjectRollupSchedulable('Select Id from Project__c where createddate = today', 5));
        test.stopTest();

        CronTrigger job = [Select Id, State, NextFireTime, CronExpression From CronTrigger where Id = :scheduledJobId];
        CronTrigger job2 = [Select Id, State, NextFireTime, CronExpression From CronTrigger where Id = :scheduledJobId];
        system.assertEquals(scheduledTime, job.CronExpression);
        system.assertEquals(scheduledTime, job2.CronExpression);

    } // end of ProjectRollupSchedulableTest()

    static testMethod void OpportunityRollupSchedulableTest() {

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

        Set<String> projectRecordTypes = new Set<String>{
                'PM-Standard'
        };

        test.startTest();
        String scheduledJobId = system.schedule('testOpportunityRollupSchedulable', scheduledTime, new OpportunityRollupSchedulable(5));
        String scheduledJobId2 = system.schedule('test2OpportunityRollupSchedulable', scheduledTime, new OpportunityRollupSchedulable('Select Id from Opportunity where Createddate = today', 5));
        test.stopTest();

        CronTrigger job = [Select Id, State, NextFireTime, CronExpression From CronTrigger where Id = :scheduledJobId];
        CronTrigger job2 = [Select Id, State, NextFireTime, CronExpression From CronTrigger where Id = :scheduledJobId];
        system.assertEquals(scheduledTime, job.CronExpression);
        system.assertEquals(scheduledTime, job2.CronExpression);

    } // end of OpportunityRollupSchedulableTest()


    @TestSetup
    static void setupData(){

        Map<String, RecordTypeInfo> accountRecordTypes = Schema.sObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'ProjectAndOpportunityRollupTest Customer',
                Type = 'Customer',
                RecordTypeId = accountRecordTypes.get('Customers').getRecordTypeId()
        );

        insert testAccount;

        Map<String, RecordTypeInfo> opportunityRecordTypes = Schema.sObjectType.Opportunity.getRecordTypeInfosByName();

        Opportunity testOpp = new Opportunity(
                Name = 'ProjectAndOpportunityRollupTest',
                AccountId = testAccount.Id,
                Partner_Deal__c = 'NO',
                RecordTypeId = opportunityRecordTypes.get('Qualified Opportunity').getRecordTypeId(),
                StageName = '5 - Proposal / Negotiation',
                CloseDate = Date.today(),
                Contract_Type__c = 'New Customer'
        );
        insert testOpp;

        Map<String, RecordTypeInfo> projectRecordTypes = Schema.sObjectType.Project__c.getRecordTypeInfosByName();

        Project__c parentProject = new Project__c();
        parentProject.RecordTypeId = projectRecordTypes.get('PS Parent Project - SaaS').getRecordTypeId();
        parentProject.Opportunity__c = testOpp.Id;
        parentProject.Account__c = testAccount.Id;
        insert parentProject;


    }
}