@isTest
private class CaseEventTestClass {

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


    static testMethod void TestinContactIVRWebServices_HasCustomerPriorityOneEvent()
    {
        createSiteConfig();

        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        Map<ID, Schema.RecordTypeInfo> recordTypeMapById = d.getRecordTypeInfosByID();

        //Get Event record type id
        Id eventRecordType = rtMapByName.get('Event').getRecordTypeId();

        //Create a new Account object
        Account acct = inContactBaseClass.CreateAccount('Test Account');
        acct.CadebillAccountNo__c = 9999999;
        acct.inContact_Cluster__c = 'C6';
        insert acct;

        Opportunity o = new Opportunity();
        o.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Historical Products', 'Opportunity');
        o.Name = 'test';
        o.CloseDate = system.today().addDays(30);
        o.StageName = 'Open';
        o.AccountId = acct.Id;

        insert o;

        ImplementedProduct__c ip = new ImplementedProduct__c();
        ip.Account__c = acct.Id;
        ip.GoLiveDate__c = system.today() - 1;
        ip.Status__c = 'Implemented';
        ip.Product__c = 'inContact';
        ip.Opportunity__c = o.Id;
        insert ip;


        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'ACD';
        pem.Product__c = 'ACD';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

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
        c.InternalEvent__c = false;
        c.Priority = 'P1';
        c.Description = 'Description';


        c.setOptions(dmo);

        insert c;


        ApexPages.StandardController eventCont = new ApexPages.StandardController(c);

        //test CaseConfirmEventExtension
        CaseConfirmEventExtension confirmExt = new CaseConfirmEventExtension(eventCont);

        confirmExt.ConfirmEvent();

        Test.startTest();
        boolean actual = inContactIVRWebServices.HasCustomerPriorityOneEvent(string.valueOf(acct.CadebillAccountNo__c));
        //system.assert(actual);
        Test.stopTest();
    }


    static testMethod void TestCaseConfirmEventExtension()
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

        ApexPages.StandardController eventCont = new ApexPages.StandardController(c);

        //test CaseConfirmEventExtension
        CaseConfirmEventExtension confirmExt = new CaseConfirmEventExtension(eventCont);

        confirmExt.ConfirmEvent();
        confirmExt.RejectEvent();
        //confirmExt.ConfirmEvent();


    }

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
    }

    static testMethod void TestCaseEventBannerExtension()
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

        c.setOptions(dmo);
        insert c;

        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'ACD';
        pem.Product__c = 'ACD';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

        ApexPages.StandardController eventCont = new ApexPages.StandardController(c);

        //test CaseEventAccountsExtension
        CaseEventBannerExtension banner = new CaseEventBannerExtension(eventCont);

        //banner.allowNotifications = true;
        banner.Blank();
        c.IgnoreEventStatusLock__c = true;
        banner.ChatRoomEmail();
        banner.Confirm();
        //banner.renderForm = true;
        ApexPages.currentPage().getHeaders().put('Host', 'http://test.com');
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
        cecExt.Save();

        Test.stopTest();
    }

    static testMethod void TestCaseEventLogExtension()
    {
        createSiteConfig();

        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        Map<ID, Schema.RecordTypeInfo> recordTypeMapById = d.getRecordTypeInfosByID();

        //Get Event record type id
        Id eventRecordType = rtMapByName.get('Event').getRecordTypeId();


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

        c.setOptions(dmo);
        insert c;

        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'ACD';
        pem.Product__c = 'ACD';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

        ApexPages.StandardController eventCont = new ApexPages.StandardController(c);

        //test CaseEventAccountsExtension
        CaseEventLogExtension log = new CaseEventLogExtension(eventCont);

        EventSidebarController esc = new EventSidebarController();
    }

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

    static testMethod void TestNotificationProxy()
    {

        Test.setMock(WebServiceMock.class, new INotificationProxy());

        String testResult = NotificationHelperClass.GenerateEmail(new String[] { 'test@test.com' }, 'test', 'test', 'test', 3);

    }

    static testMethod void TestCaseEventStatusChangeExtension()
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
        c.Request_Type__c = 'Adds/Moves/Changes';
        c.Product_or_Service__c = 'DIA';
        c.ProductImpacted__c = 'inContact';
        c.PlatformsImpacted__c = 'C4';
        c.Status = 'New';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';

        c.setOptions(dmo);

        insert c;

        c = [SELECT CaseNumber, Status, Subject, Description, ProductImpacted__c, PlatformsImpacted__c FROM Case WHERE ID = :c.Id];

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

        c2.setOptions(dmo2);

        insert c2;

        //Test StandardTextExtension
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(c);
        CaseEventStatusChangeExtension cecExt = new CaseEventStatusChangeExtension(stdCtrl);


        List<Case> cCases = cecExt.ChildCaseList;
        List<SelectOption> eventStatuses = cecExt.EventStatus;
        cecExt.Save();

        cecExt.SelectedStandardText = 'test comment';
        string comment = cecExt.SelectedStandardText;

        List<selectOption> es = cecExt.EventStatus;
        List<selectOption> rto = cecExt.RecordTypeOptions;
        List<selectOption> sto = cecExt.StandardTextOptions;
        cecExt.SelectedRecordTypeId = rto[1].getValue();
        Id rtId = cecExt.SelectedRecordTypeId;
        c.Status = 'TEST';
        
        boolean sendResolvedEmailVisible = cecExt.ShowSendEventResolvedEmail;
        boolean getCurrentSendEmail = cecExt.SetSendEventResovledEmail;
        

        cecExt.Save();
        cecExt.RefreshPage();
    }

    static testMethod void TestRCAButtonBannerExtension()
    {
        createSiteConfig();

        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        Map<ID, Schema.RecordTypeInfo> recordTypeMapById = d.getRecordTypeInfosByID();

        //Get Event record type id
        Id eventRecordType = rtMapByName.get('Event').getRecordTypeId();
        Id incidentRecordType = rtMapByName.get('Incident').getRecordTypeId();

        //create test account
        Account a = inContactBaseClass.CreateAccount('Test');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
        a.CSM__c = UserInfo.getUserId();
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
        c.EventType__c = 'Service Disruption';
        c.RecordTypeId = eventRecordType;
        c.PlatformsImpacted__c = 'C6 - inContact';
        c.ProductImpacted__c = 'ACD';
        c.EventCommander__c = UserInfo.getUserId();

        c.setOptions(dmo);
        insert c;

        Case child = inContactBaseClass.CreateCase(a.Id, con.Id, incidentRecordType, 'test child');
        child.ParentId = c.Id;

        child.setOptions(dmo);
        insert child;

        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'ACD';
        pem.Product__c = 'ACD';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

        RCA__c rca = new RCA__c();
        rca.Event__c = c.Id;

        insert rca;

        Test.startTest();

        ApexPages.StandardController eventCont = new ApexPages.StandardController(rca);

        //test CaseEventAccountsExtension
        RCAButtonBannerExtension buttonExt = new RCAButtonBannerExtension(eventCont);

        buttonExt.OpenRCA();
        buttonExt.EditRFE();
        buttonExt.Publish();
        buttonExt.CloseNonEvent();

        Test.stopTest();
    }

    static testMethod void TestRCALoadEventSummaryExtension()
    {
        createSiteConfig();

        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        Map<ID, Schema.RecordTypeInfo> recordTypeMapById = d.getRecordTypeInfosByID();

        //Get Event record type id
        Id eventRecordType = rtMapByName.get('Event').getRecordTypeId();
        Id incidentRecordType = rtMapByName.get('Incident').getRecordTypeId();

        //create test account
        Account a = inContactBaseClass.CreateAccount('Test');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
        a.CSM__c = UserInfo.getUserId();
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
        c.EventType__c = 'Service Disruption';
        c.RecordTypeId = eventRecordType;
        c.PlatformsImpacted__c = 'C6 - inContact';
        c.ProductImpacted__c = 'ACD';
        c.EventCommander__c = UserInfo.getUserId();

        c.setOptions(dmo);
        insert c;

        Case child = inContactBaseClass.CreateCase(a.Id, con.Id, incidentRecordType, 'test child');
        child.ParentId = c.Id;

        child.setOptions(dmo);
        insert child;

        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'ACD';
        pem.Product__c = 'ACD';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

        RCA__c rca = new RCA__c();
        rca.Event__c = c.Id;
        rca.CustomerAdvocate__c = UserInfo.getUserId();

        insert rca;

        ApexPages.StandardController eventCont = new ApexPages.StandardController(rca);

        //test CaseEventAccountsExtension
        RCALoadEventSummaryExtension summary = new RCALoadEventSummaryExtension(eventCont);

        summary.Save();


    }

    static testMethod void TestRCARFEPageExtension()
    {
        createSiteConfig();

        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        Map<ID, Schema.RecordTypeInfo> recordTypeMapById = d.getRecordTypeInfosByID();

        //Get Event record type id
        Id eventRecordType = rtMapByName.get('Event').getRecordTypeId();
        Id incidentRecordType = rtMapByName.get('Incident').getRecordTypeId();

        //create test account
        Account a = inContactBaseClass.CreateAccount('Test');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
        a.CSM__c = UserInfo.getUserId();
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
        c.EventType__c = 'Service Disruption';
        c.RecordTypeId = eventRecordType;
        c.PlatformsImpacted__c = 'C6 - inContact';
        c.ProductImpacted__c = 'ACD';
        c.EventCommander__c = UserInfo.getUserId();

        c.setOptions(dmo);
        insert c;

        Case child = inContactBaseClass.CreateCase(a.Id, con.Id, incidentRecordType, 'test child');
        child.ParentId = c.Id;

        insert child;

        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'ACD';
        pem.Product__c = 'ACD';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

        RCA__c rca = new RCA__c();
        rca.Event__c = c.Id;
        rca.CustomerAdvocate__c = UserInfo.getUserId();

        insert rca;

        ApexPages.StandardController eventCont = new ApexPages.StandardController(rca);

        //test CaseEventAccountsExtension
        RCARFEPageExtension rfe = new RCARFEPageExtension(eventCont);

        rfe.Save();


    }
        //@isTest(SeeAllData=true)
    static testMethod void TestTrustWebService()
    {
        createSiteConfig();

        Schema.DescribeSObjectResult d = Schema.SObjectType.Account;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        //Get Event record type id
        Id partnerRecordType = rtMapByName.get('Resell Partner').getRecordTypeId();
        Id partnerCustomerRecordType = rtMapByName.get('Resell Customers').getRecordTypeId();


        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'ACD';
        pem.Product__c = 'ACD';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

        ProductEventMap__c esn = new ProductEventMap__c();
        esn.Name = 'ESN';
        esn.Product__c = 'ESN';
        esn.Platform__c = 'Intelligent Network';
        esn.AllCustomers__c = true;

        insert esn;

        ProductEventMap__c pemVerint = new ProductEventMap__c();
        pemVerint.Name = 'WFM 2.0';
        pemVerint.Product__c = 'WFM 2.0';
        pemVerint.ImplementedProduct__c = 'WFM 2.0';
        pemVerint.Platform__c = 'Cluster - WFO';
        pemVerint.HasClusters__c = true;

        insert pemVerint;

        Account partnerAccount = inContactBaseClass.CreateAccount('partner-account', partnerRecordType);
        partnerAccount.CadebillAccountNo__c = 100002;
        partnerAccount.Emerging_Channel_Type__c = 'Alliance Partner';
        insert partnerAccount;

        Account partnerCustomer = inContactBaseClass.CreateAccount('resell-customer', partnerCustomerRecordType);
        partnerCustomer.CadebillAccountNo__c = 100001;
        partnerCustomer.inContact_Cluster__c = 'C6';
        partnerCustomer.Verint_Cluster__c = 'V1';
        partnerCustomer.ParentId = partnerAccount.Id;
        insert partnerCustomer;

        Opportunity o = new Opportunity();
        o.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Historical Products', 'Opportunity');
        o.Name = 'test';
        o.CloseDate = system.today().addDays(30);
        o.StageName = 'Open';
        o.AccountId = partnerCustomer.Id;

        insert o;

        ImplementedProduct__c ip = new ImplementedProduct__c();
        ip.Account__c = partnerCustomer.Id;
        ip.Opportunity__c = o.Id;
        ip.GoLiveDate__c = system.today() - 1;
        ip.Status__c = 'Implemented';
        ip.Product__c = 'inContact';
        insert ip;

        ImplementedProduct__c ip1 = new ImplementedProduct__c
        (
            Account__c = partnerCustomer.Id,
            Opportunity__c = o.Id,
            GoLiveDate__c = system.today() - 1,
            Status__c = 'Implemented',
            Product__c = 'WFM 2.0'  
        );

        insert ip1;

        List<inContactTrustWebService.MaintenanceNotification> notifications = inContactTrustWebService.SelectMaintenanceNotificationsByCustomerAndDates(100001, system.today() - 30, system.today());
        inContactTrustWebService.EventNodeList nodeList = inContactTrustWebService.SelectEventsByNodeAndDate('inContact', system.today() - 7);
        inContactTrustWebService.CustomerNodeEvents testNodeEvents = inContactTrustWebService.SelectTrustNodesByCustomerAndDaysBack(100001, 30);
        testNodeEvents = inContactTrustWebService.SelectTrustNodesByCustomerAndDaysBack(100002, 30);
        inContactTrustWebService.TrustNode[] tNode = inContactTrustWebService.SelectIntelligentNetworkEvents(30);
        List<Case> knonwIssues = inContactTrustWebService.SelectKnownIssuesByCustomer(100001, '');

        inContactTrustWebService.TrustNode trustNode = new inContactTrustWebService.TrustNode(system.now(), system.now(), 'case-id', 'node', 'type');
        inContactTrustWebService.MaintenanceNotification maintenanceNotification = new inContactTrustWebService.MaintenanceNotification(system.now(), system.now(), 'subjectCon', 'descriptionCon', 'eventTypeCon', 'carrierCon', 'platformCon', 'cNumber', 'productImpacted');
        inContactTrustWebService.KnownIssue knownIssue = new inContactTrustWebService.KnownIssue(system.now(), system.now(), 'subjectCon', 'summaryCon', 'recreateStepsCon', 'workAroundCon', 'statusCon', 'cNumber');
    }
    static testMethod void Test_ConsoleEventActions()
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
        c.Request_Type__c = 'Adds/Moves/Changes';
        c.Product_or_Service__c = 'DIA';
        c.ProductImpacted__c = 'inContact';
        c.PlatformsImpacted__c = 'C4';
        c.Status = 'New';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';

        c.setOptions(dmo);

        insert c;

        CaseComment cc = new CaseComment();
        cc.CommentBody = 'comment-body';
        cc.ParentId = c.Id;
        cc.IsPublished = true;

        insert cc;

        c = [SELECT CaseNumber, Status, Subject, Description, ProductImpacted__c, PlatformsImpacted__c FROM Case WHERE ID = :c.Id];

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

        c2.setOptions(dmo2);

        insert c2;

        Test.startTest();
        string eventLog = ConsoleRemoteActions.JsonEventLog(c.Id);
        string opentEvents = ConsoleRemoteActions.JsonOpenEvents();
        ConsoleRemoteActions.SetRelatedEvent(c.Id, c2.Id);
        ConsoleRemoteActions.SyncChildPriorities(c.Id, 'P2');
        ConsoleRemoteActions.ChatRoomEmail(c.Id);
        Test.stopTest();
    }

    // Provides setup for the test class by adding data
    private static void Setup()
    {
        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        Map<ID, Schema.RecordTypeInfo> recordTypeMapById = d.getRecordTypeInfosByID();

        Schema.DescribeSObjectResult OppDescribe = Schema.SObjectType.Opportunity;
        Map<string, Schema.RecordTypeInfo> recordTypeMapByIdOpp = oppDescribe.getRecordTypeInfosByName();
        //Get Event record type id
        Id eventRecordType = rtMapByName.get('Event').getRecordTypeId();
        Id incidentRecordType = rtMapByName.get('Incident').getRecordTypeId();
        Id opportunityRecordType = recordTypeMapByIdOpp.get('Historical Products').getRecordTypeId();
        List<Account> accounts = new List<Account> ();
        List<ImplementedProduct__c> implementedProducts = new List<ImplementedProduct__c> ();
        List<Opportunity> lstOpportunities = new List<Opportunity>();
        
            Account accountRecord = inContactBaseClass.CreateAccount('Test Account');
            accountRecord.Site = 'Test';
            accountRecord.CS_AM__c = UserInfo.getUserId();
            accountRecord.inContact_Cluster__c = 'C6';
            accountRecord.CadebillAccountNo__c = 99999;
            accountRecord.Verint_Cluster__c = 'V2';
        
            Database.insert(accountRecord, false);
            Opportunity opp 
                        = new Opportunity(
                                          Name = 'Opportunity test',
                                          AccountId = accountRecord.Id,
                                          CloseDate = System.today(),
                                          StageName = 'Completed',
                                          RecordTypeId =opportunityRecordType
                                          );
            
            Database.insert(opp, false);    
            
            ImplementedProduct__c ip1 = new ImplementedProduct__c
            (
             Account__c = opp.AccountId,
             Opportunity__c = opp.Id,
             GoLiveDate__c = system.today() - 1,
             Status__c = 'Implemented',
             Product__c = 'inContact'
            );
            insert ip1;
            ImplementedProduct__c ip2 = new ImplementedProduct__c
            (
             Account__c = opp.AccountId,
             Opportunity__c = opp.Id,
             GoLiveDate__c = system.today() - 1,
             Status__c = 'Implemented',
             Product__c = 'WFM 2.0'
            );
            insert ip2;
        
        //set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;

        //create test case      
        Case caseRecordInContact = new Case
        (
         Subject = 'Test Event Incontact',
         EventType__c = 'Service Disruption',
         RecordTypeId = eventRecordType,
         PlatformsImpacted__c = 'C6 - inContact',
         ProductImpacted__c = 'ACD',
         Status = 'New'
        );

        caseRecordInContact.setOptions(dmo);
        insert caseRecordInContact;

        Case caseRecordVerint = new Case
        (
         Subject = 'Test Event Verint',
         EventType__c = 'Service Disruption',
         RecordTypeId = eventRecordType,
         PlatformsImpacted__c = 'V2 - WFO',
         ProductImpacted__c = 'WFM 2.0',
         Status = 'New'
        );
    
        caseRecordVerint.setOptions(dmo);
        insert caseRecordVerint;

        ProductEventMap__c productEventMapInContact = new ProductEventMap__c
        (
         Name = 'ACD',
         Product__c = 'ACD',
         ImplementedProduct__c = 'inContact',
         Platform__c = 'Cluster - inContact',
         HasClusters__c = true       
        );

        insert productEventMapInContact;

        ProductEventMap__c productEventMapVerint = new ProductEventMap__c
        (
         Name = 'WFM 2.0',
         Product__c = 'WFM 2.0',
         ImplementedProduct__c = 'WFM 2.0',
         Platform__c = 'Cluster - WFO',
         HasClusters__c = true
        );

        insert productEventMapVerint;
    }

    @isTest(SeeAllData=false)
    static void TestCaseEventAccountsExtensionVerint()
    {
        createSiteConfig();
        Setup();
        List<Account> lstAcct = new List<Account>();
        
        for (Case caseRecord: [SELECT Id, PlatformsImpacted__c, RecordTypeId, ProductImpacted__c  FROM Case])
        {
            lstAcct = new List<Account>();
            CaseEventClass cec = new CaseEventClass(caseRecord);
            lstAcct = cec.EventAccountList();
            System.assertEquals(1, lstAcct.size());

        }
    }
}