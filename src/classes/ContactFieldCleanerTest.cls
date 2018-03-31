/**
 * Created by mohandaas.rangaswamy on 3/30/2018.
 */
@isTest
private class ContactFieldCleanerTest {

    static testmethod void TestContactEmailAndADFSGuid_AreNull_WhenRun()
    {
        Integer size = 100;
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

        ContactFieldCleaner cleaner = new ContactFieldCleaner('SELECT Id, Email FROM Contact', 'Sandbox');
        Database.executeBatch(cleaner);

        cleaner.sendErrorEmail(new List<String>());

        Test.stopTest();

        Contact[] contactsUpdated = [SELECT Email FROM Contact WHERE Email like '%Sandbox'];

        //all of the contact records should have been updated.
        System.assertEquals(contactList.size(), contactsUpdated.size());


    }
}