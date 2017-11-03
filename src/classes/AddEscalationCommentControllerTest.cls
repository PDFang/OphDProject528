/**
 * Created by arnab.karsarkar on 11/2/2017.
 */

@isTest
public class AddEscalationCommentControllerTest {

	static testMethod void testAddComment(){
		Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
		Account acct = new Account(
				Name = 'AddEscalationComment Account',
				RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId()
		);

		insert acct;

		Issues__c newIssue = new Issues__c(
				Account__c = acct.Id,
				Status__c = 'Open',
				Description_of_Resolution_High_Level__c = 'Test Issue',
				Sequence_of_Events_Leading_to_Escalation__c = 'Test'

		);
		insert newIssue;

		ApexPages.StandardController controller = new ApexPages.StandardController(newIssue);
		AddEscalationCommentController commentController = new AddEscalationCommentController(controller);
		Test.startTest();
		commentController.SaveComment();
		commentController.escalationCommnet = 'Test Comment';
		commentController.commnetDate = System.today();
		commentController.SaveComment();
		commentController.cancel();
		Test.stopTest();
		Escalation_Comment__c comment = [Select Comment__c from Escalation_Comment__c where Escalation_ID__c = :newIssue.Id];
		system.assertEquals('Test Comment', comment.Comment__c, 'Values Matched');

		AddEscalationCommentController commentController1 = new AddEscalationCommentController();


	}


}