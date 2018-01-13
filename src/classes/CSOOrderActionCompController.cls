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
		'Item Status',
		'Last Comment',
		'RelatedLineItem__c',
		'Parent Line Item'

	};

	static set<string> lineItemFields = new set<string>{
			'Id',
			'Name',
			'ItemStatus__c',
			'Last_Comment__c',
			'RelatedLineItem__c',
			'RelatedLineItem__r.Name'

	};

	static set<string> columnTitles = new set<string>();
	static map<string,string> columnNameTitleMap = new map<string, string>();
	static Case currentCase;

	public string ItemStatus
	{
		get
		{
			String[] statusList = new String[]{};
			list<case> cases = getCurrentCase(currentCaseId);
			if(cases.isEmpty())
				return 'NONE';
			list<CSOOrderResolutionColumnMapping__c> mappings = getMappings(cases[0].CSO_Resolution_Type__c);
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
				return 'Error occured while loading the order line items grid. Case information is incomplete.';

			currentCase = cases[0];

			list<CSOOrderResolutionColumnMapping__c> mappings = getMappings(currentCase.CSO_Resolution_Type__c);

			List<OrderLineGeneralItems__c> lineGeneralItems = getAllLineItems(currentCase, mappings);
			if(lineGeneralItems == null || lineGeneralItems.isEmpty())
				return 'Error occured while loading the order line items grid. No Line Items were found to show';

			list<string> buttons = getButtons(mappings);

			if(lineGeneralItems.size() > 0){
				string jsonString = generateJSONString(lineGeneralItems, buttons);
				System.debug('JSONstring ==>' + jsonString);
				return jsonString;
			}

			return null;
		}Catch(Exception ex){
			return 'Error occured while loading the order line items grid. - ' + ex.getMessage();
		}

	}

	private static list<Case> getCurrentCase(string caseId){
		return [select CustomerOrder__c, SubProductorService__c,CSO_Resolution_Type__c, Origin from Case where Id = : caseId and CSO_Resolution_Type__c != null Limit 1];

	}

	private static list<OrderLineGeneralItems__c> getAllLineItems(case currentCase, list<CSOOrderResolutionColumnMapping__c> mappings){
		string orderId = currentCase.CustomerOrder__c;
		decimal instrumentId = mappings == null ? 0 : mappings[0].Instrument_Id__c;

		columnTitles.addAll(mappings[0].DisplayColumns__c.split(';'));
		columnTitles.addAll(lineItemColumns);
		set<string> columnTitleLocal = new set<string>();
		
		Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Map <String, Schema.SObjectField> fieldMap = schemaMap.get('OrderLineGeneralItems__c').getDescribe().fields.getMap();
		for(Schema.SObjectField sfield : fieldMap.Values())
		{
			schema.describefieldresult dfield = sfield.getDescribe();
			if(columnTitles.contains(dfield.getLabel())){
				lineItemFields.add(dfield.getName());
				columnNameTitleMap.put(dfield.getName(), dfield.getLabel());
				columnTitleLocal.add(dfield.getLabel());

			}

		}

		for(string title : columnTitles ){
			if(!columnTitleLocal.contains(title)){
				string key = title.replaceAll( '\\s+', '');
				columnNameTitleMap.put(key, title);
			}
		}
		columnNameTitleMap.put('ParentLineItem', 'Parent Line Item Name');

		system.debug('columnNameTitleMap ==> ' + columnNameTitleMap);

		List<String> fieldList = new List<String>(lineItemFields);
		
		String columns = String.join(fieldList, ',');

		system.debug('getAllLineItems(): columns - ' + columns);

		String soql = 'Select ' + columns + ', (select Id, SpecificItem__c, ItemValue__c from Order_Line_Specific_Items__r) From OrderLineGeneralItems__c where  CustomerOrder__c = : orderId '
					 + ' and (InstrumentType__c = :instrumentId OR RelatedLineItem__r.InstrumentType__c = :instrumentId) '
				     + ' and ItemStatus__c not in(\'Canceled\', \'Completed\') order by CreatedDate desc';

		system.debug('getAllLineItems(): soql - ' + soql);

		List<OrderLineGeneralItems__c> lineItems = Database.query(soql);

		return lineItems;
	}

	private static list<CSOOrderResolutionColumnMapping__c> getMappings(string CSOCaseType){
			return [Select DisplayColumns__c, CSO_Resolution_Type__c, Line_Item_Status__c , Display_Buttons__c, Instrument_Id__c from CSOOrderResolutionColumnMapping__c where  CSO_Resolution_Type__c = :CSOCaseType Limit 1];
	}


	
	private static list<string> getButtons(list<CSOOrderResolutionColumnMapping__c> mappings){
		if(mappings == null || mappings.isEmpty())
			return new list<string>();

		list<string> buttons = mappings[0].Display_Buttons__c.split(';');
		return buttons;
	}



	private static string generateJSONString(list<OrderLineGeneralItems__c> lineItems, list<string> buttons){

		System.debug('generate JSON => lineItems : ' + lineItems);
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();

			gen.writeFieldName('data');
			gen.writeStartArray();
				for(OrderLineGeneralItems__c li : lineItems){
					gen.writeStartObject();
					set<string> stCols = new set<string>();
					for(string columnName : lineItemFields){
						if(!columnName.contains('RelatedLineItem__r.Name')){
							string value = String.valueOf(li.get(columnName));
							gen.writeStringField(columnName, value == null ? '' : value);
							stCols.add(columnName);
						}else if(columnName.contains('RelatedLineItem__r.Name')){
							gen.writeStringField('ParentLineItem', li.RelatedLineItem__r.Name == null ? '' : li.RelatedLineItem__r.Name);
							stCols.add('ParentLineItem');
						}
					}
					for(OrderLineSpecificItem__c si : li.Order_Line_Specific_Items__r){
						string col = si.SpecificItem__c.replaceAll( '\\s+', '');
						System.debug('JSON ++> ' + col);
							if(columnNameTitleMap.containsKey(col)){
								gen.writeStringField(col, si.ItemValue__c);
								stCols.add(col);
							}

					}
					for(string col : columnNameTitleMap.keySet()) {
						if(!stCols.contains(col) && !lineItemColumns.contains(col)){
							gen.writeStringField(col, '');
						}
					}
					gen.writeEndObject();
				}
			gen.writeEndArray();

		list<string> colName= new list<string>();
		for(string col : columnNameTitleMap.keySet()){
			string formatColName = col + '~' + columnNameTitleMap.get(col);
			colName.add(formatColName);
		}

		gen.writeObjectField('columns', colName);
		gen.writeObjectField('buttons', buttons);

		gen.writeEndObject();

		return gen.getAsString();
	}

	@RemoteAction
	public static string saveComment(string comment,boolean isPublic, string lineItemId, string caseId){
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
					Public__c = isPublic
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
				list<CSOOrderResolutionColumnMapping__c> mappings = getMappings(currentCase.CSO_Resolution_Type__c);
				List<OrderLineGeneralItems__c> lineGeneralItems = getAllLineItems(currentCase, mappings);
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