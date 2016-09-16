@isTest	
private class DG_Lead_Class_TEST {
    static testMethod void ReEngagedMQL_ToSalesDev_OnUpdate_TEST() {
    	
    	Profile p = [select id from profile where name = 'Sales Development'];

		User u = new User(
		FirstName = 'APEX',
		LastName = 'TestUser', 
		email = 'APEX@APEXTEST.xxx',
		Username = 'APEX@APEXTEST.xxx',
		Alias = 'APEX',
		TimeZoneSidKey = 'America/Los_Angeles',
		LocaleSidKey = 'en_US',
		EmailEncodingKey = 'ISO-8859-1',
		ProfileId = p.id,
		LanguageLocaleKey = 'en_US');
		try{
    		insert u;
    	}catch(exception e){}  
    	
    	//Lead to test status changing to Re-Engaged MQL with Sales Developer that is an active user with a Sales Development profile
    	Lead l = new Lead(
    	FirstName = 'TEST',
    	LastName = 'TEST',
    	Company = 'TEST IBM',
    	Email = 'test@test.com',
    	City = 'So. San Francisco',
    	State = 'CA',
    	PostalCode = '94080',
    	Country = 'USA',
    	Title = 'Boss',
    	Phone = '777-777-7777',
    	Sales_Developer__c = u.id,
    	Status = 'Open'); 
    	
    	try{  	
    		insert l;
    	}catch(exception e){}
    	
    	l.Status = 'Re-Engaged MQL';
    	try{
    		update l;
    	}catch(exception e){}

    }
    
    static testMethod void ReEngagedMQL_ToAssignmentRule_OnUpdate_TEST() {
    	
    	Profile p = [select id from profile where name = 'System Administrator'];

		User u = new User(
		FirstName = 'APEX',
		LastName = 'TestUser',
		email = 'APEX@APEXTEST.xxx',
		Username = 'APEX@APEXTEST.xxx',
		Alias = 'APEX',
		TimeZoneSidKey = 'America/Los_Angeles',
		LocaleSidKey = 'en_US',
		EmailEncodingKey = 'ISO-8859-1',
		ProfileId = p.id,
		LanguageLocaleKey = 'en_US');
		try{
    		insert u;
    	}catch(exception e){}
    	
    	list<Lead> listLead = new list<Lead>();
    	
    	//Lead to test status changing to Re-Engaged MQL with Sales Developer that is an active user with a non-Sales Development profile
    	Lead l1 = new Lead(
    	FirstName = 'TEST',
    	LastName = 'TEST',
    	Company = 'TEST IBM',
    	Email = 'test@test.com',
    	City = 'So. San Francisco',
    	State = 'CA',
    	PostalCode = '94080',
    	Country = 'USA',
    	Title = 'Boss',
    	Phone = '777-777-7777',
    	Sales_Developer__c = u.id,
    	Status = 'Open'); 
    	
    	listLead.add(l1);
    	
    	//Lead to test status changing to Re-Engaged MQL without Sales Developer defined.
    	Lead l2 = new Lead(
    	FirstName = 'TEST',
    	LastName = 'TEST',
    	Company = 'TEST IBM',
    	Email = 'test@test.com',
    	City = 'So. San Francisco',
    	State = 'CA',
    	PostalCode = '94080',
    	Country = 'USA',
    	Title = 'Boss',
    	Phone = '777-777-7777',
    	Status = 'Open'); 
    	
    	listLead.add(l2);
    	
    	try{  	
    		insert listLead;
    	}catch(exception e){}
    	
    	l1.Status = 'Re-Engaged MQL';
    	l2.Status = 'Re-Engaged MQL';
    	
    	try{
    		update listLead;
    	}catch(exception e){}

    }
}