public class inContactBaseClass 
{
    public static String OrgId15Digit = UserInfo.getOrganizationId().left(15);

	public static String SelectRecordTypeIDByName(string recType, string objName)
	{
		String recTypeId = [SELECT ID FROM RecordType WHERE sObjectType = :objName AND Name = :recType LIMIT 1].id;
		return recTypeId;
		
	}
	
	public static Boolean HasEditAccess(Id recordId, Id userId)
	{
		//determine if the user has edit access to specific record from any object
		
		UserRecordAccess ua = new UserRecordAccess();
		ua = [Select u.RecordId, u.HasEditAccess  From UserRecordAccess u WHERE RecordId = :recordId AND UserId = :userId LIMIT 1];
		
		return ua.HasEditAccess;
	}
	
	public static Account CreateAccount(string name)
	{
		Account a = new Account();
		a.Name = name;
	
		return a;
	}
	
	public static Account CreateAccount(string name, string recordTypeId )
	{
		Account a = new Account();
		a.Name = name;
		a.RecordTypeId = recordTypeId;
	
		return a;
	}
	
    public static Asset CreateAsset(string name)
    {
        Asset ass = new Asset();
        ass.Name = name;
        
        return ass;
    }
    public static Asset CreateAsset(string name, string recordTypeId )
    {
        Asset ass = new Asset();
        ass.Name = name;
        ass.RecordTypeId = recordTypeId;
        
        return ass;
    }
	public static Contact CreateContact(string accountId, string firstName, string lastName, string email)
	{
		Contact c = new Contact();
		c.AccountId = accountId;
		c.FirstName = firstName;
		c.LastName = lastName;
		c.Email = email;
		
		return c;
	}
	
	public static Contact CreateContact(string accountId, string firstName, string lastName, string email, string recordTypeId)
	{
		Contact c = new Contact();
		c.AccountId = accountId;
		c.FirstName = firstName;
		c.LastName = lastName;
		c.Email = email;
		c.RecordTypeId = recordTypeId;
		
		return c;
	}
	
	public static Case CreateCase(string accountId, string contactId, string recordTypeId, string subject)
	{
		//set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
		
		
		Case c = new Case(); 
		c.AccountId = accountId;
		c.ContactId = contactId;
		c.RecordTypeId = recordTypeId;
		c.Subject = subject;
		
		c.setOptions(dmo);
		
		return c;
	}
	
	public static Lead CreateLead (string firstName, string lastName, string leadSource, string company)
	{
		Lead l = new Lead();
		l.FirstName = firstName;
		l.LastName = lastName;
		l.LeadSource = leadSource;
		l.Company = company;
		
		return l;
	}
	
	public static Set<id> GetUserIdsFromGroup(Id groupId)
    {
        // store the results in a set so we don't get duplicates
        Set<Id> result=new Set<Id>();
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        
        // Loop through all group members in a group
        for (GroupMember m : [Select Id, UserOrGroupId From GroupMember Where GroupId = :groupId])
        {
            // If the user or group id is a user
            if (((String)m.UserOrGroupId).startsWith(userType))
            {
                result.add(m.UserOrGroupId);
            }
            // If the user or group id is a group
            // Note: there may be a problem with governor limits if this is called too many times
            else if (((String)m.UserOrGroupId).startsWith(groupType))
            {
                // Call this function again but pass in the group found within this group
                result.addAll(GetUSerIdsFromGroup(m.UserOrGroupId));
            }
        }
        
        return result;  
    }
    
    
	public static Map<String,Schema.RecordTypeInfo> GetRecordTypesByObject(string objectName)
	{
		List<Schema.DescribeSObjectResult> d = Schema.describeSObjects(new string[]{'objectName'}); 
		Map<String,Schema.RecordTypeInfo> rtMapByName = d[0].getRecordTypeInfosByName();
		
		return rtMapByName;
		 
	}
    
    
    public static void SendErrorEmail(Exception ex, string recordId)
    {
        system.debug(' **** inContactBaseClass.SendErrorEmail: ' + ex);
		system.debug(' **** inContactBaseClass.SendErrorEmail: ' + ex.getStackTraceString());
        SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(OrgId15Digit);
    	string subject = 'Apex Error - ' + Userinfo.getName();
    	
    	if(string.isNotBlank(recordId))
    	{
    		subject = subject + ' Record Id: ' + recordId;
    	}
    	
    	Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    	
        String[] toAddresses;
        
        if(!test.isRunningTest())
        {
    		toAddresses = new String[]{siteConfig.DeveloperErrorEmail__c};
    		email.setSenderDisplayName(siteConfig.DeveloperErrorFromName__c);
        }
        else
        {
    		toAddresses = new String[]{'test@test.com'};
    		email.setSenderDisplayName('Test Sender');
        }
    	//set mail info
    	email.setSubject(subject);
    	email.setToAddresses(toAddresses);
    	email.setHtmlBody(ex.getMessage() + '<br/><br/><h2>Stack Trace:</h2><br/>' + ex.getStackTraceString());
    	email.setPlainTextBody(ex.getMessage() + '/n/r/n/rStack Trace:/n/r' + ex.getStackTraceString());
    	
    	//send message
		try{
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
		}catch(EmailException emailEx){
			system.debug('EmailException - '+ emailEx);
		}

    }
    
    public static void SendErrorEmail(string errorMessage, string recordId)
    {
        SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(OrgId15Digit);
    	string subject = 'Apex Error - ' + Userinfo.getName();
    	
    	if(string.isNotBlank(recordId))
    	{
    		subject = subject + ' Record Id: ' + recordId;
    	}
    	
    	Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    	
        String[] toAddresses;
        
        if(!test.isRunningTest())
        {
    		toAddresses = new String[]{siteConfig.DeveloperErrorEmail__c};
    		email.setSenderDisplayName(siteConfig.DeveloperErrorFromName__c);
        }
        else
        {
    		toAddresses = new String[]{'test@test.com'};
    		email.setSenderDisplayName('Test Sender');
        }
    	email.setSubject(subject);
    	email.setToAddresses(toAddresses);
    	email.setHtmlBody(errorMessage);
    	email.setPlainTextBody(errorMessage);
    	
    	//send message
		try{
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
		}catch(EmailException emailEx){
			system.debug('EmailException - '+ emailEx);
		}

    }
	
    
    
    
    public static String LimitStringLength(String input, Integer maxLength)
	{
		 String results;
		 if(input != null && input.length() > maxLength) 
		 {
		 	results = input.substring(0,maxLength);
		 }
		 else
		 { 
		 	results = input;
		 }
		 return results;
	}
}