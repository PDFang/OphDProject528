// moved from CaseEventTestClass

@IsTest
private class CaseEventNotificationExtensionTest {

    private static Case cNotification;

    static testMethod void TestCaseEventNotificationExtension()
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
        a.inContact_Cluster__c = 'C6';

        insert a;

        Contact con = inContactBaseClass.CreateContact(a.Id, 'test', 'test', 'test@test.com');
        con.Contact_Role__c = 'Event Notification';
        insert con;

        Opportunity o = new Opportunity();
        o.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Historical Products', 'Opportunity');
        o.Name = 'test';
        o.CloseDate = system.today().addDays(30);
        o.StageName = 'Open';
        o.AccountId = a.Id;

        insert o;

        ImplementedProduct__c ip = new ImplementedProduct__c();
        ip.Account__c = a.Id;
        ip.GoLiveDate__c = system.today().addMonths(- 4);
        ip.Product__c = 'inContact';
        ip.Opportunity__c = o.Id;
        ip.Status__c = 'Implemented';

        insert ip;

        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;

        //create test case
        Case c = new Case();
        c.Subject = 'Test Event';
        c.Description = 'test test';
        c.EventType__c = 'Service Disruption';
        c.RecordTypeId = eventRecordType;
        c.PlatformsImpacted__c = 'C6 - inContact';
        c.ProductImpacted__c = 'ACD';
        c.setOptions(dmo);
        insert c;

        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'ACD';
        pem.Product__c = 'ACD';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

        Standard_Text__c st = new Standard_Text__c();
        st.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Event Standard Text', 'Standard_Text__c');
        st.Name = 'Test';
        st.StandardText__c = 'test test';

        insert st;


        Case insertedCase = [SELECT Id, StartDateTimeUTC__c, CustomersMayExperienceTheFollowing__c, Description, InternalEvent__c, CustomerAction__c, Status, CaseNumber, OwnerId, Owner.Name, RecordTypeId, Subject, EventType__c, PlatformsImpacted__c, ProductImpacted__c FROM Case WHERE Id = :c.Id];

        Test.setMock(WebServiceMock.class, new INotificationProxy());

       //  NotificationHelperClass.futureCallout(new String[] { 'test@test.com' }, 'test', 'test', 'test', 3, '123');

        Test.startTest();

        ApexPages.StandardController eventCont = new ApexPages.StandardController(insertedCase);


        //test CaseEventAccountsExtension
        CaseEventNotificationExtension notify = new CaseEventNotificationExtension(eventCont);


        notify.EventAccounts();

        List<selectOption> rtList = notify.RecordTypeOptions;
        List<selectOption> stList = notify.StandardTextOptions;

        notify.selectedStandardTextId = stList[1].getValue();
        notify.UpdateStandardText();

        notify.emailBody = 'Test';
        notify.subject = 'test';
        notify.SendNotification();

        Test.stopTest();
    }

    static testMethod void TestMaintenanceNotificationViaXmatters(){

        createSiteConfig();

        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'inContact';
        pem.Product__c = 'inContact';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

        AppConfiguration__c config = new AppConfiguration__c();
        config.XM_Turn_Off_Maintenance_Notifications__c = false;
        insert config;

        //create test account
        Account a = inContactBaseClass.CreateAccount('Test');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
        a.inContact_Cluster__c = 'C6';

        insert a;

        Contact con = inContactBaseClass.CreateContact(a.Id, 'test', 'test', 'test@test.com');
        con.Contact_Role__c = 'Maintenance Notification';
        insert con;

        Opportunity o = new Opportunity();
        o.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Historical Products', 'Opportunity');
        o.Name = 'test';
        o.CloseDate = system.today().addDays(30);
        o.StageName = 'Open';
        o.AccountId = a.Id;

        insert o;

        ImplementedProduct__c ip = new ImplementedProduct__c();
        ip.Account__c = a.Id;
        ip.GoLiveDate__c = system.today().addMonths(- 4);
        ip.Product__c = 'inContact';
        ip.Opportunity__c = o.Id;
        ip.Status__c = 'Implemented';

        insert ip;


        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;

        //create Maintenance case
        Case testMaintenance = new Case(
                RecordTypeId = rtMapByName.get('Maintenance Notification').getRecordTypeId(),
                Subject = 'Test Maintenance Notification',
                Description = 'Test Maintenance Notification',
                Status = 'New',
                EventType__c = 'Service Disruption',
                PlatformsImpacted__c = 'C6 - inContact',
                ProductImpacted__c = 'inContact',
                InternalEvent__c = false,
                Priority = 'P1'
        );

        testMaintenance.setOptions(dmo);

        insert testMaintenance;


        Test.startTest();

        CaseEventNotificationExtension testExtension = new CaseEventNotificationExtension(new ApexPages.StandardController(testMaintenance));
        xMatters_Forms__mdt xmattersForm = [SELECT Form_Name__c FROM xMatters_Forms__mdt LIMIT 1];
        testExtension.xmSelectedForm = xmattersForm.Form_Name__c;
        testExtension.xmSelectedSendMethod = 'ByProducts';

        system.assertEquals(true, testExtension.enableXmatters, 'xMatters maintenance notification should be enabled.');
        system.assert(testExtension.xMattersFieldMapping.size() > 0, 'Case Field to xMatters form property mapping is empty.');

        testExtension.sendNotificationViaXmatters();

        Test.stopTest();

        List<xmNotification__c> xmNotifications = [Select Id from  xmNotification__c where Case__c = :testMaintenance.Id];
        system.assertEquals(1, xmNotifications.size(), 'Notification record should be created.');
    }

    static testMethod void TestGroupBatchNew()
    {
        createGroupBatchTestData();

        xmNotificationGroups__c xmNotificationGroup = new xmNotificationGroups__c(
                Case__c = cNotification.Id,
                Name = 'test',
                xmGroupUID__c = 'testID',
                Status__c = 'New'
        );

        Test.startTest();

        CaseEventNotificationExtension testExtension = new CaseEventNotificationExtension(new ApexPages.StandardController(cNotification));
        boolean disableGroupOption = testExtension.SendMethodOptions.get(0).getDisabled();

        Test.stopTest();

        System.assertEquals(true, disableGroupOption);
    }

    static testMethod void TestGroupBatchInProgress()
    {
        createGroupBatchTestData();

        xmNotificationGroups__c xmNotificationGroup = new xmNotificationGroups__c(
                Case__c = cNotification.Id,
                Name = 'test',
                xmGroupUID__c = 'testID',
                Status__c = 'In Progress'
        );

        Test.startTest();

        CaseEventNotificationExtension testExtension = new CaseEventNotificationExtension(new ApexPages.StandardController(cNotification));
        boolean disableGroupOption = testExtension.SendMethodOptions.get(0).getDisabled();

        Test.stopTest();

        System.assertEquals(true, disableGroupOption);
    }

    static testMethod void TestGroupBatchCompleted()
    {
        createGroupBatchTestData();

        xmNotificationGroups__c xmNotificationGroup = new xmNotificationGroups__c(
                Case__c = cNotification.Id,
                Name = 'test',
                xmGroupUID__c = 'testID',
                Status__c = 'Completed'
        );

        insert xmNotificationGroup;

        Test.startTest();

        CaseEventNotificationExtension testExtension = new CaseEventNotificationExtension(new ApexPages.StandardController(cNotification));
        boolean disableGroupOption = testExtension.SendMethodOptions.get(0).getDisabled();

        Test.stopTest();

        System.assertEquals(false, disableGroupOption);
    }

    static testMethod void TestGroupBatchFailed()
    {
        createGroupBatchTestData();

        xmNotificationGroups__c xmNotificationGroup = new xmNotificationGroups__c(
                Case__c = cNotification.Id,
                Name = 'test',
                xmGroupUID__c = 'testID',
                Status__c = 'Failed'
        );

        insert xmNotificationGroup;

        Test.startTest();

        CaseEventNotificationExtension testExtension = new CaseEventNotificationExtension(new ApexPages.StandardController(cNotification));
        boolean disableGroupOption = testExtension.SendMethodOptions.get(0).getDisabled();

        Test.stopTest();

        System.assertEquals(true, disableGroupOption);
    }

    static testMethod void TestRefreshBatchStatus()
    {
        createGroupBatchTestData();

        xmNotificationGroups__c xmNotificationGroup = new xmNotificationGroups__c(
                Case__c = cNotification.Id,
                Name = 'test',
                xmGroupUID__c = 'testID',
                Status__c = 'New'
        );

        insert xmNotificationGroup;

        Test.startTest();

        CaseEventNotificationExtension testExtension = new CaseEventNotificationExtension(new ApexPages.StandardController(cNotification));
        boolean disableGroupOptionNew = testExtension.SendMethodOptions.get(0).getDisabled();

        xmNotificationGroup.Status__c = 'Completed';
        update xmNotificationGroup;
        testExtension.RefreshPage();
        testExtension.refreshBatchStatus();

        Test.stopTest();

        boolean disableGroupOptionCompleted = testExtension.SendMethodOptions.get(0).getDisabled();
        System.assertEquals(true, disableGroupOptionNew);
        System.assertEquals(false, disableGroupOptionCompleted);
    }

    private static void createGroupBatchTestData()
    {
        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        Id eventRecordType = rtMapByName.get('Event').getRecordTypeId();

        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;

        cNotification = new Case(
                RecordTypeId = rtMapByName.get('Maintenance Notification').getRecordTypeId(),
                Subject = 'Test Maintenance Notification',
                Description = 'Test Maintenance Notification',
                Status = 'New',
                EventType__c = 'Service Disruption',
                PlatformsImpacted__c = 'C6 - inContact',
                ProductImpacted__c = 'inContact',
                InternalEvent__c = false,
                Priority = 'P1'
        );

        cNotification.setOptions(dmo);

        insert cNotification;
    }

    private static void createSiteConfig(){

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