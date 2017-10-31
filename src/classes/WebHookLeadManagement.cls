/**
 * Created by arnab.karsarkar on 10/31/2017.
 */

@RestResource(urlmapping='/SFDCLead/*')
global class WebHookLeadManagement {

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
		}catch (Exception ex){
			System.debug('exception => ' + ex.getMessage());
		}



		//System.debug('paramMap ==>> ' + paramMap);

	}
}