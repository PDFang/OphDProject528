@isTest
private class LinkedTaskHandlerTest {
	
	@isTest static void test_method_For_Incident() {
		
        list<BMCServiceDesk__Urgency__c> urgencies = TestUtilities.createRFUrgencyRecords();
        list<BMCServiceDesk__Impact__c> impacts = TestUtilities.createRFImpactRecords();
        insert urgencies;
        insert impacts;

        //Creating Category           
        BMCServiceDesk__Category__c testCat = new BMCServiceDesk__Category__c(
        	Name='Performance Issue', 
            BMCServiceDesk__AvailableForIncidents__c= true
        );
        Insert testcat;

        BMCServiceDesk__Status__c testStatusVal1 = new BMCServiceDesk__Status__c(
        Name='OPENED', 
        BMCServiceDesk__appliesToIncident__c = true,  
        BMCServiceDesk__appliesToTask__c =TRUE); 

         BMCServiceDesk__Status__c testStatusVal2 = new BMCServiceDesk__Status__c(
        Name='CLOSED', 
        BMCServiceDesk__appliesToIncident__c = true,  
        BMCServiceDesk__appliesToTask__c =TRUE);
 
         BMCServiceDesk__Status__c testStatusVal3 = new BMCServiceDesk__Status__c(
        Name='ALL TASKS COMPLETED', 
        BMCServiceDesk__appliesToIncident__c = true,  
        BMCServiceDesk__appliesToTask__c =TRUE); 
		 insert testStatusVal1;insert testStatusVal2;insert testStatusVal3;

		List<Group> g = [ SELECT Name, Id FROM Group WHERE Name = 'Network' LIMIT 1 ];

         BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c (
            BMCServiceDesk__FKClient__c = userinfo.getUserId(),
            BMCServiceDesk__FKImpact__c = impacts[0].Id,
            BMCServiceDesk__FKCategory__c = testCat.Id,
            BMCServiceDesk__FKUrgency__c = urgencies[0].Id,
            BMCServiceDesk__FKStatus__c = testStatusVal1.id,           
            BMCServiceDesk__incidentDescription__c = 'Test',
            RF_Product_Impacted__c='ASR',            
            RF_Customers_May_Experience_following__c='Testing',
            RF_Customer_Action__c='Testing',
           RF_Platform_s_Impacted__c='C1 - inContact; C2 - inContact', 
            OwnerId = g[0].Id
        );
        insert inc;

        BMCServiceDesk__Task__c task1 = 
       						new BMCServiceDesk__Task__c(BMCServiceDesk__templateOrder__c = 1,
       													BMCServiceDesk__FKClient__c = userinfo.getUserId(),
       													BMCServiceDesk__taskDescription__c = 'Dummy Task 1',
       													BMCServiceDesk__FKImpact__c = impacts[0].Id,
            											BMCServiceDesk__FKCategory__c = testCat.Id,
            											BMCServiceDesk__FKUrgency__c = urgencies[0].Id,
       													BMCServiceDesk__FKStatus__c = testStatusVal1.id,
       													BMCServiceDesk__FKIncident__c = inc.id);
       	insert task1;

       	Test.startTest();
       	BMCServiceDesk__Status__c statusval = [Select Id,Name from BMCServiceDesk__Status__c where Name='CLOSED'];      	

        BMCServiceDesk__Task__c updatedtask1 = [Select Id,BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name,
        											   BMCServiceDesk__FKCategory__c,
        											   BMCServiceDesk__taskResolution__c from BMCServiceDesk__Task__c where Id =: task1.Id];
        updatedtask1.BMCServiceDesk__FKStatus__c = statusval.Id;
        updatedtask1.BMCServiceDesk__FKCategory__c = testCat.Id;
        updatedtask1.BMCServiceDesk__taskResolution__c = 'Resolved';
        update updatedtask1;
		
		
		BMCServiceDesk__Incident__c updatedIncident1 = [Select Id,BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name
        											    from BMCServiceDesk__Incident__c where Id =: inc.Id];

        system.debug('updatedtask1'+updatedtask1);
        system.debug('incident task'+inc.BMCServiceDesk__FKStatus__c);
        system.debug('Status 1'+testStatusVal1.Name + ' '+testStatusVal1.Id);
         system.debug('Status 2'+testStatusVal3.Name + ' '+testStatusVal2.Id);
		system.debug('Status 3'+testStatusVal3.Name + ' '+testStatusVal3.Id);
        system.assertEquals(updatedIncident1.BMCServiceDesk__FKStatus__c,testStatusVal3.Id);
        Test.stopTest();

	}

	@isTest static void test_method_For_Problem (){
		
        list<BMCServiceDesk__Urgency__c> urgencies = TestUtilities.createRFUrgencyRecords();
        list<BMCServiceDesk__Impact__c> impacts = TestUtilities.createRFImpactRecords();
        insert urgencies;
        insert impacts;

        //Creating Category           
        BMCServiceDesk__Category__c testCat = new BMCServiceDesk__Category__c(
        	Name='Performance Issue', 
            BMCServiceDesk__AvailableForIncidents__c= true
        );
        Insert testcat;

        BMCServiceDesk__Status__c testStatusVal1 = new BMCServiceDesk__Status__c(
        Name='OPENED', 
        BMCServiceDesk__appliesToProblem__c = true,  
        BMCServiceDesk__appliesToTask__c =TRUE); 

         BMCServiceDesk__Status__c testStatusVal2 = new BMCServiceDesk__Status__c(
        Name='CLOSED', 
        BMCServiceDesk__appliesToProblem__c = true,  
        BMCServiceDesk__appliesToTask__c =TRUE);

         BMCServiceDesk__Status__c testStatusVal3 = new BMCServiceDesk__Status__c(
        Name='ALL TASKS COMPLETED', 
        BMCServiceDesk__appliesToProblem__c = true,  
        BMCServiceDesk__appliesToTask__c =TRUE); 
		 insert testStatusVal1;insert testStatusVal2;insert testStatusVal3;

		List<Group> g = [ SELECT Name, Id FROM Group WHERE Name = 'Network' LIMIT 1 ];

         BMCServiceDesk__Problem__c problem = new BMCServiceDesk__Problem__c (
         	BMCServiceDesk__Problem_Source__c = 'Incident',
            BMCServiceDesk__FKImpact__c = impacts[0].Id,
            BMCServiceDesk__FKCategory__c = testCat.Id,
            BMCServiceDesk__FKUrgency__c = urgencies[0].Id,
            BMCServiceDesk__FKStatus__c = testStatusVal1.id,           
            Ca_Summary__c = 'Test',
            BMCServiceDesk__Problem_Description__c='Description',            
            RF_Symptoms_Customer_Experience__c='API-Failure');
        insert problem;

        BMCServiceDesk__Task__c task1 = 
       						new BMCServiceDesk__Task__c(BMCServiceDesk__templateOrder__c = 1,
       													BMCServiceDesk__FKClient__c = userinfo.getUserId(),
       													BMCServiceDesk__taskDescription__c = 'Dummy Task 1',
       													BMCServiceDesk__FKImpact__c = impacts[0].Id,
            											BMCServiceDesk__FKCategory__c = testCat.Id,
            											BMCServiceDesk__FKUrgency__c = urgencies[0].Id,
       													BMCServiceDesk__FKStatus__c = testStatusVal1.id,
       													BMCServiceDesk__FKProblem__c = problem.id);
       	insert task1;

       	Test.startTest();
       	BMCServiceDesk__Status__c statusval = [Select Id,Name from BMCServiceDesk__Status__c where Name='CLOSED'];      	

        BMCServiceDesk__Task__c updatedtask1 = [Select Id,BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name,
        											   BMCServiceDesk__FKCategory__c,
        											   BMCServiceDesk__taskResolution__c from BMCServiceDesk__Task__c where Id =: task1.Id];
        updatedtask1.BMCServiceDesk__FKStatus__c = statusval.Id;
        updatedtask1.BMCServiceDesk__FKCategory__c = testCat.Id;
        updatedtask1.BMCServiceDesk__taskResolution__c = 'Resolved';
        update updatedtask1;
		
		
		BMCServiceDesk__Problem__c updatedProblem1 = [Select Id,BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name
        											    from BMCServiceDesk__Problem__c where Id =: problem.Id];

        system.assertEquals(updatedProblem1.BMCServiceDesk__FKStatus__c,testStatusVal3.Id);
        Test.stopTest();

	}
	
	
	
}