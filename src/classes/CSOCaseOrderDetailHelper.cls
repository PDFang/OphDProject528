/**
 * Created by arnab.karsarkar on 1/8/2018.
 */

public class CSOCaseOrderDetailHelper {

	public Case currentCase;

	static Set<String> caseFields = new Set<String>{
			'RecordType.Name'
	};



	// constructor
	public CSOCaseOrderDetailHelper(String idParam){

		String sObjType = getSObjectType(idParam);
		if(sObjType == 'Case'){
			currentCase = getCase(idParam);
			system.debug('getCase(): currentCase - ' + currentCase);

			if(currentCase == null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No asset record found.'));
				return;
			}

		}
	}

	public String getSObjectType(String IdParam){
		if(idParam.left(3) == Schema.SObjectType.Case.getKeyPrefix()){
			return 'Case';
		}

		else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'URL: Invalid ID Parameter.'));
		}
		return null;
	}

	public Case getCase(string caseId){
		List<Schema.FieldSetMember> fsMembers = Schema.SobjectType.Case.fieldSets.CSO_Order_Resolution.getFields();
		for(Schema.FieldSetMember member : fsMembers){
			caseFields.add(member.getFieldPath());
		}
		List<String> fieldList = new List<String>(caseFields);
		String columns = String.join(fieldList, ',');
		system.debug('getCase(): columns - ' + columns);
		String soql = 'Select ' + columns + ' From Case where Id = \'' + caseId + '\'';
		system.debug('getCase(): soql - ' + soql);

		List<Case> cases = Database.query(soql);
		if(cases.isEmpty()){
			return null;
		}

		return cases[0];

	}

	public list<CaseComment> getCaseComments(string caseId){
		list<CaseComment> retlist = new list<CaseComment>();
		retlist = [SELECT CommentBody,CreatedDate,CreatedBy.Name,Id,IsDeleted,IsPublished,ParentId FROM CaseComment where parentId =:caseId  order by CreatedDate desc];
		return retlist;
	}

}