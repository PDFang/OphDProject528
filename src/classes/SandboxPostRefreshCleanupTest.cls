@isTest
public class SandboxPostRefreshCleanupTest 
{ 
	@isTest
	static void TestContactEmailAndADFSGuid_AreNull_WhenRun()
	{		
		Integer size = 400;
		Contact[] contactList = new List<Contact>();

		for (Integer i = 0; i < size; i++)
		{
			Contact contact = new Contact(
				FirstName = 'Test_' + i,
				LastName = 'Last_' + i, 
				Email = 'Contact_' + i + '@test.com',
				ADFSGuid__c = 'Contact_' + i + '_Guid'
			);
			contactList.Add(contact);
		}

		insert contactList;
        
        //insert customsettings for the test
        refedge__POR_App_Configuration__c referenceEdgeSetting = new refedge__POR_App_Configuration__c();
        referenceEdgeSetting.refedge__ContactTrigger__c = true;
        insert referenceEdgeSetting;	
        
		Test.startTest();
		
		
		SandboxPostRefreshCleanup cleanup = new SandboxPostRefreshCleanup();
		Test.testSandboxPostCopyScript(cleanup, UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
		
		//cleanup.runApexClass(null);
		string appendedValue = '%' + UserInfo.getOrganizationId();

		Contact[] contactsWithADFSGuid = [SELECT ADFSGuid__c, Email FROM Contact WHERE Email like :appendedValue AND ADFSGuid__c != null];

		//all of the contact records should have been updated.
		System.assertEquals(0, contactsWithADFSGuid.size());

		Contact[] contacts = [SELECT ADFSGuid__c, Email FROM Contact];
		//ensure the contact records were not deleted
		System.assertEquals(size, contacts.size());

		Test.stopTest();
	}
}