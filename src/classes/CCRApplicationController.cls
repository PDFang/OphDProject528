/**
 * Created by arnab.karsarkar on 12/11/2017.
 */

public class CCRApplicationController {

	public String currentCCRId{get;set;}
	public ChangeControlRequest__c ccrApplication{get;set;}


	public CCRApplicationController(){

		currentCCRId = ApexPages.currentPage().getParameters().get('id');
		system.debug('currentCCRId(): currentId - ' + currentCCRId);

		ccrApplication = [SELECT Id, Name, Status__c FROM ChangeControlRequest__c where Id = :currentCCRId Limit 1];


	}

	public string applicationList
	{
		get
		{
			Schema.DescribeFieldResult fieldResult = CCRApplication__c.Application__c.getDescribe();
			list<string> applicationPicklistValues = new list<string>();
			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
			for(Schema.PicklistEntry pl:ple)
			{
				applicationPicklistValues.add(pl.getValue());
			}

			return JSON.Serialize(applicationPicklistValues);
		}
	}

	public pagereference cancel(){
		return new PageReference('/'+currentCCRId).setRedirect(true);
	}


	@RemoteAction
	public static string GetAllApplications(string CCRId){
		if(CCRId == null || CCRId == '')
			return null;

		List<CCRApplication__c> applications = new List<CCRApplication__c>();
		applications = [Select Id, Application__c, Description__c, ChangeControlRequest__c From CCRApplication__c where ChangeControlRequest__c =: CCRId];
		if(applications.size() > 0)
			return JSON.serialize(applications);

		return null;
	}

	@RemoteAction
	public static string UpSertApplication(string application){
		String result;
		String message = '';
		try{
			system.debug('inside add new application (): application ->> '+application);
			CCRApplication__c ccrApplication = (CCRApplication__c)JSON.deserialize(application, CCRApplication__c.class);
			upsert ccrApplication;
			result = 'Success';
		}
		catch (DmlException ex){
			return handleException(ex);
		}
		return sendResponse(result, message);

	}

	@RemoteAction
	public static string DeleteApplication(string applicationId){
		String result;
		String message = '';
		try{
			delete [select id from CCRApplication__c where Id =: applicationId];
			result = 'Success';
		}
		catch (DmlException ex){
			return handleException(ex);

		}
		return sendResponse(result, message);
	}



	private static string sendResponse(String result, string message){
		System.JSONGenerator generator = Json.createGenerator(true);
		generator.writeStartObject();
		generator.writeStringField('result', result);
		generator.writeStringField('message', message);
		return generator.getAsString();
	}

	private static string handleException(DmlException ex) {
		String result = 'Failed';
		String message = ex.getMessage();
		Integer occurrence;
		if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
			occurrence = message.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
			message = message.mid(occurrence, message.length());
			occurrence = message.lastIndexOf(':');
			message = message.mid(0, occurrence);
		}
		else {
			message = ex.getMessage();
		}
		return sendResponse(result, message);
	}




}