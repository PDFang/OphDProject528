@isTest
public class CaseEmailTriggerTest {

	public static testmethod void caseUpdateTest()
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
    
    public static testmethod void caseUpdateTest_NoUpdateWhenInContactFromAddress()
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
 }