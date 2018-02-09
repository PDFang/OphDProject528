/* =================================================================================================
*   Version     Date                   Comment
* =================================================================================================
*   1.0        15-Feb-2017            OpportunityTriggerHandlerTest
*   1.1        21-Mar-2017            OpportunityTriggerHandlerTest to check Buying Stage and Portfolioscope field values

*																			on Opportunity object
**/
@isTest
private class OpportunityTriggerHandlerTest {
	//test data of Opportunity
	public static list<Opportunity> createTestDataOfOpportunity() {
		list<Opportunity> lstOfOpportunity = new list<Opportunity>();
		Account objAccount = new Account();
		objAccount.Name = 'Test Account';
		insert objAccount;
        Account pAccount = new Account();
        pAccount.Name = 'Partner Account';
        insert pAccount;    

		for(integer i=0;i<10;i++){
			Opportunity objOpp = new Opportunity();
            objOpp.RecordTypeId = '01270000000LuOXAA0';
            objOpp.Partner_Origination__c = 'Lead Source';
			objOpp.Partner_Deal__c = 'YES';
			objOpp.Name = 'Test'+i;
            objOpp.Partner_Account__c = pAccount.Id;
			objOpp.AccountId = objAccount.Id;
			objOpp.CloseDate = Date.today();
			objOpp.StageName = '1 - Identification / Qualification';
			objOpp.ForecastCategoryName = 'Pipeline';
			objOpp.inContact__c = 'YES';
			objopp.ECHO__c = 'YES';
			lstOfOpportunity.add(objopp);
		}
		return lstOfOpportunity;
	}

	//method to check Buying Stage, Portfolioscope fields on Opportunity insert
	@isTest static void testOpportunityOnInsert() {
		list<Opportunity> lstOfOpportunity = OpportunityTriggerHandlerTest.createTestDataOfOpportunity();
		system.Test.startTest();
		insert lstOfOpportunity;
		system.Test.stopTest();
		Opportunity objOpp = [SELECT Id, Name, Buying_Stage__c, Portfolio_Scope__c
		FROM Opportunity
		WHERE Id =: lstOfOpportunity[0].Id];

		system.assertEquals('MQL Awareness', objOpp.Buying_Stage__c);
        System.assertNotEquals(null, objOpp.Portfolio_Scope__c);
        Set<String> scopes = new Set<String>();
        scopes.addAll(objOpp.Portfolio_Scope__c.split(';'));
        System.debug(LoggingLevel.WARN, scopes);
		system.assert(scopes.contains('Omnichannel Routing'), 'Portfilio Scope does not contain OmniChannel Routing, instead contains:'+objOpp.Portfolio_Scope__c);
		system.assert(scopes.contains('Workforce Optimization'), 'Portfilio Scope does not contain Workforce Optimization, instead contains:'+objOpp.Portfolio_Scope__c);
	}

	//method to check Buying Stage, Portfolioscope fields on Opportunity update
	@isTest static void testOpportunityOnUpdate() {
		list<Opportunity> lstOfOpportunity = OpportunityTriggerHandlerTest.createTestDataOfOpportunity();
		insert lstOfOpportunity;

		lstOfOpportunity[0].StageName = '2 - Determining Problem / Impact';
		lstOfOpportunity[0].Analytics__c = true;
		lstOfOpportunity[0].Salesforce_Agent__c = true;
		lstOfOpportunity[0].inContact_Ports__c = 10;
		lstOfOpportunity[0].Service_Package_MAT__c = 10;
		lstOfOpportunity[0].OSC__c = true;


		system.Test.startTest();
		update lstOfOpportunity[0];
		system.Test.stopTest();




		Opportunity objOpp = [SELECT Id, Name, Buying_Stage__c, Portfolio_Scope__c

		FROM Opportunity
		WHERE Id =: lstOfOpportunity[0].Id];

		system.assertEquals('STAGE 2 Exploration', objOpp.Buying_Stage__c);
        System.assertNotEquals(null, objOpp.Portfolio_Scope__c);
        Set<String> scopes = new Set<String>();
        scopes.addAll(objOpp.Portfolio_Scope__c.split(';'));
		system.assert(scopes.contains('Omnichannel Routing'), 'Portfilio Scope does not contain OmniChannelRouting, instead contains:'+objOpp.Portfolio_Scope__c);
		system.assert(scopes.contains('Workforce Optimization'), 'Portfilio Scope does not contain Workforce Optimization, instead contains:'+objOpp.Portfolio_Scope__c);
		system.assert(scopes.contains('Analytics'), 'Portfilio Scope does not contain Analytics, instead contains:'+objOpp.Portfolio_Scope__c);
		system.assert(scopes.contains('Open Cloud Platform'), 'Portfilio Scope does not contain Open Cloud Platform, instead contains:'+objOpp.Portfolio_Scope__c);
		system.assert(scopes.contains('Voice as a Service'), 'Portfilio Scope does not contain Voice as a Service, instead contains:'+objOpp.Portfolio_Scope__c);
		system.assert(scopes.contains('Services'), 'Portfilio Scope does not contain Services, instead contains:'+objOpp.Portfolio_Scope__c);
		//system.assert(scopes.contains('TBD'), 'Portfilio Scope does not contain TBD, instead contains:'+objOpp.Portfolio_Scope__c);


	}

	//method to check Buying Stage, Portfolioscope fields on Opportunity update with Stage Alignment
	@isTest static void testOpportunityOnUpdateStageAlignment() {
		// Implement test code
		list<Opportunity> lstOfOpportunity = OpportunityTriggerHandlerTest.createTestDataOfOpportunity();
		insert lstOfOpportunity;

		lstOfOpportunity[0].StageName = '3 - Aligning Benefits & Value';
		system.Test.startTest();
		update lstOfOpportunity[0];
		system.Test.stopTest();
		Opportunity objOpp = [SELECT Id, Name, Buying_Stage__c, Portfolio_Scope__c
		FROM Opportunity
		WHERE Id =: lstOfOpportunity[0].Id];

		system.assertEquals('STAGE 3 Alignment', objOpp.Buying_Stage__c);
        System.assertNotEquals(null, objOpp.Portfolio_Scope__c);
        Set<String> scopes = new Set<String>();
        scopes.addAll(objOpp.Portfolio_Scope__c.split(';'));
		system.assert(scopes.contains('Omnichannel Routing'), 'Portfilio Scope does not contain OmniChannelRouting, instead contains:'+objOpp.Portfolio_Scope__c);
		system.assert(scopes.contains('Workforce Optimization'), 'Portfilio Scope does not contain Workforce Optimization, instead contains:'+objOpp.Portfolio_Scope__c);


	}

	//method to check Buying Stage, Portfolioscope fields on Opportunity update with Stage Confirm value
	@isTest static void testOpportunityOnUpdateStageConfirmValue() {
		// Implement test code
		list<Opportunity> lstOfOpportunity = OpportunityTriggerHandlerTest.createTestDataOfOpportunity();
		insert lstOfOpportunity;

		lstOfOpportunity[0].StageName = '4 - Confirm Value & Agreement';
		system.Test.startTest();
		update lstOfOpportunity[0];
		system.Test.stopTest();
		Opportunity objOpp = [SELECT Id, Name, Buying_Stage__c, Portfolio_Scope__c
		FROM Opportunity
		WHERE Id =: lstOfOpportunity[0].Id];

		system.assertEquals('STAGE 4 Evaluation', objOpp.Buying_Stage__c);
        System.assertNotEquals(null, objOpp.Portfolio_Scope__c);
        Set<String> scopes = new Set<String>();
        scopes.addAll(objOpp.Portfolio_Scope__c.split(';'));
		system.assert(scopes.contains('Omnichannel Routing'), 'Portfilio Scope does not contain OmniChannelRouting, instead contains:'+objOpp.Portfolio_Scope__c);
		system.assert(scopes.contains('Workforce Optimization'), 'Portfilio Scope does not contain Workforce Optimization, instead contains:'+objOpp.Portfolio_Scope__c);

	}

	//method to check Buying Stage, Portfolioscope fields on Opportunity update with Stage Proposal
	@isTest static void testOpportunityOnUpdateStageProposal() {
		// Implement test code
		list<Opportunity> lstOfOpportunity = OpportunityTriggerHandlerTest.createTestDataOfOpportunity();
		insert lstOfOpportunity;


		lstOfOpportunity[0].StageName = '5 - Proposal / Negotiation';
		system.Test.startTest();
		update lstOfOpportunity[0];
		system.Test.stopTest();
		Opportunity objOpp = [SELECT Id, Name, Buying_Stage__c, Portfolio_Scope__c
		FROM Opportunity
		WHERE Id =: lstOfOpportunity[0].Id];

		system.assertEquals('STAGE 5 Commitment', objOpp.Buying_Stage__c);
        System.assertNotEquals(null, objOpp.Portfolio_Scope__c);
        Set<String> scopes = new Set<String>();
        scopes.addAll(objOpp.Portfolio_Scope__c.split(';'));
		system.assert(scopes.contains('Omnichannel Routing'), 'Portfilio Scope does not contain OmniChannelRouting, instead contains:'+objOpp.Portfolio_Scope__c);
		system.assert(scopes.contains('Workforce Optimization'), 'Portfilio Scope does not contain Workforce Optimization, instead contains:'+objOpp.Portfolio_Scope__c);

	}


	//method to check Buying Stage, Portfolioscope fields on Opportunity update with Closed – Won
	@isTest static void testOpportunityOnUpdateStageClosedWOn() {
		// Implement test code
		list<Opportunity> lstOfOpportunity = OpportunityTriggerHandlerTest.createTestDataOfOpportunity();
		insert lstOfOpportunity;
		lstOfOpportunity[0].StageName = 'Closed – Won';
		system.Test.startTest();
		update lstOfOpportunity[0];
		system.Test.stopTest();
		Opportunity objOpp = [SELECT Id, Name, Buying_Stage__c, Portfolio_Scope__c
		FROM Opportunity
		WHERE Id =: lstOfOpportunity[0].Id];

        System.assertNotEquals(null, objOpp.Buying_Stage__c);
        Set<String> scopes = new Set<String>();
        scopes.addAll(objOpp.Buying_Stage__c.split(';'));
		system.assert(scopes.contains('CUST Use'), 'Buying Stage does not contain CUST Use, instead contains:'+objOpp.Buying_Stage__c);
		system.assert(scopes.contains('CUST Renew and Expand'), 'Buying Stage does not contain CUST Renew and Expand, instead contains:'+objOpp.Buying_Stage__c);
		system.assert(scopes.contains('CUST Advocate'), 'Buying Stage does not contain CUST Advocate, instead contains:'+objOpp.Buying_Stage__c);
        System.assertNotEquals(null, objOpp.Portfolio_Scope__c);
        scopes = new Set<String>();
        scopes.addAll(objOpp.Portfolio_Scope__c.split(';'));
		system.assert(scopes.contains('Omnichannel Routing'), 'Portfilio Scope does not contain OmniChannelRouting, instead contains:'+objOpp.Portfolio_Scope__c);
		system.assert(scopes.contains('Workforce Optimization'), 'Portfilio Scope does not contain Workforce Optimization, instead contains:'+objOpp.Portfolio_Scope__c);
	}

	//method to check Buying Stage, Portfolioscope fields on Opportunity update with N/A
	@isTest static void testOpportunityOnUpdateStageNA() {
		// Implement test code
		list<Opportunity> lstOfOpportunity = OpportunityTriggerHandlerTest.createTestDataOfOpportunity();
		insert lstOfOpportunity;

		lstOfOpportunity[0].StageName = 'N/A';
		system.Test.startTest();
		update lstOfOpportunity[0];
		system.Test.stopTest();
		Opportunity objOpp = [SELECT Id, Name, Buying_Stage__c, Portfolio_Scope__c
		FROM Opportunity
		WHERE Id =: lstOfOpportunity[0].Id];

		system.assertEquals('UNI Thought Leadership', objOpp.Buying_Stage__c);
		System.assertNotEquals(null, objOpp.Portfolio_Scope__c);
        Set<String> scopes = new Set<String>();
        scopes.addAll(objOpp.Portfolio_Scope__c.split(';'));
		system.assert(scopes.contains('Omnichannel Routing'), 'Portfilio Scope does not contain OmniChannelRouting, instead contains:'+objOpp.Portfolio_Scope__c);
		system.assert(scopes.contains('Workforce Optimization'), 'Portfilio Scope does not contain Workforce Optimization, instead contains:'+objOpp.Portfolio_Scope__c);

	}

	@isTest static void testOpportunityNiceConnection(){
		list<Opportunity> lstOfOpportunity = OpportunityTriggerHandlerTest.createTestDataOfOpportunity();
		lstOfOpportunity[0].StageName = '0 - Nice Account';
		insert lstOfOpportunity;

		Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
		Account acc = [SELECT Id, RecordTypeId FROM Account WHERE Id = :lstOfOpportunity[0].AccountId];
		acc.RecordTypeId = accountRecordTypeMap.get('NICE NAMED NON-REC.').getRecordTypeId();
		update acc;

		lstOfOpportunity[0].StageName = '1 - Nice Account';
		system.Test.startTest();
		update lstOfOpportunity[0];
		system.Test.stopTest();

		Opportunity objOpp = [SELECT Id, Name, ConnectionSentId	FROM Opportunity WHERE Id =: lstOfOpportunity[0].Id];

		//connections don't actually send in test methods
		//system.assertNotEquals(objOpp.ConnectionSentId, null);
	}
}