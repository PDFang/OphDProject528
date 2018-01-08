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

	// query string parameter
	public String currentId{get;set;}
	private static CSOCaseOrderDetailHelper helper;

	public CSOCaseOrderDetailController(){
		currentId = ApexPages.currentPage().getParameters().get('id');
		system.debug('currentId - ' + currentId);

		if(String.isBlank(currentId)){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid URL: Missing ID Parameter.'));
			return;
		}
	}

	@AuraEnabled
	public static list<string> GetFieldList(){
		return CSOCaseOrderDetailHelper.getFieldList();
	}

	@AuraEnabled
	public static Case GetCaseRecord(string caseId){
		helper = new CSOCaseOrderDetailHelper(caseId);
		return helper.currentCase;
	}


}