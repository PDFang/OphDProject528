/**
 * Created by arnab.karsarkar on 1/9/2018.
 */

public with sharing class CSOOrderActionCompController {

	public String currentCaseId{get;set;}


	public CSOOrderActionCompController(){
		if (currentCaseId == null) {
			currentCaseId = System.currentPageReference().getParameters().get('id');
		}



	}

	final static set<string> lineItemColumns = new set<string>{
		'Id',
		'Name',
		'Status'

	};

	static set<string> stColumns = new set<string>();
	static Case currentCase;

	public string ItemStatus
	{
		get
		{
			String[] statusList = new String[]{};
			list<case> cases = getCurrentCase(currentCaseId);
			if(cases.isEmpty())
				return 'NONE';
			list<CSOOrderResolutionColumnMapping__c> mappings = getMappings(cases[0].CSO_Case_Type__c);
			if(!mappings.isEmpty()){
				statusList = mappings[0].Line_Item_Status__c.split(';');
			}
			statusList.sort();

			return JSON.Serialize(statusList);
		}
	}



	@RemoteAction
	public static string getCurrentOrderDetails(string caseId){
		try{
			list<case> cases = getCurrentCase(caseId);
			if(cases == null || cases.isEmpty())
				return 'Error occured while loading the order line items grid. Invalid Case type. ';

			currentCase = cases[0];

			List<OrderLineGeneralItems__c> lineGeneralItems = getAllLineItems(currentCase);
			if(lineGeneralItems == null)
				return 'Error occured while loading the order line items grid. No Line Items were found to show';

			list<CSOOrderResolutionColumnMapping__c> mappings = getMappings(currentCase.CSO_Case_Type__c);
			list<string> columns = getColumnMappings(mappings);
			list<string> buttons = getButtons(mappings);

			if(columns.size() > 0){
				string jsonString = generateJSONString(columns, lineGeneralItems, buttons);
				System.debug('JSONstring ==>' + jsonString);
				return jsonString;
			}

			return null;
		}Catch(Exception ex){
			return 'Error occured while loading the order line items grid. - ' + ex.getMessage();
		}

	}

	private static decimal getInstrumentId(string caseType){
		decimal instrumentId = 0;

		if(caseType == null)
			return 0;

		if(caseType.contains('DID'))
			instrumentId = 12554;
		else if (caseType.contains('IP Voice'))
			instrumentId = 12709;

		return instrumentId;

	}

	private static list<Case> getCurrentCase(string caseId){
		return [select CustomerOrder__c, SubProductorService__c,CSO_Case_Type__c, Origin from Case where Id = : caseId and CSO_Case_Type__c != null Limit 1];

	}

	private static list<OrderLineGeneralItems__c> getAllLineItems(case currentCase){
		string orderId = currentCase.CustomerOrder__c;
		decimal instrumentId = getInstrumentId(currentCase.CSO_Case_Type__c);

		return [select Id, Name, ItemStatus__c, InstrumentType__c,Last_Comment__c,
				(select SpecificItem__c, ItemValue__c,OrderLineGeneralItem__c from Order_Line_Specific_Items__r)
				from OrderLineGeneralItems__c where CustomerOrder__c = : orderId and InstrumentType__c = :instrumentId];
	}

	private static list<CSOOrderResolutionColumnMapping__c> getMappings(string CSOCaseType){
			return [Select DisplayColumns__c, CSO_Case_Type__c,Line_Item_Status__c , Display_Buttons__c from CSOOrderResolutionColumnMapping__c where  CSO_Case_Type__c = :CSOCaseType Limit 1];
	}


	private static list<String> getColumnMappings(list<CSOOrderResolutionColumnMapping__c> mappings){

		list<string> columns = new list<string>();
		columns.addAll(lineItemColumns);
		if(mappings == null || mappings.isEmpty())
			return columns;

		for(string st : mappings[0].DisplayColumns__c.split(';')){
			columns.add( st.replaceAll( '\\s+', ''));

		}
		stColumns.addAll(columns);
		return columns;
	}

	private static list<string> getButtons(list<CSOOrderResolutionColumnMapping__c> mappings){
		if(mappings == null || mappings.isEmpty())
			return new list<string>();

		list<string> buttons = mappings[0].Display_Buttons__c.split(';');
		return buttons;
	}



	private static string generateJSONString(list<string> columns, list<OrderLineGeneralItems__c> lineItems, list<string> buttons){

		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();

			gen.writeFieldName('data');
			gen.writeStartArray();
				for(OrderLineGeneralItems__c li : lineItems){
					gen.writeStartObject();
					gen.writeStringField('Id', li.Id);
					gen.writeStringField('Name', li.Name);
					gen.writeStringField('Status', li.ItemStatus__c);
					gen.writeStringField('LastComment', li.Last_Comment__c == null ? '' : li.Last_Comment__c);
					set<string> stCols = new set<string>();
					for(OrderLineSpecificItem__c si : li.Order_Line_Specific_Items__r){
						string col = si.SpecificItem__c.replaceAll( '\\s+', '');
							if(stColumns.contains(col)){
								gen.writeStringField(col, si.ItemValue__c);
								stCols.add(col);
							}

					}
					for(string col : columns) {
						if(!stCols.contains(col) && !lineItemColumns.contains(col)){
							gen.writeStringField(col, '');
						}
					}
					gen.writeEndObject();
				}
			gen.writeEndArray();

		columns.add('LastComment');
		gen.writeObjectField('columns', columns);
		gen.writeObjectField('buttons', buttons);

		gen.writeEndObject();

		return gen.getAsString();
	}

	@RemoteAction
	public static string saveComment(string comment, string lineItemId, string caseId){
		try{
			if(comment == '' || comment == null)
				return 'Empty comments are not allowed to save.';
			list<case> cases = getCurrentCase(caseId);
			Id customerOrderId = cases[0].CustomerOrder__c;
			LineItemComment__c lineItemComment = new LineItemComment__c(
					Comment__c = comment,
					OrderLineGeneralItem__c = lineItemId,
					CustomerOrder__c = customerOrderId,
					Case__c = caseId,
					Public__c = true
			);

			insert lineItemComment;
			return 'Success';
		}catch (Exception ex){
			return 'Error while saving comment. Technical error message -  ' + ex.getMessage();
		}
	}

	@RemoteAction
	public static string updateStatus(string status, string lineItemId, string caseId, boolean updateAll){
		try{
			if(status == '' || status == null)
				return 'Invalid Staus.';
			if(updateAll){
				list<case> cases = getCurrentCase(caseId);
				currentCase = cases[0];
				List<OrderLineGeneralItems__c> lineGeneralItems = getAllLineItems(currentCase);
				for(OrderLineGeneralItems__c li : lineGeneralItems){
					li.ItemStatus__c = status;
				}
				update lineGeneralItems;
			}else{
				OrderLineGeneralItems__c lineItem = new OrderLineGeneralItems__c(
						Id = lineItemId,
						ItemStatus__c = status
				);

				update lineItem;
			}
			return 'Success';
		}catch (Exception ex){
			return 'Error while updating Status change. Technical error message -  ' + ex.getMessage();
		}
	}
}