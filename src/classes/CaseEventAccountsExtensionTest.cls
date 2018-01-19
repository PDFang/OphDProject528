@IsTest
private class CaseEventAccountsExtensionTest {

    static testMethod void TestCaseEventAccountsExtension()
    {
        createSiteConfig();

        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        Map<ID, Schema.RecordTypeInfo> recordTypeMapById = d.getRecordTypeInfosByID();

        //Get Event record type id
        Id eventRecordType = rtMapByName.get('Event').getRecordTypeId();

        //create test account
        Account a = inContactBaseClass.CreateAccount('Test');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();

        insert a;


        //create test account
        Account aa = inContactBaseClass.CreateAccount('Test');
        aa.Site = 'Test';
        aa.CS_AM__c = UserInfo.getUserId();
        aa.inContact_Cluster__c = 'C6';

        insert aa;

        ImplementedProduct__c ip = new ImplementedProduct__c();
        ip.Account__c = aa.Id;
        ip.GoLiveDate__c = system.today() - 1;
        ip.Status__c = 'Implemented';
        ip.Product__c = 'inContact';


        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;

        //create test case
        Case c = new Case();
        c.Subject = 'Test Event';
        c.EventType__c = 'Service Disruption';
        c.RecordTypeId = eventRecordType;
        c.PlatformsImpacted__c = 'C6 - inContact';
        c.ProductImpacted__c = 'ACD';
        c.Status = 'New';


        c.setOptions(dmo);

        insert c;

        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'ACD';
        pem.Product__c = 'ACD';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

        Test.startTest();
        ApexPages.StandardController eventCont = new ApexPages.StandardController(c);

        //test CaseEventAccountsExtension
        CaseEventAccountsExtension acctsExt = new CaseEventAccountsExtension(eventCont);
        acctsExt.searchString = 'Test';
        acctsExt.AccountSearch();
        acctsExt.selectedAccount = a.Id;

        acctsExt.AddAccount();

        acctsExt.selectedAccountFromMasterList = a.Id;

        acctsExt.RemoveAccount();


        acctsExt.selectedAccountFromMasterList = aa.Id;
        acctsExt.RemoveAccount();
        acctsExt.selectedExcludedAccount = aa.Id;
        acctsExt.RemoveExclusion();

        acctsExt.previousPage();
        acctsExt.lastPage();
        acctsExt.firstPageS();
        acctsExt.nextPage();
        boolean getDisPrev = acctsExt.getDisablePrevious();
        boolean getDisNext = acctsExt.getDisableNext();
        integer getTotPages = acctsExt.getTotalPages();
        integer getPageNum = acctsExt.getPageNumber();
        integer getTotalSize = acctsExt.getTotal_size();
        Test.stopTest();
    }

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

}