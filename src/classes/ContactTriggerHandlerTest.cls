@isTest
public class ContactTriggerHandlerTest {

    // validate person is deactivated when associated contact is deactivated
    static testMethod void testContactDeactivation(){

        Contact testContact = [
                Select Id, AccountId, xmPerson__c from Contact
                Where xmPerson__c != null Limit 1
        ][0];

        test.startTest();
        test.setMock(HttpCalloutMock.class, new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Id": "efrd-sqaw-123e-deft","Status":"INACTIVE"}]',null));
        testContact.Deactivated__c = true;
        update testContact;
        test.stopTest();

        List<xmGroupChangeRequestHeader__c> requestList = [
                Select Id from xmGroupChangeRequestHeader__c
                where sObjectId__c = :testContact.Id
                and Account__c = :testContact.AccountId
        ];
        system.assertEquals(1, requestList.size(), 'Should have created a group change request header.');

        system.assertEquals(true, ContactTriggerHandler.isValidatePersonStatusExecuted, 'Should have executed Contact trigger handler method.');
        system.assertEquals(true, ContactTriggerHandler.calloutXMRestPerson, 'Should have called xMatters REST API');

    }

    // validate person is deactivated when contact is disassociated
/*    static testMethod void testContactDisassociation(){

        Contact testContact = [
                Select Id, AccountId, xmPerson__c from Contact
                Where xmPerson__c != null Limit 1
        ][0];
        String xmPersonId = testContact.xmPerson__c;

        test.startTest();
        test.setMock(HttpCalloutMock.class, new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Id": "efrd-sqaw-123e-deft","Status":"INACTIVE"}]',null));
        testContact.xmPerson__c = null;
        update testContact;
        test.stopTest();

        List<xmGroupChangeRequestHeader__c> requestList = [
                Select Id from xmGroupChangeRequestHeader__c
                where sObjectId__c = :testContact.Id
                and Account__c = :testContact.AccountId
        ];
        system.assertEquals(1, requestList.size(), 'Should have created a group change request header.');

        system.assertEquals(true, ContactTriggerHandler.isValidatePersonStatusExecuted, 'Should have executed Contact trigger handler method.');
        system.assertEquals(true, ContactTriggerHandler.calloutXMRestPerson, 'Should have called xMatters REST API');

    }*/

    // validate person is deactivated when associated contact is deleted
    static testMethod void testContactDeletion(){

        Contact testContact = [
                Select Id, AccountId, xmPerson__c from Contact
                Where xmPerson__c != null Limit 1
        ][0];

        test.startTest();
        test.setMock(HttpCalloutMock.class, new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Id": "efrd-sqaw-123e-deft","Status":"INACTIVE"}]',null));
        delete testContact;
        test.stopTest();

        system.assertEquals(true, ContactTriggerHandler.isValidatePersonStatusExecuted, 'Should have executed Contact trigger handler method.');
        system.assertEquals(true, ContactTriggerHandler.calloutXMRestPerson, 'Should have called xMatters REST API');

    }

    @testSetup
    private static void setUpData(){

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'ContactTriggerHandlerTest Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId()
        );

        insert testAccount;

        xmPerson__c person = new xmPerson__c(
                xmPersonUID__c = 'efrd-sqaw-123e-deft'
        );
        insert person;

        Map<String,Schema.RecordTypeInfo> contactRecordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact testContact = new Contact(
                LastName = 'Contact',
                FirstName = 'ContactTriggerHandlerTest',
                Email = 'contact1@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = person.Id
        );

        insert testContact;
        testContact.xmPerson__c = person.Id;
        update testContact;

        Opportunity o = new Opportunity();
        o.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Historical Products', 'Opportunity');
        o.Name = 'test';
        o.CloseDate = system.today().addDays(30);
        o.StageName = 'Open';
        o.AccountId = testAccount.Id;

        insert o;

        ImplementedProduct__c ip1 = new ImplementedProduct__c();
        ip1.Account__c = testAccount.Id;
        ip1.GoLiveDate__c = system.today() - 1;
        ip1.Status__c = 'Implemented';
        ip1.Product__c = 'inContact';
        ip1.Opportunity__c = o.Id;
        insert ip1;


        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'inContact';
        pem.Product__c = 'inContact';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

    }

}