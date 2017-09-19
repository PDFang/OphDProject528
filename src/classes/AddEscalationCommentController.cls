/**
 * Created by arnab.karsarkar on 9/19/2017.
 */

public without sharing class AddEscalationCommentController {

	public AddEscalationCommentController(){}
	public Issues__c escalation;
	public string escalationCommnet{get; set;}
	public Date commnetDate{get; set;}

	public AddEscalationCommentController(ApexPages.StandardController controller){
		this.escalation = (Issues__c)controller.getRecord();

	}

	public PageReference SaveComment(){
		Escalation_Comment__c comment = new Escalation_Comment__c(
							Comment__c = escalationCommnet,
							Date__c = commnetDate,
							Escalation_ID__c = escalation.Id
							);

		try{
			insert comment;
			PageReference escalationPage = new PageReference('/' + escalation.Id);
			escalationPage.setRedirect(true);
			return escalationPage;
		}Catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
		return null;

	}
}