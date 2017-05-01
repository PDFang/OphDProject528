/**
 * Created by arnab.karsarkar on 5/1/2017.
 */

@isTest
public class ContactTriggerHandlerTest {

    PRIVATE static Contact ct;
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


    }


    public static testMethod void insertReferenceableActCheck(){
        setUpData();
        test.startTest();
        ct.Referenceable__c = true;
        insert ct;
        test.stopTest();

        Account act = [select Referenceable__c from Account Limit 1];
        system.assertEquals(true, act.Referenceable__c);
    }

    public static testMethod void updateReferenceableActCheck(){

        setUpData();
        insert ct;
        test.startTest();
        ct.Referenceable__c = true;
        update ct;
        test.stopTest();
        Account act = [select Referenceable__c from Account Limit 1];
        system.assertEquals(true, act.Referenceable__c);
    }

    public static testMethod void removeReferenceableActCheck(){

        setUpData();

        test.startTest();
        ct.Referenceable__c = true;
        insert ct;

        ct.Referenceable__c = false;
        update ct;
        test.stopTest();
        Account act = [select Referenceable__c from Account Limit 1];
        system.assertEquals(false, act.Referenceable__c);
    }



}