/**
 * Created by jeremy.sparrell on 5/9/2018.
 */

@IsTest
private class NewBusinessUnitRequestExtentionTest {
    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String OPPORTUNITY_TYPE_NEW = 'New Opportunity';
    //static final String OPPORTUNITY_TYPE_PS = 'PS Opportunity';

    static final Set<String> recordTypeSet = new Set<String>
    {
            ACCOUNT_TYPE_CUSTOMERS,
            OPPORTUNITY_TYPE_NEW
    };
    static Map<String, Id> recordTypeMap = null;

    static List<Account> accountList = null;
    static Contact testContact = null;
    static Contract testContract = null;


    static testMethod void FormNotRenderedTest() {
        createTestData();
        testContract.ContractType__c = 'Test';
        update testContract;

        Test.startTest();
        NewBusinessUnitRequestExtension buExt = new NewBusinessUnitRequestExtension(new ApexPages.Standardcontroller(testContract));

        Test.stopTest();
        system.assert(!buExt.renderForm);
    }

    static testMethod void NotAllRequiredInfoFilledOut() {
        createTestData();

        Test.startTest();
        NewBusinessUnitRequestExtension buExt = new NewBusinessUnitRequestExtension(new ApexPages.Standardcontroller(testContract));
        try{
            buExt.SaveNewBusinessUnit();
        } catch(Exception ex){
            system.assertEquals(ex.getTypeName(), 'DmlException');
        }
        Test.stopTest();
    }

    static testMethod void CreateNewBusinessUnitTest() {
        createTestData();

        Test.startTest();
        NewBusinessUnitRequestExtension buExt = new NewBusinessUnitRequestExtension(new ApexPages.Standardcontroller(testContract));

        buExt.newOpportunity.Name = 'Test Opportunity';
        buExt.SaveNewBusinessUnit();

        Test.stopTest();

        List<Account> accountResult = [SELECT Id, Name, Geo_Code__c, Country_Code__c FROM Account WHERE Id != :accountList[0].Id];

        system.assertEquals(accountResult.size(),1);
        system.assertEquals(accountList[0].Name, accountResult[0].Name);
        system.assertEquals(accountList[0].Geo_Code__c, accountResult[0].Geo_Code__c);
        system.assertEquals(accountList[0].Country_Code__c, accountResult[0].Country_Code__c);

        List<Contact> contacts = [SELECT LastName, Email, Contact_Role__c FROM Contact WHERE Id != :testContact.Id];

        system.assertEquals(contacts.size(),1);
        system.assertEquals(testContact.LastName, contacts[0].LastName);
        system.assertEquals(testContact.Contact_Role__c, contacts[0].Contact_Role__c);

        List<Opportunity> opportunities = [SELECT Name, Contract_Type__c FROM Opportunity];
        system.assertEquals(opportunities.size(),1);
        system.assertEquals('Test Opportunity',opportunities[0].Name);

    }

    /* Create the test data required to execute the tests successfully */
    static void createTestData() {

        recordTypeMap = new Map<String, Id>();
        for (RecordType record : [
                Select Id, Name
                from RecordType
                where Name IN :recordTypeSet
        ]) {
            recordTypeMap.put(record.Name, record.Id);
        }
        createAccount();
        createContact();
        createContract();
    }

    static void createAccount()
    {
        accountList = new List<Account>();
        accountList.add(new Account(
                Name = 'NewBusinessUnitRequestExtentionTest Customer',
                Type = 'Customer',
                RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS),
                Geo_Code__c = 'AMERICAS',
                Country_Code__c = 'US'
        ));

        insert accountList;

    } // end of createAccount()

    static void createContact() {

        testContact = new Contact(
                LastName = 'NewBusinessUnitRequestExtentionTest Contact',
                Email = 'contact1@incontact.com',
                Contact_Role__c = 'Main',
                AccountId = accountList[0].Id
        );
        insert testContact;
    }

    static void createContract() {

        testContract = new Contract(
                Name = 'NewBusinessUnitRequestExtentionTest Contract',
                ContractType__c = 'Service Contract',
                AccountId = accountList[0].Id
        );
        insert testContract;
    }








}