/**
 * Created by mohandaas.rangaswamy on 2/28/2017.
 */

@IsTest
private class LeadTriggerHelperTest {

    static testMethod void testSharePartnerLeadsWithPartnerUser() {

        Map<String, Schema.RecordTypeInfo> accountRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'LeadTriggerHelperTest Partner',
                Type = 'Partner',
                RecordTypeId = accountRecordTypes.get('Partners').getRecordTypeId()
        );
        insert testAccount;

        Map<String, Schema.RecordTypeInfo> contactRecordTypes = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact testContact = new Contact(
                LastName = 'LeadTriggerHelperTest',
                Email = 'LeadTriggerHelperTest@incontact.com',
                RecordTypeId = contactRecordTypes.get('Partner Contact').getRecordTypeId(),
                AccountId = testAccount.Id
        );
        insert testContact;

        Profile partnerProfile = [SELECT Id from Profile where Name = 'Partner Community Profile'];
        User partnerUser = new User(
                FirstName = 'LeadTriggerHelperTest',
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

        Map<String, Schema.RecordTypeInfo> leadRecordTypes = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        test.startTest();
        Lead partnerLead = null;
        system.runAs(partnerUser){

            partnerLead = new Lead(
                    FirstName = 'Super',
                    LastName = 'Partner',
                    Title = 'CFO',
                    Company = 'My Inc',
                    Phone = '2002103300',
                    Status = 'Working',
                    Lead_Status_Detail__c = '1st attempt to contact',
                    Partner_Agent_Company__c = 'Not inContact',
                    Partner_Agent_First_Name__c = 'Super',
                    Partner_Agent_Last_Name__c = 'Agent',
                    Partner_Agent_Phone__c = '8001001111',
                    Partner_Agent_Email__c = 'agent@notincontact.com',
                    RecordTypeId = leadRecordTypes.get('Prospect').getRecordTypeId()
            );
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.AssignmentRuleHeader.useDefaultRule = true;
            partnerLead.setOptions(dmo);
            insert partnerLead;
        }
        test.stopTest();

        system.runAs(partnerUser){
            List<Lead> leadList = [
                    Select Id from Lead
                    where Id = :partnerLead.Id
            ];
            system.assertEquals(1, leadList.size(), 'Partner User should have access to Lead even if it was re-assigned.');
        }

    } // end of testSharePartnerLeadsWithPartnerUser()

    static testMethod void testLeadStatusUpdate() {

        Map<String, Schema.RecordTypeInfo> leadRecordTypes = Schema.SObjectType.Lead.getRecordTypeInfosByName();

        Lead partnerLead = new Lead(
                FirstName = 'Super',
                LastName = 'Partner',
                Title = 'CFO',
                Company = 'My Inc',
                Status = 'New',
                Phone = '2002103300',
                Partner_Agent_Company__c = 'Not inContact',
                Partner_Agent_First_Name__c = 'Super',
                Partner_Agent_Last_Name__c = 'Agent',
                Partner_Agent_Phone__c = '8001001111',
                Partner_Agent_Email__c = 'agent@notincontact.com',
                RecordTypeId = leadRecordTypes.get('Prospect').getRecordTypeId()
        );
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        partnerLead.setOptions(dmo);
        insert partnerLead;

        test.startTest();
        partnerLead.Status = 'Open';
        update partnerLead;
        test.stopTest();

        LeadDetailTracking__c[] leadDetailTrackingList = [
                SELECT Lead__c, LeadStatus__c
                FROM LeadDetailTracking__c
                WHERE Lead__c =  :partnerLead.Id
                order by CreatedDate desc
        ];
        system.assert(leadDetailTrackingList.size() > 0, 'Lead Detail Tracking record was not created.');
        system.assertEquals(partnerLead.Status, leadDetailTrackingList[0].LeadStatus__c);

    } // end of testLeadStatusUpdate()

}