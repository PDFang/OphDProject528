global class FeatureWebServices 
{
	//used to commit a feature
	WebService static String CommitFeature(String featureId)
	{
		Feature__c f = new Feature__c();
		Project__c p = new Project__c();
		ID commitRt;
		String returnMessage = 'Success';
		
		
		//get commited feature record type
		commitRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Feature__c' AND Name = 'Commited Feature'].Id;
		
		//get feature and project record
		f = [SELECT Id, Project__c, RecordTypeId, FeatureStatus__c, FeatureState__c FROM Feature__c WHERE Id = :featureId];
		p = [SELECT Id, ProjectStatus__c FROM Project__c WHERE Id = :f.Project__c];
		
		//update feature fields
		f.FeatureState__c = 'Next';
		f.FeatureStatus__c = 'Committed';
		f.RecordTypeId = commitRt;
		
		try
		{	
			update f;
		}
		catch(DmlException ex)
		{
        	return ex.getDMLMessage(0);
    	}
		
		if(p.ProjectStatus__c != 'Being Worked' && p.ProjectStatus__c != 'Assigned To Sprint')
		{
			p.ProjectStatus__c = 'Assigned To Sprint';
		
			try
			{	
				update p;
			}
			catch(DmlException ex)
			{
	        	return ex.getDMLMessage(0);
	    	}
		}
		
		return returnMessage;
		
	}
}