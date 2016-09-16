@isTest
public class UpsertCommunityUsersTest { 

    public static testmethod void createUserTest()
    {
		map<string, String> attributes = new map<string, string>();
	    attributes.put('User.ContactUserName', 'test_user01');
     	string federationIdentifier = 'test.user01' ;  
        string actName = 'testAccount';
        Account act = inContactBaseClass.CreateAccount(actName);
        
        Contact con = new Contact();
        con.AccountId = act.Id;
        con.Phone = '999-999-9999';
        con.Email = 'test@test4568527.com';
        con.FirstName = 'Test';
        con.LastName = 'CommunityContact';
        con.Username__c = 'test_user01';        
        insert con;

        UpsertCommunityUsers samlHandler = new UpsertCommunityUsers();	
        User u = samlHandler.createUser(null,null ,null,federationIdentifier, attributes,'');
        
        system.assertEquals('test.user01', u.FederationIdentifier);
        
        
    }

}