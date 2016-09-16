trigger Trip_AttendeeBeforeDelete on Trip_Attendee__c (before delete) 
{
	//Loop through all the Trip_Attendee__c objects checking to make sure they aren't 
	// deleting a Attendee that has already been surveyed.
	for(Trip_Attendee__c attendee : trigger.old)
	{
		//When we spawn a survey we set the survey spawn date.  If it's not null then
		// we have surveyed them and will not allow a delete so we have a record of the 
		// spawn.
		if(attendee.SurveySpawnDate__c != null)
			attendee.addError('Attendee can not be deleted because it has already had a survey sent to them.');
	}
}