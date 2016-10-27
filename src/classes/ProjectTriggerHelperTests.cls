@isTest
public class ProjectTriggerHelperTests
{
    private static Id childRTId = [SELECT id from RecordType where Name = 'PS Project Phase SaaS'].Id;
    private static Id parentProjectRTId = [SELECT id from RecordType where Name = 'PS Parent Project - SaaS'].Id;

    public static testMethod void testUpdateParentPlannedHours()
    {
        List<Project__c> parentProjectList = new List<Project__c>();
        List<Project__c> childProjectList = new List<Project__c>();

        //Parent Projects
        Project__c parentProject1 = new Project__c(
            RecordTypeId = parentProjectRTId,
            Summary__c = 'This is the parent Project 1',
            ProjectType__c = 'CEM'
        );

        Project__c parentProject2 = new Project__c(
            RecordTypeId = parentProjectRTId,
            Summary__c = 'This is the parent Project 2',
            ProjectType__c = 'CEM'
        );

        parentProjectList.add(parentProject1);
        parentProjectList.add(parentProject2);

        insert parentProjectList;

        // Child Projects for Parent Project 1
        Project__c phaseProject1 = new Project__c(
            Summary__c = 'This is child project 1',
            RecordTypeId = childRTId,
            PlannedHours__c = 55.5,
            ParentProject__c = parentProject1.Id,
            PercentComplete__c = 10,
            Team__c = 'Echo'
        );

        Project__c phaseProject2 = new Project__c(
            Summary__c = 'This is child project 2',
            RecordTypeId = childRTId,
            PlannedHours__c = 10,
            ParentProject__c = parentProject1.Id,
            PercentComplete__c = 10,
            Team__c = 'Echo'
        );
        
        childProjectList.add(phaseProject1);
        childProjectList.add(phaseProject2);
        
         // Child Projects for Parent Project 2
         Project__c phaseProject3 = new Project__c(
            Summary__c = 'This is child project 3',
            RecordTypeId = childRTId,
            PlannedHours__c = 81.5,
            ParentProject__c = parentProject2.Id,
            PercentComplete__c = 10,
            Team__c = 'Echo'
        );

        Project__c phaseProject4 = new Project__c(
            Summary__c = 'This is child project 4',
            RecordTypeId = childRTId,
            PlannedHours__c = 100,
            ParentProject__c = parentProject2.Id,
            PercentComplete__c = 10,
            Team__c = 'Echo'
        );

        childProjectList.add(phaseProject3);
        childProjectList.add(phaseProject4);

        insert childProjectList;

        Project__c updatedParentProject1 = [SELECT Id, PlannedHours__c FROM Project__C where Id = :parentProject1.Id];
        Project__c updatedParentProject2 = [SELECT Id, PlannedHours__c FROM Project__C where Id = :parentProject2.Id];

        System.assertEquals(65.5, updatedParentProject1.PlannedHours__c);
        System.assertEquals(181.5, updatedParentProject2.PlannedHours__c);
    }

    public static testMethod void testUpdateAssetStatusForPhasedProject()
    {
        List<ImplementedProduct__c> implementedProducts = new List<ImplementedProduct__c>();
        List<Asset> assets = new List<Asset>();

        // Create account
        Account accountRecord = InContactBaseClass.CreateAccount('Test Account');
        insert accountRecord;

  
        Opportunity opp = new Opportunity(
            Name = 'Test',
            AccountId = accountRecord.Id,
            StageName = 'Assigned',
            CloseDate = Date.today(),
            RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Education Request', 'Opportunity'),
            PM_Estimated_Go_Live__c = system.today(),
            PM_Go_Live_Date__c  = null
        );

        insert opp;     

        // Parent Project
        Project__c parentProject1 = new Project__c(
            RecordTypeId = parentProjectRTId,
            Summary__c = 'This is the parent Project 1',
            ProjectType__c = 'CEM',
            Opportunity__c = opp.Id
            
        );

        insert parentProject1;
        
         // Parent Project
        Project__c childProject1 = new Project__c(
            RecordTypeId = childRTId,
            Summary__c = 'This is the Child Project 1',
            ProjectType__c = 'CEM',
            ParentProject__c = parentProject1.Id            
        );

        insert childProject1;
        
        

        ImplementedProduct__c ip1 = new ImplementedProduct__c(
            Account__c = accountRecord.Id,
            Opportunity__c = opp.Id
        );

        implementedProducts.add(ip1);
        insert implementedProducts;

        Asset asset1 = new Asset(
            Name = 'Asset asset1',
            Project_Phase__c = childProject1.Id,
            ImplementedProduct__c = ip1.Id,
            AccountId = accountRecord.Id
        );
       
        assets.add(asset1);

        insert assets;

        Test.startTest();

        Project__c testProject = [SELECT Id, ParentProject__r.Opportunity__r.PM_Go_Live_Date__c from Project__c where Id = :childProject1.Id];
        testProject.ActualProjectGoLiveDate__c = System.today();
        update testProject;

        // Check that the assets were updated. Since we are using sandboxed data, only the ones we inserted should be retrieved
        for (Asset assetRecord: [SELECT Status from Asset])
        {
            System.assertEquals('4 - Delivered', assetRecord.Status);

        }
        
        // Check that the implemented products associated to the asset records were updated
        for (ImplementedProduct__c ip: [SELECT Id, Status__c, GoLiveDate__c from ImplementedProduct__c])
        {
            System.assertEquals('Implemented', ip.Status__c);
            System.assertEquals(System.today(), ip.GoLiveDate__c);
        }

       Test.stopTest();
    }

    static testmethod void createProjectTasks(){

        Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        OrderManagementTask__c omTask = new OrderManagementTask__c();
        omTask.Name = 'Test OM';
        omTask.DaysUntilDue__c = 7;
        omTask.Description__c = 'New OM Task';
        omTask.CustomerOrder__c = true;
        omTask.NewOrder__c = true;
        omTask.Type__c = 'OM - Good Order';
        omTask.Order__C = 1;
        insert omTask;

        ProductReadinessTask__c prTask = new ProductReadinessTask__c();
        prTask.Name = 'Test PR';
        prTask.CorePlus__c = true;
        prTask.TaskType__c = 'Work';
        prTask.Description__c = 'Test';
        prTask.AssignTo__c = 'Concept Owner';
        prTask.DaysPrior__c = 5;
        prTask.Order__C = 1;
        insert prTask;

        DedicatedProvisioningTask__c dpTask = new DedicatedProvisioningTask__c();
        dpTask.Name = 'DIA 01';
        dpTask.Dia__c = true;
        dpTask.TaskType__c = 'Work';
        dpTask.Task__c = 'Review';
        dpTask.Order__C = 1;
        insert dpTask;

        test.startTest();
        List<Project__c> projectList = new List<Project__c>();
        // Dedicated Provisioning
        Project__c dpProject = new Project__c();
        dpProject.Summary__c = 'Dedicated Provisioning';
        dpProject.RecordTypeId = rtMapByName.get('Dedicated Provisioning').getRecordTypeId();
        dpProject.ProjectType__c = 'DIA';
        projectList.add(dpProject);

        //Order Management
        Project__c omProject = new Project__c();
        omProject.Summary__c = 'Order Management';
        omProject.RecordTypeId = rtMapByName.get('Order Management').getRecordTypeId();
        omProject.ProjectType__c = 'Customer';
        omProject.RequestType__c = 'New';
        projectList.add(omProject);

        // Product Readiness
        Project__c prProject = new Project__c();
        prProject.Summary__c = 'Product Readiness';
        prProject.RecordTypeId = rtMapByName.get('Product Readiness Project').getRecordTypeId();
        prProject.PricingRateReview__c = true;
        prProject.TargetLaunchDate__c = system.today().addMonths(1);
        projectList.add(prProject);

        insert projectList;
        test.stopTest();

        List<Task> result = [Select Id from Task where WhatId IN :projectList];
        system.AssertEquals(3, result.size(), 'One or more task was not created.');
    }
}