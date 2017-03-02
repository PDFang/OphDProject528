@isTest
private class SurveyTestClass 
{
    //Test HelpDesk Survey
   static testMethod void TestHelpDeskSurvey()
    {
        Case[] helpdeskCases = [Select Id, Status, Reason, Disposition__c, Owner.Name from Case where RecordType.Name = 'Help Desk'];
        system.assertEquals('IT-Help Desk Queue', helpdeskCases[0].Owner.Name, 'Case was supposed to be assigned to IT Help Desk.');
        system.assertEquals('IT-Help Desk Queue', helpdeskCases[1].Owner.Name, 'Case was supposed to be assigned to IT Help Desk.');
        test.startTest();
        for(Case c :helpdeskCases){
            c.Reason = 'Help Desk Issue';
            c.Disposition__c = 'Other';
            c.Status = 'Closed';
        }

        update helpdeskCases;
        test.stopTest();

        CaseComment[] comments = [Select Id, commentBody from CaseComment where ParentId IN :helpdeskCases];
        system.assertEquals(2, comments.size(), 'There suppose to be one comment added for each Case.');
        system.assert(comments[0].commentBody.startsWith('A survey request was successfully submitted.'), 'Actual comment - '+ comments[0].commentBody);
        system.assert(comments[1].commentBody.startsWith('No survey was sent.'), 'Actual comment - ' + comments[1].commentBody);

    } // end of TestHelpDeskSurvey(0

    @TestSetup
    private static void createTestData(){

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'Test Account',
                Billing_Group__c = 'Test Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId()
        );

        insert testAccount;

        Map<String,Schema.RecordTypeInfo> contactRecordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact[] testContacts = new Contact[]{};
        testContacts.add(new Contact(
                LastName = 'Contact1',
                FirstName = 'Test',
                Email = 'contact1@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccount.Id
        ));

        testContacts.add(new Contact(
                LastName = 'Contact2',
                FirstName = 'Test',
                Email = null,
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccount.Id
        ));

        insert testContacts;

        Group itGroup = new Group(Name='IT-Help Desk Queue', Type='Queue');
        insert itGroup;

        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            QueuesObject itQueue = new QueueSObject(QueueID = itGroup.id, SObjectType = 'Case');
            insert itQueue;
        }

        // create HelpDesk Case
        Map<String,Schema.RecordTypeInfo> caseRecordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case[] helpdeskCases = new Case[]{};
        helpdeskCases.add(new Case(
                RecordTypeId = caseRecordTypeMap.get('Help Desk').getRecordTypeId(),
                OwnerId = itGroup.Id,
                Subject = 'Assign to HelpDesk',
                Description = 'Assign to HelpDesk',
                Status = 'New',
                Origin = 'Email',
                Priority = 'P1',
                AccountId = testAccount.Id,
                ContactId = testContacts[0].Id,
                Request_Type__c = 'Other'
        ));

        helpdeskCases.add(new Case(
                RecordTypeId = caseRecordTypeMap.get('Help Desk').getRecordTypeId(),
                OwnerId = itGroup.Id,
                Subject = 'Assign to HelpDesk',
                Description = 'Assign to HelpDesk',
                Status = 'New',
                Origin = 'Email',
                Priority = 'P1',
                AccountId = testAccount.Id,
                ContactId = testContacts[1].Id,
                Request_Type__c = 'Other'
        ));

        insert helpdeskCases;

    } // createTestData()

}