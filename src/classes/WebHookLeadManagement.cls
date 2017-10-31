/**
 * Created by arnab.karsarkar on 10/31/2017.
 */

@RestResource(urlmapping='/SFDCLead/*')
global class WebHookLeadManagement {


	private List<Lead_Mapping__mdt> mappings;
	@HttpPost
	global static void CreateLead(){
	 	 try{
			RestRequest req = RestContext.request;
			Lead newLead = Lead();
			//iterate through the list and map fields from the request;
			JSONParser parser = JSON.createParser(req);
			while (parser.nextToken() != null) {
				string field  =  parser.getCurrentName();
				string value = parser.readValueAs(string);
				for (Lead_Mapping__mdt mapping : mappings) {


				}
			}
			System.debug('req ==>> ' + req);
			System.debug('paramMap ==>> ' + req.params);
			Blob body = req.requestBody;
			System.debug('body ==>> ' + body);
			String bodyString = body.toString();
			System.debug('body string ==>> ' + bodyString);
			Map<String,string> paramMap = req.params;
		}catch (Exception ex){
			System.debug('exception => ' + ex.getMessage());
		}



		//System.debug('paramMap ==>> ' + paramMap);

	}
	global WebHookLeadManagement(){
		this.mappings = [Select Lead_Fields__c, WebHooks_Fields__c, DeveloperName from Lead_Mapping__mdt];
	}


}