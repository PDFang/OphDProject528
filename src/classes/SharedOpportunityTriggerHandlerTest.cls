/**
 * Created by mohandaas.rangaswamy on 12/9/2016.
 */

@IsTest
private class SharedOpportunityTriggerHandlerTest {

    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String ACCOUNT_TYPE_PARTNERS = 'Partners';
    static final String CONTACT_TYPE_PARTNER = 'Partner Contact';
    static final String OPPORTUNITY_TYPE_NEW = 'New Opportunity';

    // case when Shared Opportunity is accepted
    static testMethod void testOpportunityAcceptance() {

        Opportunity opp = [Select Id, AccountId from Opportunity LIMIT 1];
        Account partner = [Select Id from Account where Type = 'Partner' LIMIT 1];
        List<User> userList = [Select Id from User where AccountId = :partner.Id];
        List<Shared_Opportunity__c> sharedOppList = new List<Shared_Opportunity__c>();
        for(User u :userList){
            Shared_Opportunity__c sharedOpp = new Shared_Opportunity__c(
                    Partner_User__c = u.Id,
                    Opportunity__c = opp.Id
            );
            sharedOppList.add(sharedOpp);
        }
        insert sharedOppList;
        // apex sharing
        List<Shared_Opportunity__Share> shareList = new List<Shared_Opportunity__Share>();
        for(Shared_Opportunity__c sharedOpp : sharedOppList){
            Shared_Opportunity__Share newShare = new Shared_Opportunity__Share();
            newShare.ParentId = sharedOpp.Id;
            newShare.UserOrGroupId = sharedOpp.Partner_User__c;
            newShare.AccessLevel = 'Edit';
            newShare.Rowcause = Schema.Shared_Opportunity__Share.RowCause.iCE_Partner__c;
            shareList.add(newShare);
        }
        insert shareList;

        test.startTest();
        sharedOppList[0].Status__c = 'Accepted';
        update sharedOppList[0];
        test.stopTest();

        opp = [Select Id, AccountId, iCE_Partner_Status__c, iCE_Partner__c from Opportunity where Id = :opp.Id];

        system.assertEquals('Accepted',opp.iCE_Partner_Status__c);
        system.assertEquals(partner.Id,opp.iCE_Partner__c);

        List<Account_Partner__c> partnerList = [
                Select Id from Account_Partner__c
                where Customer__c = :opp.AccountId
                and Partner__c = :partner.Id
                and Partner_Type__c = :AccountPartnerTriggerHandler.ICE_PARTNER
        ];
        system.assertEquals(1, partnerList.size(), 'Account Partner record was not created.');

        boolean hasException = false;
        try{
            sharedOppList[1].Status__c = 'Accepted';
            update sharedOppList[1];
        } catch(system.DMLException ex){
            hasException = true;
        }
        system.assert(hasException, 'Opportunity has been accepted already. It can\'t be accepted again.');

    }

    // case when Shared Opportunity is rejected
    static testMethod void testOpportunityRejection() {

        Opportunity opp = [Select Id, AccountId from Opportunity LIMIT 1];
        Account partner = [Select Id from Account where Type = 'Partner' LIMIT 1];
        List<User> userList = [Select Id from User where AccountId = :partner.Id];
        List<Shared_Opportunity__c> sharedOppList = new List<Shared_Opportunity__c>();
        for(User u :userList){
            Shared_Opportunity__c sharedOpp = new Shared_Opportunity__c(
                    Partner_User__c = u.Id,
                    Opportunity__c = opp.Id
            );
            sharedOppList.add(sharedOpp);
        }
        insert sharedOppList;
        // apex sharing
        List<Shared_Opportunity__Share> shareList = new List<Shared_Opportunity__Share>();
        for(Shared_Opportunity__c sharedOpp : sharedOppList){
            Shared_Opportunity__Share newShare = new Shared_Opportunity__Share();
            newShare.ParentId = sharedOpp.Id;
            newShare.UserOrGroupId = sharedOpp.Partner_User__c;
            newShare.AccessLevel = 'Edit';
            newShare.Rowcause = Schema.Shared_Opportunity__Share.RowCause.iCE_Partner__c;
            shareList.add(newShare);
        }
        insert shareList;

        test.startTest();
        sharedOppList[0].Status__c = 'Rejected';
        update sharedOppList[0];
        test.stopTest();

        opp = [Select Id, AccountId, iCE_Partner_Status__c, iCE_Partner__c from Opportunity where Id = :opp.Id];

        system.assertNotEquals('Accepted',opp.iCE_Partner_Status__c);
        system.assertNotEquals(partner.Id,opp.iCE_Partner__c);

        List<Account_Partner__c> partnerList = [
                Select Id from Account_Partner__c
                where Customer__c = :opp.AccountId
                and Partner__c = :partner.Id
                and Partner_Type__c = :AccountPartnerTriggerHandler.ICE_PARTNER
        ];
        system.assertEquals(0, partnerList.size(), 'Account Partner record should not have been created.');

    }

    @testSetup
    static void createTestData() {

        User admin = [Select Id from User where Profile.Name = 'System Administrator' and isActive = true LIMIT 1];
        PermissionSet iCEPermissionSet = new PermissionSet();
        system.runAs(admin) {
            iCEPermissionSet.Name = 'iCE_Partner';
            iCEPermissionSet.Label = 'iCE Partner';
            insert iCEPermissionSet;
        }
        Partner_Permission_Sets__c permission = new Partner_Permission_Sets__c(
                Name = 'iCE',
                Permission_Set__c = iCEPermissionSet.Name,
                Partner_Type__c = OpportunityPartnerSharingExtension.PARTNEY_TYPE_ICE
        );

        insert permission;

        List<Account> accountList = createAccounts();
        List<Contact> contactList = createContacts(accountList[1]);
        createOpportunity(accountList[0]);
        List<User> userList = CreatePartnerUsers(contactList);

        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        system.runAs(admin) {
            for (Integer i = 0; i < userList.size(); i++) {
                PermissionSetAssignment psa = new PermissionSetAssignment(
                        AssigneeId = userList[i].Id,
                        PermissionSetId = iCEPermissionSet.Id
                );
                psaList.add(psa);
            }
            insert psaList;
        }

    } // end of createTestData()

    static List<Account> createAccounts()
    {
        Map<String, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        List<Account> accountList = new List<Account>();
        accountList.add(
                new Account(
                        Name = 'Customer Account',
                        Type = 'Customer',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS).getRecordTypeId()
                )
        );
        accountList.add(
                new Account(
                        Name = 'Partner Account',
                        Type = 'Partner',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_PARTNERS).getRecordTypeId()
                )
        );

        insert accountList;

        return accountList;

    } // end of createAccounts()

    static List<Contact> createContacts(Account acct){

        Map<String, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        List<Contact> contactList = new List<Contact>();
        contactList.add(
                new Contact(
                        LastName = 'Partner Contact 1',
                        Email = 'contact1@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER).getRecordTypeId(),
                        AccountId = acct.Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'Partner Contact 2',
                        Email = 'contact2@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER).getRecordTypeId(),
                        AccountId = acct.Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'Partner Contact 3',
                        Email = 'contact3@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER).getRecordTypeId(),
                        AccountId = acct.Id
                )
        );
        contactList.add(
                new Contact(
                        LastName = 'Partner Contact 4',
                        Email = 'contact4@incontact.com',
                        RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER).getRecordTypeId(),
                        AccountId = acct.Id
                )
        );

        insert contactList;

        return contactList;

    } // end of createContacts()

    static void createOpportunity(Account acct){

        Map<String, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Opportunity testOpp = new Opportunity(
                Name = 'Test Opp',
                AccountId = acct.Id,
                RecordTypeId = recordTypeMap.get(OPPORTUNITY_TYPE_NEW).getRecordTypeId(),
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(7),
                Probability = 25,
                Partner_Deal__c = 'NO',
                Contract_Type__c = 'New Customer',
                inContact__c = 'YES',
                inContact_Setup_Fee__c = 1000,
                inContact_Seats__c = 1,
                inContact_MRC_Min__c = 1000,
                inContact_Ports__c = 1,
                inContact_MRC_Exp__c = 1000,
                ECHO__c = 'NO',
                eLearning__c = 'NO',
                Hiring__c = 'NO',
                WFM__c = 'NO'
        );
        insert testOpp;

    } // end of createOpportunity()

    static List<User> createPartnerUsers(List<Contact> contactList) {

        List<User> userList = new List<User>();
        Profile profile = [SELECT Id from Profile where Name = 'Partner Community User'];

        for(Integer i=0; i < contactList.size(); i++){
            userList.add(
                    new User(
                            FirstName = 'Partner',
                            LastName = 'User' + i,
                            ContactId = contactList[i].Id,
                            Email = contactList[i].Email,
                            Username = contactList[i].Email,
                            Alias = 'test'+i,
                            profileId = profile.Id,
                            EmailEncodingKey = 'UTF-8',
                            TimeZoneSidKey = 'America/Los_Angeles',
                            LocaleSidKey = 'en_US',
                            LanguageLocaleKey = 'en_US'
                    )
            );
        }

        insert userList;

        return userList;

    }// end of createPartnerUsers()

}