/**
 * Created by ravish.chawla on 7/24/2017.
 */

@IsTest
private class CreateMaintNotificationControllerTest {

    static final String CUSTOMER_ACCOUNT = 'Customers';
    static final String CUSTOMER_CONTACT = 'Customer-Other';
    static Account testAccount;

    static testMethod void loadCaseDetailsTest(){

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();

        testAccount = new Account(
                Name = 'XMPersonManagementControllerTest Account',
                Type = 'Customer',
                CadebillAccountNo__c = 877124,
                RecordTypeId = accountRecordTypeMap.get(CUSTOMER_ACCOUNT).getRecordTypeId(),
                Cluster__c = 'C3'
        );
        insert testAccount;

        BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
        insert changeRequest;

        //get record type IDs
        Id rtIncident = '01270000000LuEpAAK';
        Id rtInfo = '01270000000LuEqAAK';
        Id rtWO = '01270000000LuErAAK';
        Id rtCustOther = '01270000000Lrn4AAC';

        //create contact
        Contact ct = new Contact();
        ct.LastName = 'LastName';
        ct.Email = 'test@test.com';
        ct.RecordTypeId = rtCustOther;
        ct.AccountId = testAccount.Id;

        insert ct;


        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;


        //create test case
        Case c = new Case();
        c.AccountId = testAccount.Id;
        c.Subject = testAccount.Name;
        c.Description = 'test';
        c.ContactId = ct.Id;
//        c.RecordTypeId = eventRecordType;
        c.Request_Type__c = 'Adds/Moves/Changes';
        c.Product_or_Service__c = 'DIA';
        c.ProductImpacted__c = 'inContact';
        c.PlatformsImpacted__c = 'C4';
        c.Status = 'New';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';
        c.RF_Change_Request__c = changeRequest.Id;

        c.setOptions(dmo);

        insert c;

        c = [SELECT CaseNumber, Status, Subject, Description, ProductImpacted__c, PlatformsImpacted__c FROM Case WHERE ID = :c.Id];


        Test.startTest();
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(changeRequest);
        CreateMaintenanceNotificationController createMainNotCon = new CreateMaintenanceNotificationController(stdCtrl);
        createMainNotCon.contactUsString = 'test';
        createMainNotCon.newCase.ProductImpacted__c = 'testProImpact';
        createMainNotCon.newCase.PlatformsImpacted__c = 'testPlatImpact';
        createMainNotCon.getContactInfo();
        createMainNotCon.goBack();
        createMainNotCon.createMaintenanceRecord();
        Case c1 = new Case();
        c1 = [SELECT CaseNumber, Status, Subject, Description, ProductImpacted__c, PlatformsImpacted__c FROM Case WHERE subject = :changeRequest.RF_Summary__c];

        system.assertNotEquals(createMainNotCon, null);
        system.assertNotEquals(c1, null);
        Test.stopTest();
    }
}