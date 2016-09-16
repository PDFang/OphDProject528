@isTest
private class ProjectClassTests 
{
    static string premiseAssetRecordTypeId = '01270000000N0o9';
    static string saasAssetRecordTypeId = '01270000000N0oA';
    
    static testMethod void TestProjectClass_AssetSummaries() 
    {  
        List<Project__c> testProjects = new List<Project__c>();
        List<Project__c> testPhases = new List<Project__c>();
        List<Asset> testAssets = new List<Asset>();
        
        /* Get the standard pricebook. There must be a standard pricebook already in the target org.  */
        ID pb = Test.getStandardPricebookId();
        
        /* Create a product2 */
        Product2 p = new Product2();
        p.Name     = 'TEST';
        p.ProductCode ='AMC-18';    
        p.Category__c = 'Maintenance';  
        Database.insert(p);
        
        Product2 p1 = new Product2();
        p1.Name     = 'IN TEST';
        p1.ProductCode ='';  
        p1.Category__c ='Integration';    
        Database.insert(p1);
        
        /* Create a pricebook entry. */
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = pb;
        pbe.Product2Id   = p.id;
        pbe.IsActive     = true;
        pbe.UnitPrice    = 1;
        Database.insert(pbe);
        
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = pb;
        pbe1.Product2Id   = p1.id;
        pbe1.IsActive     = true;
        pbe1.UnitPrice    = 1;
        Database.insert(pbe1);
        
        //create account
        Account a = InContactBaseClass.CreateAccount('Test Account');
        insert a;
        
        //create parent projects
        Project__c parentProject = new Project__c();
        parentProject.RecordTypeId = InContactBaseClass.SelectRecordTypeIDByName('PS Parent Project - Premise','Project__c');
        parentProject.Projected_Deadline__c = system.today() + 30;
        testProjects.add(parentProject);
        
        Project__c parentProject2 = new Project__c();
        parentProject2.RecordTypeId = InContactBaseClass.SelectRecordTypeIDByName('PS Parent Project - Premise','Project__c');
        parentProject2.Projected_Deadline__c = system.today() + 30;
        testProjects.add(parentProject2);
        
        insert testProjects;
        
        //create phases
        Project__c phase1 = new Project__c();
        phase1.RecordTypeId = InContactBaseClass.SelectRecordTypeIDByName('PS Project Phase Premise WFO','Project__c');
        phase1.Projected_Deadline__c = system.today() + 30;
        phase1.ParentProject__c = parentProject.Id;
        testPhases.add(phase1);
        
        Project__c phase2 = new Project__c();
        phase2.RecordTypeId = InContactBaseClass.SelectRecordTypeIDByName('PS Project Phase Premise WFO','Project__c');
        phase2.Projected_Deadline__c = system.today() + 30;
        phase2.ParentProject__c = parentProject.Id;
        testPhases.add(phase2);
        
        Project__c phase3 = new Project__c();
        phase3.RecordTypeId = InContactBaseClass.SelectRecordTypeIDByName('PS Project Phase Premise WFO','Project__c');
        phase3.Projected_Deadline__c = system.today() + 30;
        phase3.ParentProject__c = parentProject.Id;
        testPhases.add(phase3);
        
        Project__c phase4 = new Project__c();
        phase4.RecordTypeId = InContactBaseClass.SelectRecordTypeIDByName('PS Project Phase Premise WFO','Project__c');
        phase4.Projected_Deadline__c = system.today() + 30;
        phase4.ParentProject__c = parentProject2.Id;
        testPhases.add(phase4);
        
        insert testPhases;
        
        //create premise assets
        Asset ass1 = new Asset();
        ass1.RecordTypeId = premiseAssetRecordTypeId;
        ass1.Name = 'Premise Test Asset 1';
        ass1.AccountId = a.Id;
        ass1.Parent_Project__c = parentProject.Id;
        ass1.Project_Phase__c = phase1.Id;
        ass1.Price = 10.00;
        testAssets.add(ass1);
        
        Asset ass2 = new Asset();
        ass2.RecordTypeId = premiseAssetRecordTypeId;      
        ass2.Name = 'Premise Test Asset 2';
        ass2.AccountId = a.Id;
        ass2.Parent_Project__c = parentProject.Id;
        ass2.Project_Phase__c = phase1.Id;
        ass2.Price = 55.00;
        testAssets.add(ass2);
        
        Asset ass3 = new Asset();
        ass3.RecordTypeId = premiseAssetRecordTypeId;
        ass3.Name = 'Premise Test Asset 3';
        ass3.AccountId = a.Id;
        ass3.Parent_Project__c = parentProject.Id;
        ass3.Project_Phase__c = phase2.Id;
        ass3.Price = 100.00;
        testAssets.add(ass3);
        
        Insert testAssets;
        
        Test.startTest();
        
        //Create project map and set initial asset roll-up values
        Map<Id, Project__c> projects = new Map<Id,Project__c>([SELECT Id, Project_Asset__c, Phase_Asset__c, Name FROM Project__c WHERE Id = :parentProject.Id OR Id = :parentProject2.Id OR Id = :phase1.Id OR Id = :phase2.Id OR Id = :phase3.Id OR Id = :phase4.Id]);
        
        system.assertEquals(projects.get(parentProject.Id).Project_Asset__c, 165.00);
        system.assertEquals(projects.get(phase1.Id).Phase_Asset__c, 65.00);
        system.assertEquals(projects.get(phase2.Id).Phase_Asset__c, 100.00);
        system.assertEquals(projects.get(parentProject2.Id).Project_Asset__c, Null);
        system.assertEquals(projects.get(phase3.Id).Phase_Asset__c, Null);
        system.assertEquals(projects.get(phase4.Id).Phase_Asset__c, Null);
        
        //Test deleting asset     
        delete ass2;
        
        Project__c parent = [SELECT Id, Project_Asset__c FROM Project__c WHERE Id = :parentProject.Id];
        Project__c child1 = [SELECT Id, Phase_Asset__c FROM Project__c WHERE Id = :phase1.Id];
        Project__c child2 = [SELECT Id, Phase_Asset__c FROM Project__C WHERE Id = :phase2.Id];
        
        system.assertEquals(parent.Project_Asset__c, 110.00);
        system.assertEquals(child1.Phase_Asset__c, 10.00);
        system.assertEquals(child2.Phase_Asset__c, 100.00);
        
        //test reparenting asset to new phase, same parent
        ass3.Parent_Project__c = parentProject.Id; 
        ass3.Project_Phase__c = phase1.Id;       
        
        update ass3;
        
        Project__c parent2 = [SELECT Id, Project_Asset__c FROM Project__c WHERE Id = :parentProject.Id];
        Project__c child3 = [SELECT Id, Phase_Asset__c FROM Project__c WHERE Id = :phase1.Id];
        Project__c child4 = [SELECT Id, Phase_Asset__c FROM Project__C WHERE Id = :phase2.Id];
        
        system.assertEquals(parent2.Project_Asset__c, 110.00);
        system.assertEquals(child3.Phase_Asset__c, 110.00);
        system.assertEquals(child4.Phase_Asset__c, 0.00);        
        
        //test reparenting asset to new project and new phase
        ass1.Parent_Project__c = parentProject2.Id; 
        ass1.Project_Phase__c = phase4.Id;
        
        update ass1;
        
        Project__c parent3 = [SELECT Id, Project_Asset__c FROM Project__c WHERE Id = :parentProject.Id];
        Project__c parent4 = [SELECT Id, Project_Asset__c FROM Project__c WHERE Id = :parentProject2.Id];
        Project__c child5 = [SELECT Id, Phase_Asset__c FROM Project__c WHERE Id = :phase1.Id];
        Project__c child6 = [SELECT Id, Phase_Asset__c FROM Project__C WHERE Id = :phase2.Id];
        Project__c child7 = [SELECT Id, Phase_Asset__c FROM Project__C WHERE Id = :phase4.Id];
        
        system.assertEquals(parent3.Project_Asset__c, 100.00);
        system.assertEquals(child5.Phase_Asset__c, 100.00);
        system.assertEquals(child6.Phase_Asset__c, 0.00);
        system.assertEquals(parent4.Project_Asset__c, 10.00);
        system.assertEquals(child7.Phase_Asset__c, 10.00);
        
        Test.stopTest();
    }
    
    static testMethod void TestSaaSProjectClass_AssetSummaries()
    {
        List<Project__c> testProjects = new List<Project__c>();
        List<Project__c> testPhases = new List<Project__c>();
        List<Asset> testAssets = new List<Asset>();
        
        //create account
        Account a = InContactBaseClass.CreateAccount('SaaS Parent Project Test Account');
        insert a;
        
        //create parent projects
        Project__c parentProject = new Project__c();
        parentProject.RecordTypeId = InContactBaseClass.SelectRecordTypeIDByName('PS Parent Project - SaaS','Project__c');
        parentProject.Projected_Deadline__c = system.today() + 45;
        testProjects.add(parentProject);
        
        Project__c parentProject2 = new Project__c();
        parentProject2.RecordTypeId = InContactBaseClass.SelectRecordTypeIDByName('PS Parent Project - SaaS','Project__c');
        parentProject2.Projected_Deadline__c = system.today() + 45;
        testProjects.add(parentProject2);
        
        insert testProjects;
        
        //create phases
        Project__c phase1 = new Project__c();
        phase1.RecordTypeId = InContactBaseClass.SelectRecordTypeIDByName('PS Project Phase SaaS','Project__c');
        phase1.EstimatedProjectGoLiveDate__c = system.today() + 30;
        phase1.ParentProject__c = parentProject.Id;
        phase1.Phase_Status__c  = 'Open';
        testPhases.add(phase1);
        
        Project__c phase2 = new Project__c();
        phase2.RecordTypeId = InContactBaseClass.SelectRecordTypeIDByName('PS Project Phase SaaS','Project__c');
        phase2.EstimatedProjectGoLiveDate__c = system.today() + 30;
        phase2.ParentProject__c = parentProject.Id;
        phase2.Phase_Status__c  = 'Open';
        testPhases.add(phase2);
        
        Project__c phase3 = new Project__c();
        phase3.RecordTypeId = InContactBaseClass.SelectRecordTypeIDByName('PS Project Phase SaaS','Project__c');
        phase3.EstimatedProjectGoLiveDate__c = system.today() + 30;
        phase3.ParentProject__c = parentProject.Id;
        phase3.Phase_Status__c  = 'Open';
    testPhases.add(phase3);

        
        Project__c phase4 = new Project__c();
        phase4.RecordTypeId = InContactBaseClass.SelectRecordTypeIDByName('PS Project Phase SaaS','Project__c');
        phase4.EstimatedProjectGoLiveDate__c = system.today() + 30;
        phase4.ParentProject__c = parentProject2.Id;
        phase4.Phase_Status__c  = 'Open';
        testPhases.add(phase4);
  
        insert testPhases;
        
        //create SaaS assets       
        Asset ass1 = new Asset();
        ass1.RecordTypeId = saasAssetRecordTypeId;  
        ass1.Name = 'Saas Test Asset 1';
        ass1.AccountId = a.Id;
        ass1.Parent_Project__c = parentProject.Id;
        ass1.Project_Phase__c = phase1.Id;
        ass1.Sales_Price__c = 500.00;
        ass1.Quantity = 1.00;
        ass1.Type__c = 'NRC';
    testAssets.add(ass1);  
        
        Asset ass2 = new Asset();
        ass2.RecordTypeId = saasAssetRecordTypeId; 
        ass2.Name = 'Saas Test Asset 2';
        ass2.AccountId = a.Id;
        ass2.Parent_Project__c = parentProject.Id;
        ass2.Project_Phase__c = phase1.Id;
        ass2.Sales_Price__c = 55.00;
        ass2.Quantity = 10.00;
        ass2.Type__c = 'MRC';
        testAssets.add(ass2);
        
        Asset ass3 = new Asset();
        ass3.RecordTypeId = saasAssetRecordTypeId;       
        ass3.Name = 'Saas Test Asset 3';
        ass3.AccountId = a.Id;
        ass3.Parent_Project__c = parentProject.Id;
        ass3.Project_Phase__c = phase2.Id;
        ass3.Sales_Price__c = 5.00;
        ass3.Type__c = 'Telco';
        ass3.Quantity = 2.00;
        testAssets.add(ass3);
        
        Asset ass4 = new Asset();
        ass4.RecordTypeId = saasAssetRecordTypeId;      
        ass4.Name = 'Saas Test Asset 4';
        ass4.AccountId = a.Id;
        ass4.Parent_Project__c = parentProject.Id;
        ass4.Project_Phase__c = phase2.Id;
        ass4.Sales_Price__c = 75.00;
        ass4.Quantity = 10.00;
        ass4.Type__c = 'MRC';
        testAssets.add(ass4);  
        
        insert testAssets;
        
        Test.startTest();
        system.debug('number of soql queries == >' + Limits.getQueries());
        //Create project map and set initial asset roll-up values
        Map<Id, Project__c> projects = new Map<Id,Project__c>([SELECT Id, Project_Asset__c, ProjectMRC__c, ProjectNRC__c, Project_Telco__c, MRC_Delivered__c, NRC_Delivered__c, Phase_Asset__c, PhaseMRC__c, PhaseNRC__c, Phase_Telco__c 
                                                               FROM Project__c WHERE Id = :parentProject.Id OR Id = :parentProject2.Id OR Id = :phase1.Id OR Id = :phase2.Id OR Id = :phase3.Id OR Id = :phase4.Id]);
        
        system.assertEquals(projects.get(parentProject.Id).Project_Asset__c, 1810.00);
        system.assertEquals(projects.get(parentProject.Id).ProjectMRC__c, 1300.00);
        system.assertEquals(projects.get(parentProject.Id).ProjectNRC__c, 500.00);
        system.assertEquals(projects.get(parentProject.Id).Project_Telco__c, 10.00);
        system.assertEquals(projects.get(parentProject.Id).MRC_Delivered__c, 0.00);
        system.assertEquals(projects.get(parentProject.Id).NRC_Delivered__c, 0.00);
        system.assertEquals(projects.get(phase1.Id).Phase_Asset__c, 1050.00);
        system.assertEquals(projects.get(phase1.Id).PhaseMRC__c, 550.00);
        system.assertEquals(projects.get(phase1.Id).PhaseNRC__C, 500.00);
        system.assertEquals(projects.get(phase1.Id).Phase_Telco__c, 0);
        system.assertEquals(projects.get(phase2.Id).Phase_Asset__c, 760.00);
        system.assertEquals(projects.get(phase2.Id).PhaseMRC__c, 750.00);
        system.assertEquals(projects.get(phase2.Id).PhaseNRC__C, 0.00);
        system.assertEquals(projects.get(phase2.Id).Phase_Telco__c, 10.00);
        system.assertEquals(projects.get(parentProject2.Id).Project_Asset__c, Null);
        system.assertEquals(projects.get(parentProject2.Id).ProjectMRC__c, Null);
        system.assertEquals(projects.get(parentProject2.Id).ProjectNRC__c, Null);
        system.assertEquals(projects.get(parentProject2.Id).Project_Telco__c, Null);
        system.assertEquals(projects.get(parentProject2.Id).MRC_Delivered__c, 0.00);
        system.assertEquals(projects.get(parentProject2.Id).NRC_Delivered__c, 0.00);
        system.assertEquals(projects.get(phase3.Id).Phase_Asset__c, Null);
        system.assertEquals(projects.get(phase3.Id).PhaseMRC__c, Null);
        system.assertEquals(projects.get(phase3.Id).PhaseNRC__C, Null);
        system.assertEquals(projects.get(phase3.Id).Phase_Telco__c, Null);
        system.assertEquals(projects.get(phase4.Id).Phase_Asset__c, Null);
        system.assertEquals(projects.get(phase4.Id).PhaseMRC__c, Null);
        system.assertEquals(projects.get(phase4.Id).PhaseNRC__C, Null);
        system.assertEquals(projects.get(phase4.Id).Phase_Telco__c, Null);
        
        //Test deleting asset     
       // delete ass2;
        
    	/** Project__c parent = [SELECT Id, Project_Asset__c, ProjectMRC__c, ProjectNRC__c, Project_Telco__c  FROM Project__c WHERE Id = :parentProject.Id];
        Project__c child1 = [SELECT Id, Phase_Asset__c, PhaseMRC__c, PhaseNRC__c, Phase_Telco__c FROM Project__c WHERE Id = :phase1.Id];
        Project__c child2 = [SELECT Id, Phase_Asset__c, PhaseMRC__c, PhaseNRC__c, Phase_Telco__c FROM Project__C WHERE Id = :phase2.Id];
        
        system.assertEquals(parent.Project_Asset__c, 1260.00);
        system.assertEquals(parent.ProjectMRC__c, 750.00);
        system.assertEquals(parent.ProjectNRC__c, 500.00);
        system.assertEquals(parent.Project_Telco__c, 10.00);
        system.assertEquals(child1.Phase_Asset__c, 500.00);
        system.assertEquals(child1.PhaseMRC__c, 0.00);
        system.assertEquals(child1.PhaseNRC__c, 500.00);
        system.assertEquals(child1.Phase_Telco__c, 0.00);
        system.assertEquals(child2.Phase_Asset__c, 760.00);
        system.assertEquals(child2.PhaseMRC__c, 750.00);
        system.assertEquals(child2.PhaseNRC__c, 0.00);
        system.assertEquals(child2.Phase_Telco__c, 10.00);
        
        //test reparenting asset to new phase, same parent
        ass3.Parent_Project__c = parentProject.Id; 
        ass3.Project_Phase__c = phase1.Id;       
        
        update ass3;
        
        Project__c parent2 = [SELECT Id, Project_Asset__c, ProjectMRC__c, ProjectNRC__c, Project_Telco__c  FROM Project__c WHERE Id = :parentProject.Id];
        Project__c child3 = [SELECT Id, Phase_Asset__c, PhaseMRC__c, PhaseNRC__c, Phase_Telco__c FROM Project__c WHERE Id = :phase1.Id];
        Project__c child4 = [SELECT Id, Phase_Asset__c, PhaseMRC__c, PhaseNRC__c, Phase_Telco__c FROM Project__C WHERE Id = :phase2.Id];
        
        system.assertEquals(parent2.Project_Asset__c, 1260.00);
        system.assertEquals(parent2.ProjectMRC__c, 750.00);
        system.assertEquals(parent2.ProjectNRC__c, 500.00);
        system.assertEquals(parent2.Project_Telco__c, 10.00);
        system.assertEquals(child3.Phase_Asset__c, 510.00);
        system.assertEquals(child3.PhaseMRC__c, 0.00);
        system.assertEquals(child3.PhaseNRC__c, 500.00);
        system.assertEquals(child3.Phase_Telco__c, 10.00);
        system.assertEquals(child4.Phase_Asset__c, 750.00);
        system.assertEquals(child4.PhaseMRC__c, 750.00);
        system.assertEquals(child4.PhaseNRC__c, 0.00);
        system.assertEquals(child4.Phase_Telco__c, 00.00);
        **/
     	
        
        testAssets[2].Parent_Project__c = parentProject.Id; 
        testAssets[2].Project_Phase__c = phase1.Id;       
        
        
        //test reparenting asset to new project and new phase
        //
       
        testAssets[0].Parent_Project__c = parentProject2.Id; 
        testAssets[0].Project_Phase__c = phase3.Id;
        
        testAssets.remove(1);
        update testAssets;
         
        
        
        Project__c parent3 = [SELECT Id, Project_Asset__c, ProjectMRC__c, ProjectNRC__c, Project_Telco__c  FROM Project__c WHERE Id = :parentProject.Id];
        Project__c parent4 = [SELECT Id, Project_Asset__c, ProjectMRC__c, ProjectNRC__c, Project_Telco__c  FROM Project__c WHERE Id = :parentProject2.Id];
        Project__c child5 = [SELECT Id, Phase_Asset__c, PhaseMRC__c, PhaseNRC__c, Phase_Telco__c FROM Project__c WHERE Id = :phase1.Id];
        Project__c child6 = [SELECT Id, Phase_Asset__c, PhaseMRC__c, PhaseNRC__c, Phase_Telco__c FROM Project__C WHERE Id = :phase2.Id];
        Project__c child7 = [SELECT Id, Phase_Asset__c, PhaseMRC__c, PhaseNRC__c, Phase_Telco__c FROM Project__C WHERE Id = :phase3.Id];
        
        system.assertEquals(parent3.Project_Asset__c, 1310.00);
      /*  system.assertEquals(parent3.ProjectMRC__c, 750.00);
        system.assertEquals(parent3.ProjectNRC__c, 0.00);
        system.assertEquals(parent3.Project_Telco__c, 10.00);
        system.assertEquals(child5.Phase_Asset__c, 10.00);
        system.assertEquals(child5.PhaseMRC__c, 0.00);
        system.assertEquals(child5.PhaseNRC__c, 0.00);
        system.assertEquals(child5.Phase_Telco__c, 10.00);
        system.assertEquals(child6.Phase_Asset__c, 750.00);
        system.assertEquals(child6.PhaseMRC__c, 750.00);
        system.assertEquals(child6.PhaseNRC__c, 0.00);
        system.assertEquals(child6.Phase_Telco__c, 00.00);
        system.assertEquals(parent4.Project_Asset__c, 500.00);
        system.assertEquals(parent4.ProjectMRC__c, 00.00);
        system.assertEquals(parent4.ProjectNRC__c, 500.00);
        system.assertEquals(parent4.Project_Telco__c, 0.00);
        system.assertEquals(child7.Phase_Asset__c, 500.00);
        system.assertEquals(child7.PhaseMRC__c, 0.00);
        system.assertEquals(child7.PhaseNRC__c, 500.00);
        system.assertEquals(child7.Phase_Telco__c, 00.00);
        */
        //Test closing a phase 
        /*phase2.Phase_Status__c = 'Closed'; 
        update phase2;
       
        Project__c parent5 = [SELECT Id, MRC_Delivered__c, NRC_Delivered__c  FROM Project__c WHERE Id = :parentProject.Id];
        
        system.assertEquals(parent5.MRC_Delivered__c, 750.00);
        system.assertEquals(parent5.NRC_Delivered__c, 0.00 );
         */
        
        Test.stopTest();
    }
}