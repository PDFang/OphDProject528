/**
 * Created by william.nelson on 9/19/2017.
 */
@IsTest
public with sharing class SubScriptionReplicaControllerTest {

    private static Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
    private static Account SetupData(){

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


        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(
                SBQQ__Account__c = testAccount.Id,
                SBQQ__Discount__c = 2.05,
                SBQQ__AdditionalDiscountAmount__c = 2500,
                SBQQ__Bundled__c = true,
                SBQQ__ListPrice__c = 50,
                SBQQ__Quantity__c = 200

        );
        insert subscription;
        return testAccount;
    }

    public static testMethod void GetAvailableSubscriptions(){

        Account acc = SetupData();

        ApexPages.currentPage().getParameters().put('id',acc.id);
        ApexPages.StandardController stdcont = new ApexPages.StandardController(acc);


        SubScriptionReplicaController controller = new SubScriptionReplicaController(stdcont);
        controller.GetSubscriptionReplicas(acc);
    }



}