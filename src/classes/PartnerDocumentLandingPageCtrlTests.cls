@isTest
public class PartnerDocumentLandingPageCtrlTests {
    private void Setup(){

        Map<String, Schema.RecordTypeInfo> accountRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'DocumentSharing Partner',
                Type = 'Partner',
                RecordTypeId = accountRecordTypes.get('Partners').getRecordTypeId()
        );
        insert testAccount;

        Map<String, Schema.RecordTypeInfo> contactRecordTypes = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact testContact = new Contact(
                LastName = 'Partner',
                Email = 'PartnerDocummentTest@incontact.com',
                RecordTypeId = contactRecordTypes.get('Partner Contact').getRecordTypeId(),
                AccountId = testAccount.Id
        );
        insert testContact;

        Profile partnerProfile = [SELECT Id from Profile where Name = 'Partner Community Profile'];
        User partnerUser = new User(
                FirstName = 'Partner',
                LastName = 'User',
                ContactId = testContact.Id,
                Email = 'partner1@incontact.com',
                Username = 'partner1@incontact.com',
                Alias = 'test',
                profileId = partnerProfile.Id,
                EmailEncodingKey = 'UTF-8',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
        );
        insert partnerUser;
    }

    static testMethod void FilteringByPartnerTypes_ReturnsCorrecPartnerTypesforUser(){

        Partner_Document_Manager__c pdm = new Partner_Document_Manager__c();
        pdm.Active__c = true;
        pdm.All_Accounts__c = true;
        pdm.Title__c = 'My beautiful article';
    }
}