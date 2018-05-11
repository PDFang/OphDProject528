@isTest
public class CaseEmailTriggerTest {

	static testmethod void caseUpdateTest()
	{
		Map<String,Schema.RecordTypeInfo> recordTypeMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
		Id incidentRecordTypeId = recordTypeMapByName.get('Incident - Premise').getRecordTypeId();
		
		Account acct = inContactBaseClass.CreateAccount('Test Account');
		acct.CadebillAccountNo__c = 9999999;
		acct.inContact_Cluster__c = 'C6';
		insert acct;
		 
		database.DMLOptions dmo = new database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
        
        Case incident = new Case(
						  Status = 'New',
						  recordTypeId = incidentRecordTypeId,
						  subject = 'test',
						  Description = 'test description',
						  AccountId = acct.Id,
						  Severity__c = 'S4',
						  Priority = 'P4'
						);
		
        incident.setOptions(dmo);
        
        insert incident;
		
        
        	
		incident.Status = 'Acknowledged';
		update incident;

		EmailMessage[] newEmail = new EmailMessage[0];
		newEmail.add(new EmailMessage(FromAddress = 'someone@test.com', 
									  Incoming = True, ToAddress= 'someone@salesforce.com', 
									  Subject = 'Test email', 
									  TextBody = 'Test', 
									  ParentId = incident.Id)); 
	

		
		Test.startTest();
		insert newEmail;
		string statusIncident = [select status from Case where id =: incident.id limit 1].Status;
		System.assertEquals('Customer Updated', statusIncident);
		Test.stopTest();

	}
    
    static testmethod void caseUpdateTest_NoUpdateWhenInContactFromAddress()
    {
        Map<String,Schema.RecordTypeInfo> recordTypeMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
		Id incidentRecordTypeId = recordTypeMapByName.get('Incident - Premise').getRecordTypeId();
		
		Account acct = inContactBaseClass.CreateAccount('Test Account');
		acct.CadebillAccountNo__c = 9999999;
		acct.inContact_Cluster__c = 'C6';
		insert acct;
		
        database.DMLOptions dmo = new database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
        
		Case incident = new Case(
						  Status = 'New',
						  recordTypeId = incidentRecordTypeId,
						  subject = 'test',
						  Description = 'test description',
						  AccountId = acct.Id,
						  Severity__c = 'S4',
						  Priority = 'P4'
						);
        
        incident.setOptions(dmo);      
		insert incident;

		incident.Status = 'Acknowledged';
		update incident;

		EmailMessage[] newEmail = new EmailMessage[0];
		newEmail.add(new EmailMessage(FromAddress = 'someone@incontact.com', 
									  Incoming = True, ToAddress= 'someone@salesforce.com', 
									  Subject = 'Test email', 
									  TextBody = 'Test', 
									  ParentId = incident.Id)); 
	

		
		Test.startTest();
		insert newEmail;
		string statusIncident = [select status from Case where id =: incident.id limit 1].Status;
		System.assertEquals('Acknowledged', statusIncident);
		Test.stopTest();
    }

	static testmethod void HelpDeskOutgoingTest()
	{
		Map<String,Schema.RecordTypeInfo> recordTypeMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
		Id helpDeskRecordTypeId = recordTypeMapByName.get('Help Desk').getRecordTypeId();

		Account acct = inContactBaseClass.CreateAccount('Test Account');
		acct.CadebillAccountNo__c = 100001;
		acct.inContact_Cluster__c = 'C6';
		insert acct;

		database.DMLOptions dmo = new database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;

		Case incident = new Case(
				Status = 'New',
				recordTypeId = helpDeskRecordTypeId,
				subject = 'test',
				Description = 'test description',
				AccountId = acct.Id,
				Severity__c = 'S4',
				Priority = 'P4'
		);

		incident.setOptions(dmo);
		insert incident;

		incident.Status = 'Acknowledged';
		update incident;

		EmailMessage[] newEmail = new EmailMessage[0];
		newEmail.add(new EmailMessage(FromAddress = 'someone@incontact.com',
				Incoming = False, ToAddress= 'someone@salesforce.com',
				Subject = 'Test email',
				TextBody = 'Test',
				ParentId = incident.Id));



		Test.startTest();
		insert newEmail;
		string statusIncident = [select status from Case where id =: incident.id limit 1].Status;
		System.assertEquals('Waiting for Reply', statusIncident);
		Test.stopTest();
	}

	static testmethod void HelpDeskIncomingTest()
	{
		Map<String,Schema.RecordTypeInfo> recordTypeMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
		Id helpDeskRecordTypeId = recordTypeMapByName.get('Help Desk').getRecordTypeId();

		Account acct = inContactBaseClass.CreateAccount('Test Account');
		acct.CadebillAccountNo__c = 100001;
		acct.inContact_Cluster__c = 'C6';
		insert acct;

		database.DMLOptions dmo = new database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;

		Case incident = new Case(
				Status = 'New',
				recordTypeId = helpDeskRecordTypeId,
				subject = 'test',
				Description = 'test description',
				AccountId = acct.Id,
				Severity__c = 'S4',
				Priority = 'P4'
		);

		incident.setOptions(dmo);
		insert incident;

		incident.Status = 'Acknowledged';
		update incident;

		EmailMessage[] newEmail = new EmailMessage[0];
		newEmail.add(new EmailMessage(FromAddress = 'someone@incontact.com',
				Incoming = True, ToAddress= 'someone@salesforce.com',
				Subject = 'Test email',
				TextBody = 'Test',
				ParentId = incident.Id));



		Test.startTest();
		insert newEmail;
		string statusIncident = [select status from Case where id =: incident.id limit 1].Status;
		System.assertEquals('Email Received', statusIncident);
		Test.stopTest();
	}

	static testmethod void CallPartnerProxyTest()
	{
		Map<String,Schema.RecordTypeInfo> recordTypeMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
		Id incidentRecordTypeId = recordTypeMapByName.get('Incident').getRecordTypeId();

		Account acct = inContactBaseClass.CreateAccount('Test Account');
		acct.CadebillAccountNo__c = 9999999;
		acct.Billing_Group__c = PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON;
		insert acct;

		database.DMLOptions dmo = new database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;

		Case incident = new Case(
				Status = 'New',
				recordTypeId = incidentRecordTypeId,
				subject = 'test',
				Description = 'test description',
				AccountId = acct.Id,
				Severity__c = 'S4',
				Priority = 'P4',
				X3rdPartyVendorTicket__c = '20180511123456'
		);

		incident.setOptions(dmo);

		insert incident;

		EmailMessage[] newEmail = new EmailMessage[0];
		newEmail.add(new EmailMessage(FromAddress = 'someone@test.com',
				Incoming = True, ToAddress= 'someone@salesforce.com',
				Subject = 'Test email',
				TextBody = 'Test',
				ParentId = incident.Id));



		Test.startTest();
		insert newEmail;
		Test.stopTest();
		List<CaseComment> caseComments = [SELECT Id, CommentBody, IsPublished FROM CaseComment WHERE ParentId = :incident.Id];
		system.assertEquals(1, caseComments.size(), 'Case Comment did not get created.');
	}

	static testmethod void AutoReplyTest()
	{
		Map<String,Schema.RecordTypeInfo> recordTypeMapByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
		Id incidentRecordTypeId = recordTypeMapByName.get('Incident - Premise').getRecordTypeId();

		Account acct = inContactBaseClass.CreateAccount('Test Account');
		acct.CadebillAccountNo__c = 9999999;
		acct.inContact_Cluster__c = 'C6';
		insert acct;

		database.DMLOptions dmo = new database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;

		Case incident = new Case(
				Status = 'New',
				recordTypeId = incidentRecordTypeId,
				subject = 'test',
				Description = 'test description',
				AccountId = acct.Id,
				Severity__c = 'S4',
				Priority = 'P4'
		);

		incident.setOptions(dmo);

		insert incident;


		EmailMessage[] newEmail = new EmailMessage[0];
		newEmail.add(new EmailMessage(FromAddress = 'someone@test.com',
				Incoming = True, ToAddress= 'someone@salesforce.com',
				Subject = 'Test email OUT OF OFFICE test email',
				TextBody = 'Test',
				ParentId = incident.Id));



		Test.startTest();
		insert newEmail;
		Test.stopTest();

		CaseComment[] caseComments = [SELECT Id FROM CaseComment];
		system.assert(caseComments.isEmpty(), 'Comments were created on out of office reploy.');
	}
 }