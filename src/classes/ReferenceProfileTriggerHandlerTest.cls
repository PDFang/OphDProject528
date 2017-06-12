/**
 * Created by ravish.chawla on 6/12/2017.
 */

@IsTest
private class ReferenceProfileTriggerHandlerTest {

    PRIVATE static Contact ct;
    PRIVATE static refedge__Reference_Basic_Information__c refProfile;
    private static void setUpData(){
        Id rtCustOther = '01270000000Lrn4AAC';
        ct = new Contact();
        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'testCalculateAccountNetScore Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                IsPartner__c = false,
                CustomerSegment__c = 'Strategic',
                Brand_Visibility__c = 'Yes',
                Industry_Leadership_Vocality__c = 'Yes',
                Social_Media_Presence__c = 'Yes',
                Risk_of_Leaving__c = 'Low',
                Referenceable__c = false,
                GYRStatus__c = 'Green'
        );

        insert testAccount;

        //create contact
        ct = inContactBaseClass.CreateContact(testAccount.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
        insert ct;

        refProfile = new refedge__Reference_Basic_Information__c(
                refedge__Account__c = testAccount.Id,
                refedge__Contact__c = ct.Id
        );




    }


    public static testMethod void insertReferenceableAccountCheck() {
        setUpData();
        test.startTest();
        refProfile.refedge__Is_Referenceable__c = true;
        refProfile.refedge__Referenceability_Status__c = 'Active';
        insert refProfile;
        test.stopTest();

        Account act = [select Referenceable__c from Account Limit 1];
        system.assertEquals(true, act.Referenceable__c);

    }

    public static testMethod void updateReferenceableActCheck(){

        setUpData();
        insert refProfile;
        test.startTest();
        refProfile.refedge__Is_Referenceable__c = true;
        refProfile.refedge__Referenceability_Status__c = 'Active';
        update refProfile;
        test.stopTest();
        Account act = [select Referenceable__c from Account Limit 1];
        system.assertEquals(true, act.Referenceable__c);
    }

    public static testMethod void removeReferenceableActCheck(){

        setUpData();

        test.startTest();
        refProfile.refedge__Is_Referenceable__c = true;
        refProfile.refedge__Referenceability_Status__c = 'Active';
        insert refProfile;

        refProfile.refedge__Is_Referenceable__c = true;
        refProfile.refedge__Referenceability_Status__c = 'Caution';
        update refProfile;
        test.stopTest();
        Account act = [select Referenceable__c from Account Limit 1];
        system.assertEquals(false, act.Referenceable__c);
    }

    public static testMethod void removeReferenceableActCheck1(){

        setUpData();

        test.startTest();
        refProfile.refedge__Is_Referenceable__c = true;
        refProfile.refedge__Referenceability_Status__c = 'Caution';
        insert refProfile;

        refProfile.refedge__Is_Referenceable__c = true;
        refProfile.refedge__Referenceability_Status__c = 'Active';
        update refProfile;
        test.stopTest();
        Account act = [select Referenceable__c from Account Limit 1];
        system.assertEquals(true, act.Referenceable__c);
    }
}