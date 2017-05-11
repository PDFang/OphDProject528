@isTest
public class PartnerDocumentLandingPageControllerTest {

    static Account testAccount;
    static Contact[] contactList;
    static User[] userList;

    static testMethod void testPartnerDocsAccess(){

        createAccount();
        createContacts();
        createUsers();
        createPartnerDocManager();
        createSetupData();

        test.startTest();

        system.runAs(userList[0]){
            PartnerDocumentLandingPageController testController = new PartnerDocumentLandingPageController();
            List<PartnerDocumentLandingPageController.DocumentDetail> documentList = testController.DocumentDetailList;

            system.assertEquals(2, documentList.size(), 'User should have access to two active documents.');
        }

        system.runAs(userList[1]){
            PartnerDocumentLandingPageController testController = new PartnerDocumentLandingPageController();
            List<PartnerDocumentLandingPageController.DocumentDetail> documentList = testController.DocumentDetailList;

            system.assertEquals(3, documentList.size(), 'User should have access to three active documents.');
        }

        test.stopTest();

    }

    static void createSetupData(){

        PermissionSet referralPs = new PermissionSet(
                Name = 'Test_Referral_Permission_Set',
                Label = 'Test_Referral_Permission_Set'
        );

        system.runAs(new User(Id = userInfo.getUserId())){
            insert referralPs;
        }

        PermissionSetAssignment psa = new PermissionSetAssignment(
                PermissionSetId = referralPs.Id,
                AssigneeId = userList[1].Id
        );
        system.runAs(new User(Id = userInfo.getUserId())){
            insert psa;
        }

        Partner_Permission_Sets__c psSetup = new Partner_Permission_Sets__c(
                Partner_Type__c = 'Referral',
                Permission_Set__c = referralPs.Name,
                Name = 'Referral'
        );
        insert psSetup;

    }

    static void createAccount() {

        Map<String, Schema.RecordTypeInfo> accountRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
        testAccount = new Account(
                Name = 'PartnerDocumentLandingPageControllerTest Partner',
                Type = 'Partner',
                RecordTypeId = accountRecordTypes.get('Partners').getRecordTypeId()
        );
        insert testAccount;
    }

    static void createContacts() {
        Map<String, Schema.RecordTypeInfo> contactRecordTypes = Schema.SObjectType.Contact.getRecordTypeInfosByName();

        contactList = new Contact[]{};
        Contact testContact1 = new Contact(
                LastName = 'Contact One',
                Email = 'PartnerDocumentLandingPageControllerTest@incontact.com',
                RecordTypeId = contactRecordTypes.get('Partner Contact').getRecordTypeId(),
                AccountId = testAccount.Id
        );
        contactList.add(testContact1);

        Contact testContact2 = new Contact(
                LastName = 'Contact Two',
                Email = 'PartnerDocumentLandingPageControllerTest@incontact.com',
                RecordTypeId = contactRecordTypes.get('Partner Contact').getRecordTypeId(),
                AccountId = testAccount.Id
        );
        contactList.add(testContact2);

        insert contactList;

    }

    static void createUsers(){

        Profile partnerProfile = [SELECT Id from Profile where Name = 'Partner Community Profile'];

        userList = new User[]{};

        User partnerOne = new User(
                FirstName = 'Partner',
                LastName = 'Contact One',
                ContactId = contactList[0].Id,
                Email = 'partnerone@incontact.com',
                Username = 'partnerone@incontact.com',
                Alias = 'test',
                profileId = partnerProfile.Id,
                EmailEncodingKey = 'UTF-8',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
        );
        userList.add(partnerOne);

        User partnerTwo = new User(
                FirstName = 'Partner',
                LastName = 'Contact Two',
                ContactId = contactList[1].Id,
                Email = 'partnertwo@incontact.com',
                Username = 'partnertwo@incontact.com',
                Alias = 'test',
                profileId = partnerProfile.Id,
                EmailEncodingKey = 'UTF-8',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
        );

        userList.add(partnerTwo);

        insert userList;

    }


    static void createPartnerDocManager(){

        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName();
        ID partnerDocRecordTypeId = rtMapByName.get('Partner Document').getRecordTypeId();

        List<ContentVersion> contentList = new List<ContentVersion>();

        ContentVersion partnerDocVersion = new ContentVersion(
                Title = 'Test Partner Doc',
                PathOnClient = 'document1.pdf',
                VersionData = Blob.valueOf('Test Partner Doc'),
                RecordTypeId = partnerDocRecordTypeId
        );
        insert partnerDocVersion;

        Partner_Document_Manager__c[] pdmList = new Partner_Document_Manager__c[]{};

        Partner_Document_Manager__c pdmInactive = new Partner_Document_Manager__c(
                ContentDocumentId__c = '069xxxxxxxxxxxxx01',
                Title__c = 'Test Partner Doc - Inactive',
                LatestVersionId__c = partnerDocVersion.Id,
                FileType__c = 'pdf',
                Active__c = false,
                All_Accounts__c = false,
                Partner_Type__c = null
        );
        pdmList.add(pdmInactive);

        Partner_Document_Manager__c pdmAllAccount = new Partner_Document_Manager__c(
                ContentDocumentId__c = '069xxxxxxxxxxxxx02',
                Title__c = 'Test Partner Doc - All accounts',
                LatestVersionId__c = partnerDocVersion.Id,
                FileType__c = 'pdf',
                Active__c = true,
                All_Accounts__c = true,
                Partner_Type__c = null
        );
        pdmList.add(pdmAllAccount);

        Partner_Document_Manager__c pdmReferral = new Partner_Document_Manager__c(
                ContentDocumentId__c = '069xxxxxxxxxxxxx03',
                Title__c = 'Test Partner Doc - Referral Partner',
                FileType__c = 'xslx',
                Active__c = true,
                All_Accounts__c = false,
                Partner_Type__c = 'Referral'
        );
        pdmList.add(pdmReferral);

        Partner_Document_Manager__c pdmPartner = new Partner_Document_Manager__c(
                ContentDocumentId__c = '069xxxxxxxxxxxxx04',
                Title__c = 'Test Partner Doc - Partner account',
                LatestVersionId__c = partnerDocVersion.Id,
                FileType__c = 'pdf',
                Active__c = true,
                All_Accounts__c = false,
                Partner_Type__c = null
        );
        pdmList.add(pdmPartner);

        insert pdmList;

        Partner_Document_Access__c pdmAccess = new Partner_Document_Access__c(
                Partner_Document_Manager__c = pdmList[3].Id,
                Account__c = testAccount.Id
        );
        insert pdmAccess;

    }

/*
    static void createContentVersion(){

        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName();
        ID partnerDocRecordTypeId = rtMapByName.get('Partner Document').getRecordTypeId();

        List<ContentVersion> contentList = new List<ContentVersion>();

        contentList.add(new ContentVersion(
                Title = 'Test Partner Doc - All accounts',
                PathOnClient = 'document1.pdf',
                VersionData = Blob.valueOf('Test Partner Doc - All accounts'),
                RecordTypeId = partnerDocRecordTypeId
        ));

        contentList.add(new ContentVersion(
                Title = 'Test Partner Doc - Referral partner',
                PathOnClient = 'document2.xslx',
                VersionData = Blob.valueOf('Test Partner Doc - Referral partner'),
                RecordTypeId = partnerDocRecordTypeId
        ));

        contentList.add(new ContentVersion(
                Title = 'Test Partner Doc - Partner Account',
                PathOnClient = 'spreadsheet.xslx',
                VersionData = Blob.valueOf('Test Partner Doc - Partner Account'),
                RecordTypeId = partnerDocRecordTypeId
        ));


        insert contentList;

    }
*/


}