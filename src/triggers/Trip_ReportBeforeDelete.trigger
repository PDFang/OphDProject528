trigger Trip_ReportBeforeDelete on Trip_Report__c (before delete) 
{
	//gather all the IDs to use in gathering all the attendees from the database
	Set<ID> tripReportIds = new Set<ID>();
	for(Trip_Report__c tripReport : trigger.old)
	{
		tripReportIds.add(tripReport.Id);
	}
	 
	//Get the Trip_Report IDs for all the trips in this trigger that have a non 
	// null spawn date on one of their attendees
	List<Trip_Attendee__c> spawnedTripAttendees = new List<Trip_Attendee__c>([Select t.Trip_Report__c From Trip_Attendee__c t where t.Trip_Report__c IN :tripReportIds AND t.SurveySpawnDate__c != null]);
	Set<ID> spawnedTripReportIds = new Set<ID>();
	for(Trip_Attendee__c tripAttendee : spawnedTripAttendees)
	{
		spawnedTripReportIds.add(tripAttendee.Trip_Report__c);
	}
	
	//Loop through all the trip reports being deleted and see if they can't be 
	// deleted because they have spawned a survey to one of their attendees
	for(Trip_Report__c tripReport : trigger.old)
	{
		//When we spawn a survey we set the survey spawn date.  If it's not null then
		// we have surveyed them and will not allow a delete so we have a record of the 
		// spawn.
		if(spawnedTripReportIds.contains(tripReport.Id))
			tripReport.addError('Trip Report can not be deleted because it has already had a survey sent to one of it\'s attendees.');
	}
	
}