/**
 * Created by arnab.karsarkar on 1/8/2018.
 */

public class CSOCaseOrderDetailController {

    //Case Comment History Model
    public class CSOCaseComment{
        public string CreatedDate {get; set;}
        public string CreatedByName {get; set;}
        public string CommentBody {get; set;}
    }
	// current asset record
	public Case CurrentCase{
		get {
			return helper != null
					? helper.currentCase : null;
		}set{}
	}

	public list<CSOCaseComment> comments{get;set;}
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
		comments = new List<CSOCaseComment>();
		comments = helper.getCaseComments(currentId);
//		caseHistory = new List<CSOCaseHistoryModel>();
//		caseHistory = helper.getCaseHistory(currentId);
//		caseAssignedTo = helper.caseAssignedTo;

	}


}