/**
 * Created by arnab.karsarkar on 1/8/2018.
 */

public class CSOCaseOrderDetailController {

	// current asset record
	public Case CurrentCase{
		get {
			return helper != null
					? helper.currentCase : null;
		}set{}
	}

	public list<CaseComment> comments{get;set;}
//	public list<CSOCaseHistoryModel> caseHistory{get;set;}
//	public list<CSOCaseHistoryModel> caseAssignedTo{get;set;}


	// query string parameter
	public String currentId{get;set;}
	private CSOCaseOrderDetailHelper helper;

	public CSOCaseOrderDetailController(){
		currentId = ApexPages.currentPage().getParameters().get('id');
		system.debug('currentId - ' + currentId);

		if(String.isBlank(currentId)){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid URL: Missing ID Parameter.'));
			return;
		}

		helper = new CSOCaseOrderDetailHelper(currentId);
		comments = new List<CaseComment>();
		comments = helper.getCaseComments(currentId);
//		caseHistory = new List<CSOCaseHistoryModel>();
//		caseHistory = helper.getCaseHistory(currentId);
//		caseAssignedTo = helper.caseAssignedTo;

	}


}