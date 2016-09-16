//This class provides logic for inbound just-in-time provisioning of single sign-on users in your Salesforce organization.
global class UpsertCommunityUsers implements Auth.SamlJitHandler {
	private class JitException extends Exception{}
	private void handleUser(boolean create, User u, Map<String, String> attributes,
		String federationIdentifier, boolean isStandard) {		
		try 
		{	        
			if(create) 
			{
				u.FederationIdentifier = federationIdentifier;
				if (attributes.containsKey('User.ContactUserName'))
				{
					Contact c = new Contact();
					string userName = attributes.get('User.ContactUserName');
                    system.debug('userName =>' + userName);
					c = [Select Id, Phone, Email, FirstName, LastName,  Title, Account.Name, Fax from Contact Where Username__c = :userName Limit 1];
					u.Phone = c.Phone;
					u.Email = c.Email;		
					u.FirstName = c.FirstName;		
					u.LastName = c.LastName;
					u.Title = c.Title;
					u.Fax = String.valueOf(c.Fax);
                    u.ContactId = c.Id;
                    u.Username = c.Email;
					u.CommunityNickname = c.FirstName.substring(0) + c.LastName.substring(0);
					String uid = UserInfo.getUserId();
					User currentUser = [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id=:uid];
					u.LocaleSidKey = currentUser.LocaleSidKey;
					u.LanguageLocaleKey = currentUser.LanguageLocaleKey;
					String alias = '';
					if(u.FirstName == null) {
						alias = u.LastName;
					} else {
						alias = u.FirstName.charAt(0) + u.LastName;
					}
					if(alias.length() > 5) {
						alias = alias.substring(0, 5);
					}
					u.Alias = alias;
					u.TimeZoneSidKey = currentUser.TimeZoneSidKey;
					u.EmailEncodingKey = currentUser.EmailEncodingKey;
					Profile p = [SELECT Id FROM Profile WHERE Name = :'Community Client' Limit 1];
					u.ProfileId = p.Id;                    
                    
				}
			}
			if(!create) {
				update(u);
			}
		}
		catch ( Exception e)
		{

			throw new JitException('Exception Occured during user Assignment: ' + e.getMessage() + ' , at line number - ' + e.getLineNumber());
		}
		
	}

	// // need account Id 
	// need attribute User.ContactName
	
	private void handleJit(boolean create, User u, Id samlSsoProviderId, Id communityId, Id portalId,
		String federationIdentifier, Map<String, String> attributes, String assertion) 
	{
			handleUser(create, u, attributes, federationIdentifier, true);
	}

	global User createUser(Id samlSsoProviderId, Id communityId, Id portalId,
		String federationIdentifier, Map<String, String> attributes, String assertion) {
		User u = new User();
		handleJit(true, u, samlSsoProviderId, communityId, portalId,
			federationIdentifier, attributes, assertion);
            system.debug('u ==>' + u);
		return u;
            
	}

	global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
		String federationIdentifier, Map<String, String> attributes, String assertion) {
		User u = [SELECT Id, FirstName, ContactId FROM User WHERE Id=:userId];
		handleJit(false, u, samlSsoProviderId, communityId, portalId,
			federationIdentifier, attributes, assertion);
	}
}