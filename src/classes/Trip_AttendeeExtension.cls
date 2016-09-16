public class Trip_AttendeeExtension 
{
	private final Trip_Attendee__c tripAttendee;
	private final Trip_Report__c tripReport;
		
	public Trip_AttendeeExtension(ApexPages.StandardController stdCtrl)
	{
		tripAttendee = (Trip_Attendee__c)stdCtrl.getRecord();
		tripReport = [SELECT t.Id, t.Name, t.Account__c FROM Trip_Report__c t WHERE t.Id = :tripAttendee.Trip_Report__c];
	}
	
	public PageReference SaveAttendee()
	{		
		if(tripAttendee.Attendee__c != null)
		{
			upsert tripAttendee;
		
			PageReference tripReportPage = new ApexPages.StandardController(tripReport).view();
      		tripReportPage.setRedirect(true);

      		return tripReportPage;
		}
		else
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Attendee is required. Please select an attendee before saving.'));			
			return null;
		}
	}
	
	public PageReference CancelNew()
	{
		PageReference tripReportPage = new ApexPages.StandardController(tripReport).view();
      	tripReportPage.setRedirect(true);

      	return tripReportPage;
	}
	
	public string Trip_Report_Name
	{
		get { return tripReport.Name; }
	}
	
	public boolean Survey
	{
		get { return tripAttendee.Survey__c; }
		set { tripAttendee.Survey__c = value; }
	}
	
	//builds a picklist of Contact Names based on selected Account
	public List<selectOption> Contacts 
	{
		get
		{
			//new list for holding all of the picklist options
			List<SelectOption> options = new List<SelectOption>(); 
			//Add the first option of '- Select Attendee -' in case no values are returned from query below
			options.add(new selectOption('', '- Select Attendee -')); 
			//Get the Contacts for this Account from the Database 
			for (Contact contact : [SELECT c.Id, c.Name FROM Contact c WHERE c.ID NOT IN (SELECT r.Attendee__c FROM Trip_Attendee__c r WHERE r.Trip_Report__c = :tripReport.Id AND r.ID != :tripAttendee.Id) AND c.AccountId = :tripReport.Account__c AND c.Email != null ORDER BY c.Name])  
			{ 
				//for all records found - add them to the picklist options
				options.add(new selectOption(contact.Id, contact.Name)); 
			}
			//return the picklist options
			return options; 
		}
	}
}