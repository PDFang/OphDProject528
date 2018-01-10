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

	@RemoteAction
	public static string getCurrentOrderDetails(string caseId){
		Case currentCase = [select CustomerOrder__c, SubProductorService__c, Origin from Case where Id = : caseId and Origin like '%CSO%' Limit 1];

		if(currentCase == null)
			return null;

		string orderId = currentCase.CustomerOrder__c;
		decimal instrumentId = getInstrumentId(currentCase.SubProductorService__c);

		List<OrderLineGeneralItems__c> lineGeneralItems = getAllLineItems(orderId, instrumentId);

		if(lineGeneralItems == null)
			return null;

		list<CSOOrderResolutionColumnMapping__c> mappings = getMappings(instrumentId);
		list<string> columns = getColumnMappings(mappings);
		list<string> buttons = getButtons(mappings);

		if(columns.size() > 0){
			string jsonString = generateJSONString(columns, lineGeneralItems, buttons);
			System.debug('JSONstring ==>' + jsonString);
			return jsonString;
		}

		return null;
	}

	private static decimal getInstrumentId(string product){
		decimal instrumentId = 0;

		if(product == null)
			return 0;

		if(product.contains('DID'))
			instrumentId = 12554;
		else if (product.contains('IP Voice'))
			instrumentId = 12709;

		return instrumentId;

	}


	private static list<OrderLineGeneralItems__c> getAllLineItems(string orderId, decimal instrumentId){
		return [select Id, Name, ItemStatus__c, InstrumentType__c,
				(select SpecificItem__c, ItemValue__c,OrderLineGeneralItem__c from Order_Line_Specific_Items__r)
				from OrderLineGeneralItems__c where CustomerOrder__c = : orderId and InstrumentType__c = :instrumentId];
	}

	private static list<CSOOrderResolutionColumnMapping__c> getMappings(decimal instrumentId){
			return [Select DisplayColumns__c, OrderProduct__c,Display_Buttons__c from CSOOrderResolutionColumnMapping__c where IntrumentNumber__c =: instrumentId Limit 1];
	}


	private static list<String> getColumnMappings(list<CSOOrderResolutionColumnMapping__c> mappings){

		list<string> columns = new list<string>();
		columns.addAll(lineItemColumns);
		if(mappings == null)
			return columns;

		for(string st : mappings[0].DisplayColumns__c.split(';')){
			columns.add( st.replaceAll( '\\s+', ''));

		}
		stColumns.addAll(columns);
		return columns;
	}

	private static list<string> getButtons(list<CSOOrderResolutionColumnMapping__c> mappings){
		if(mappings == null)
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

		gen.writeObjectField('columns', columns);
		gen.writeObjectField('buttons', buttons);

		gen.writeEndObject();

		return gen.getAsString();
	}


}