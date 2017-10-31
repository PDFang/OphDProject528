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
			 System.debug('req ==>> ' + req);
			 System.debug('paramMap ==>> ' + req.params);
			 Blob body = req.requestBody;
			 System.debug('body ==>> ' + body);
			 String bodyString = body.toString();
			 System.debug('body string ==>> ' + bodyString);
			 Map<String,string> paramMap = req.params;
			Lead newLead = new Lead();
			//iterate through the list and map fields from the request;
			JSONParser parser = JSON.createParser(bodyString);
			String tempString;

			while (parser.nextToken() != null) {
				if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
					if(parser.getText() == 'company'){
						tempString = 'company';
					}
					parser.nextToken();
					System.debug('parser.getText() ==>> ' + parser.getText());

				}
			}

		}catch (Exception ex){
			System.debug('exception => ' + ex.getMessage());
		}



		//System.debug('paramMap ==>> ' + paramMap);

	}
	global WebHookLeadManagement(){
		mappings = [Select Lead_Fields__c, WebHooks_Fields__c, DeveloperName from Lead_Mapping__mdt];
	}

	private static Map<String, String> getLeadMapping(){
		Map<String, String> leadFieldMap = new Map<String, String>();
		Map<String, Schema.sObjectField> leadFields = Schema.sObjectType.Lead.Fields.getMap();

		for (Lead_Mapping__mdt mapping : mappings) {
			leadFieldMap.put(mapping.DeveloperName, mapping.Lead_Fields__c);
		}

		return leadFieldMap;
	}


}