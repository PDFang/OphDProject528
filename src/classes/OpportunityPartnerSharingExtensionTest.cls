/**
 * Created by mohandaas.rangaswamy on 12/9/2016.
 */

@IsTest
private class OpportunityPartnerSharingExtensionTest {

    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String ACCOUNT_TYPE_PARTNERS = 'Partners';
    static final String CONTACT_TYPE_PARTNER = 'Partner Contact';
    static final String OPPORTUNITY_TYPE_NEW = 'New Opportunity';

    static testMethod void testBehavior(){

        Opportunity opp = [Select Id from Opportunity LIMIT 1];
        test.startTest();
        ApexPAges.StandardController oppController = new ApexPAges.StandardController(opp);
        OpportunityPartnerSharingExtension extension = new OpportunityPartnerSharingExtension(oppController);
        system.assertNotEquals(null,extension.opp, ApexPages.getMessages());
        OpportunityPartnerSharingExtension.getOptions();
        List<OpportunityPartnerSharingExtension.UserWrapper> wrapperList = extension.getDisplayList();
        system.assertEquals(4, wrapperList.size(), ApexPages.getMessages());

        extension.keyword = 'Partner';
        extension.search();
        wrapperList = extension.getDisplayList();
        system.assertEquals(4, wrapperList.size());
        system.assertEquals(extension.getTotalPages(), 1);

        extension.last();
        extension.previous();
        extension.next();
        extension.first();
        extension.getEnableSharing();

        extension.shareOpportunity();
        system.assert(ApexPages.hasMessages());

        wrapperList[0].selected = true;
        wrapperList[1].selected = true;
        extension.shareOpportunity();

        List<Shared_Opportunity__c> sharedOppList = [Select Id from Shared_Opportunity__c where Opportunity__c = :opp.Id];
        system.assertEquals(2, sharedOppList.size());

        opp = [Select iCE_Partner_Status__c, iCE_Partner__c from Opportunity LIMIT 1];
        system.assertEquals('Pending', opp.iCE_Partner_Status__c);

        extension.keyword = 'Partner';
        extension.search();

        extension.cancel();

        test.stopTest();

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