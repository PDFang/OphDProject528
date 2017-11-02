/**
 * Created by arnab.karsarkar on 10/31/2017.
 */

@RestResource(urlmapping='/SFDCLead/*')
global class WebHookLeadManagement {

	private static List<Lead_Mapping__mdt> mappings;

	@HttpPost
	global static void CreateLead(){
	 	 try{
			RestRequest req = RestContext.request;
             System.debug('req' + req);
			 Blob body = req.requestBody;
             System.debug('body' + body);
			 String bodyString = body.toString();
             System.debug('bodyString' + bodyString);
			 Map<String,string> paramMap = req.params;
			 Lead newLead = new Lead();

		     // Get the mapping
		     map<string, string> leadMap = getLeadMapping();

			//iterate through the list and map fields from the request;
			JSONParser parser = JSON.createParser(bodyString);
			String tempString = '',
				   streetAddress = '';

			while (parser.nextToken() != null) {
				if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
					string fieldName = parser.getText();
					string keyValue = fieldName;
					if(fieldName == 'company'){
						tempString = 'company';
					}
					if(fieldName == 'contact') {
						tempString = 'contact';
					}
					if(fieldName == 'application') {
						tempString = 'application';
					}
					parser.nextToken();
					string fieldValue  = parser.getText();
					keyValue = tempString + fieldName;
					if(keyValue == 'companystreet1'){
						streetAddress =  fieldValue;

					}
					else if(keyValue == 'companystreet2' && streetAddress != ''){
						streetAddress  = streetAddress + ', ' + fieldValue;
					}
					keyValue = keyValue.trim();
					//System.debug('keyValue ==>' + keyValue);
					if(leadMap.containsKey(keyValue))
						newLead.put(leadMap.get(keyValue), fieldValue);
					if(keyValue == 'companystreet2')
						newLead.put(leadMap.get(keyValue), streetAddress);
				}
			}

		     Map<String, Schema.RecordTypeInfo> recordTypeNameMap = Schema.SObjectType.Lead.getRecordTypeInfosByName();
		     newLead.RecordTypeId = recordTypeNameMap.get('InCloud Partner Engagement').recordTypeId;


		     System.debug('new Lead' + newLead);
		    insert newLead;

		}catch (Exception ex){
		     sendErrorEmail(ex);
		}

	}


	private static Map<String, String> getLeadMapping(){
		mappings = [Select Lead_Fields__c, WebHooks_Fields__c, DeveloperName from Lead_Mapping__mdt];
		Map<String, String> leadFieldMap = new Map<String, String>();
		Map<String, Schema.sObjectField> leadFields = Schema.sObjectType.Lead.Fields.getMap();

		for (Lead_Mapping__mdt mapping : mappings) {
			leadFieldMap.put(mapping.DeveloperName, mapping.Lead_Fields__c);
		}

		return leadFieldMap;
	}

	private static void sendErrorEmail(Exception ex){

		string subject = 'Webhook Lead Creation Errors' ;
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[]{};
		toAddresses = Label.DEVErrorEmailRecipient.split(',');
		email.setSenderDisplayName('Salesforce Developers');
		email.setSubject(subject);
		email.setToAddresses(toAddresses);
		string body = 'Error Occured - ' + ex.getStackTraceString();
		email.setHtmlBody(body);

		//send email message
		try{
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
		}catch(system.EmailException exc){
			system.debug(exc);
		}

	}


}