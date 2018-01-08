/**
 * Created by ravish.chawla on 1/2/2018.
 */

@IsTest
private class CaseEventCloseExtensionTest {

    private static void createSiteConfig()
    {
        SiteConfiguration__c sbx = new SiteConfiguration__c();
        sbx.Name = inContactBaseClass.OrgId15Digit;
        sbx.AutoEventEmails__c = true;
        sbx.DaysToDisplayKnownIssues__c = 30;
        sbx.OrgId__c = inContactBaseClass.OrgId15Digit;
        sbx.EventResolvedPriorities__c = 'P1;P2;';
        sbx.EventResolvedEmails__c = true;

        insert sbx;



    }

    static testMethod void TestCaseEventCloseExtension()
    {
        createSiteConfig();

        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        //Get Event record type id
        Id eventRecordType = rtMapByName.get('Event').getRecordTypeId();
        Id incidentRecordType = rtMapByName.get('Incident').getRecordTypeId();

        //create test account
        Account a = new Account();
        a.Name = 'testName';
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();

        insert a;
        System.debug('Insert accounts.');

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
        ct.AccountId = a.Id;

        insert ct;

        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;


        //create test case
        Case c = new Case();
        c.AccountId = a.Id;
        c.Subject = a.Name;
        c.Description = 'test';
        c.ContactId = ct.Id;
        c.RecordTypeId = eventRecordType;
        c.EventCommander__c = UserInfo.getUserId();
        c.Request_Type__c = 'Billing Issues';
        c.Product_or_Service__c = 'DIA';
        c.PlatformsImpacted__c = 'C6 - inContact';
        c.ProductImpacted__c = 'ACD';
        c.Status = 'New';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';

        c.setOptions(dmo);

        insert c;

        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'ACD';
        pem.Product__c = 'ACD';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

        c = [SELECT RecordTypeId, CaseNumber, Status, Priority, Subject, Description, ProductImpacted__c, PlatformsImpacted__c FROM Case WHERE ID = :c.Id];


        //set default assignment rule
        database.DMLOptions dmo2 = new database.DMLOptions();
        dmo2.assignmentRuleHeader.useDefaultRule = true;

        //create incident test case
        Case c2 = new Case();
        c2.AccountId = a.Id;
        c2.Subject = a.Name;
        c2.ContactId = ct.Id;
        c2.RecordTypeId = incidentRecordType;
        c2.Request_Type__c = 'Adds/Moves/Changes';
        c2.Product_or_Service__c = 'DIA';
        c2.Status = 'New';
        c2.Freqeuncy__c = 'Occasional';
        c2.Number_of_Customers_Affected__c = '1';
        c2.Severity__c = 'S4';
        c2.ParentId = c.Id;
        c2.SystemClosed__c = true;

        c2.setOptions(dmo2);

        insert c2;

        Test.startTest();
        //Test StandardTextExtension
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(c);
        CaseEventCloseExtension cecExt = new CaseEventCloseExtension(stdCtrl);

        cecExt.PublicComment = 'Test public comment.';
        cecExt.renderComment = true;
        cecExt.noText = true;
        List<selectOption> rto = cecExt.RecordTypeOptions;
        string comment = cecExt.PublicComment;
        List<selectOption> sto = cecExt.StandardTextOptions;
        Boolean rcp = cecExt.RenderClosePage;
        String sst = cecExt.SelectedStandardText;
        Id srtId = cecExt.SelectedRecordTypeId;
        cecExt.Save();
        cecExt.Cancel();


        Test.stopTest();
    }
}