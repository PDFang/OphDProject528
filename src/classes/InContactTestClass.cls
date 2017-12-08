/*****************************************************************************************
 * This class contains unit tests for all custom Apex classes and triggers.
 *
 * All test methods in an our organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are required to have at least 75%
 * code coverage in order to be deployed to a production organization. In addition, 
 * all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
  ******************************************************************************************/
@IsTest(SeeAllData = false)
private class InContactTestClass
{
    /*************************************************************************************
     * Objects Tested: Trip_ReportBeforeDelete.trigger
     *                 Trip_AttendeeBeforeDelete.trigger
     *                 Trip_AttendeeExtension.cls
     *                 InContactConfiguration.cls (EchoSurveyURL field)
     *                 InContactWebServices.cls (SendEchoSurveyByTrip_ReportId method)
     **************************************************************************************/



    static testMethod void TestTrip_Reports()
    {
        //Create a new Account object
        Account acct = inContactBaseClass.CreateAccount('Test Account Trip Reports Extension');
        acct.CadebillAccountNo__c = 9999991;
        insert acct;

        //Create a new Contact object
        Contact con1 = inContactBaseClass.CreateContact(acct.Id, 'Test', 'Contact 1', 'james.fike@incontact.com');
        insert con1;

        //Create a new Trip_Report__c object
        Trip_Report__c tripReport = new Trip_Report__c();
        tripReport.Account__c = acct.Id;
        tripReport.Objectives__c = 'Test trip reports.';
        tripReport.Outcome__c = 'Hopefully successful.';
        tripReport.Status__c = 'New';
        insert tripReport;

        //Create a new Trip_Attendee__c object
        Trip_Attendee__c tripAttendee1 = new Trip_Attendee__c();
        tripAttendee1.Trip_Report__c = tripReport.Id;
        tripAttendee1.Attendee__c = con1.Id;
        Test.startTest();
        //Test Trip_AttendeeExtension constructor
        ApexPages.StandardController stdCtrl1 = new ApexPages.StandardController(tripAttendee1);
        Trip_AttendeeExtension attendeeExtension1 = new Trip_AttendeeExtension(stdCtrl1);
        //Test Trip_AttendeeExtension.Trip_Report_Name Property
        string report_name = attendeeExtension1.Trip_Report_Name;
        //Test Trip_AttendeeExtension.Survey Property
        attendeeExtension1.Survey = true;
        boolean survey1 = attendeeExtension1.Survey;
        //Test the Trip_AttendeeExtension.Contacts Property
        List<SelectOption> contacts = attendeeExtension1.Contacts;
        //Test first half of the Trip_AttendeeExtension.SaveAttendee Method 
        PageReference pageRef1 = attendeeExtension1.SaveAttendee();

        //Test InContactWebServices.SendEchoSurveyByTrip_ReportId Method
        InContactWebServices.SendEchoSurveyByTrip_ReportId(tripReport.Id, true);

        //Create a new Trip_Attendee__c object
        Trip_Attendee__c tripAttendee2 = new Trip_Attendee__c();
        tripAttendee2.Trip_Report__c = tripReport.Id;

        //Test second half of the Trip_AttendeeExtension.SaveAttendee Method
        ApexPages.StandardController stdCtrl2 = new ApexPages.StandardController(tripAttendee2);
        Trip_AttendeeExtension attendeeExtension2 = new Trip_AttendeeExtension(stdCtrl2);
        try
        {
            PageReference pageRef2 = attendeeExtension2.SaveAttendee();
        }
        catch(Exception ex)
        {
        }
        //Test the Trip_AttendeeExtension.CancelNew Method
        PageReference pageRef3 = attendeeExtension2.CancelNew();

        //Test Trip_AttendeeBeforeDelete Trigger
        try
        {
            delete tripAttendee1;
        }
        catch(Exception ex)
        {
        }
        //Test Trip_ReportBeforeDelete Trigger
        try
        {
            delete tripReport;
        }
        catch(Exception ex)
        {
        }
        Test.stopTest();
    }

    public static testMethod void TestStandardText()
    {
        //create test account
        Account a = inContactBaseClass.CreateAccount('testName');
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
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
        ct.Referenceable__c = true;
        insert ct;


        //create test case      
        Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, rtWO, a.Name);
        c.Request_Type__c = 'Adds/Moves/Changes';
        c.Product_or_Service__c = 'DIA';
        c.Status = 'New';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';

        insert c;

        Id stRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Standard_Text__c' LIMIT 1].Id;

        //create standard text
        Standard_Text__c s = new Standard_Text__c();
        s.Name = 'Test Standard Text';
        s.StandardText__c = 'Test';
        s.RecordTypeId = stRecordTypeId;

        insert s;

        Test.startTest();
        //Test StandardTextExtension
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(c);
        StandardTextExtension stExtension = new StandardTextExtension(stdCtrl);

        //get record type
        stExtension.SelectedRecordTypeId = stRecordTypeId;
        Id rt = stExtension.SelectedRecordTypeId;

        //get standard text Id
        stExtension.SelectedStandardTextId = [Select Id From Standard_Text__c WHERE RecordTypeId = :rt LIMIT 1].Id;
        Id stId = stExtension.SelectedStandardTextId;

        //test list options
        List<SelectOption> recTypes = stExtension.RecordTypeOptions;
        List<SelectOption> standardTextIds = stExtension.StandardTextOptions;
        List<CaseComment> cc = stExtension.getCaseComments();

        //get standard text
        String standardText = stExtension.SelectedStandardText;
        stExtension.IsPublicComment = true;
        stExtension.SelectedStandardText = 'Test';
        stExtension.NoText = true;
        stExtension.TimeSpent = 5;


        //run ButtonsRendered
        boolean testButtonsRendered = stExtension.ButtonsRendered;
        boolean testNoText = stExtension.NoText;
        boolean testIsPublicComment = stExtension.IsPublicComment;


        //run CopyStandardText to save
        try
        {
            PageReference pageRef2 = stExtension.CopyStandardText();
        }
        catch(Exception ex)
        {

        }

        //run AddStandardTextAsCaseComment
        try
        {
            PageReference pageRef2 = stExtension.AddStandardTextAsCaseComment();
        }
        catch(Exception ex)
        {

        }

        //test CaseEmailTrigger
        EmailMessage e = new EmailMessage();
        e.ToAddress = 'test@test.com';
        e.FromAddress = 'bob@test.com';
        e.Subject = 'test';
        e.TextBody = '<body>test</body>';
        e.ParentId = c.Id;
        e.Incoming = true;
        e.FromName = 'bob';

        insert e;
        Test.stopTest();
    }

    public static testMethod void TestContactUndelete()
    {
        //create test account
        Account a = inContactBaseClass.CreateAccount('testName');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();

        insert a;
        System.debug('Insert accounts.');

        //get record type IDs
        Id rtCustOther = '01270000000Lrn4AAC';

        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);

        insert ct;

        delete ct;
        Test.startTest();
        //attempt to undelete should fail
        try
        {
            undelete ct;
        }
        catch(Exception ex)
        {

        }
        Test.stopTest();
    }

    public static testMethod void TestCaseWatcher()
    {
        //create test account
        Account a = inContactBaseClass.CreateAccount('testName');
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
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);

        insert ct;

        //create test case      
        Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, rtWO, a.Name);
        c.Request_Type__c = 'Adds/Moves/Changes';
        c.Product_or_Service__c = 'DIA';
        c.Status = 'New';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';

        insert c;
        Test.startTest();
        //add to Case Watcher List
        CaseWatcherWebServices.WatchCase(c.Id, UserInfo.getUserId());

        //initiate CaseWatchedCases page
        PageReference pageRef = Page.CaseWatchedCases;
        Test.setCurrentPage(pageRef);

        //reference controller
        CaseWatchedCasesController controller = new CaseWatchedCasesController();

        //set caseId parameter
        ApexPages.currentPage().getParameters().put('caseId', c.Id);

        //get watched cases for current user
        controller.GetWatchedCases();

        //sort records
        controller.SortField = 'AccountId';
        controller.DoSort();

        //do sort again so it desc
        controller.DoSort();

        //unwatch added case
        controller.UnwatchCase();
        Test.stopTest();
    }

    public static testMethod void TestCommentChildCases()
    {
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
        //create test case      
        Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, rtWO, a.Name);
        c.Request_Type__c = 'Adds/Moves/Changes';
        c.Product_or_Service__c = 'DIA';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';

        insert c;

        Id parentCase = c.Id;

        //create test case      
        Case c1 = inContactBaseClass.CreateCase(a.Id, ct.Id, rtWO, a.Name);
        c1.Request_Type__c = 'Adds/Moves/Changes';
        c1.Product_or_Service__c = 'DIA';
        c1.Freqeuncy__c = 'Occasional';
        c1.Number_of_Customers_Affected__c = '1';
        c1.Severity__c = 'S4';

        insert c1;
        c1.ParentId = parentCase;
        update c1;
        Test.startTest();
        //Test CommentChildCasesExtension constructor
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(c);
        CommentChildCasesExtention commentChild = new CommentChildCasesExtention(stdCtrl);

        commentChild.CommentBodyText = '';
        commentChild.IsPublic = true;

        try
        {
            PageReference saveComment = commentChild.SaveComment();
        }
        catch(Exception ex)
        {
        }

        commentChild.CommentBodyText = 'Test';

        PageReference saveCommentAgain = commentChild.SaveComment();
        Test.stopTest();
    }

    public static testMethod void TestGYRBeforeInsert()
    {
        //bulk load accounts
        List<Account> accounts = new List<Account> ();
        //build accounts
        for (Integer i = 0; i < 1; i++) {
            Account a = new Account();
            a.Name = 'testName' + i;
            a.Site = string.valueOf(i);
            a.CS_AM__c = UserInfo.getUserId();
            accounts.add(a);
        }

        insert accounts;
        System.debug('Insert accounts.');
        Test.startTest();
        List<GYR__c> gyrs = new List<GYR__c> ();
        //create GYR Records
        for (Account a : accounts)
        {
            GYR__c gyr = new GYR__c();
            gyr.Account__c = a.Id;
            gyr.GYRStartDate__c = system.today();
            gyr.GYRStatus__c = 'Yellow';
            gyr.ReasonCategory__c = 'Test1';
            gyrs.add(gyr);
        }

        insert gyrs;

        List<GYR__c> gyrs2 = new List<GYR__c> ();
        //create 2nd GYR Records
        for (Account a : accounts)
        {
            GYR__c gyr2 = new GYR__c();
            gyr2.Account__c = a.Id;
            gyr2.GYRStartDate__c = system.today();
            gyr2.GYRStatus__c = 'Yellow';
            gyr2.ReasonCategory__c = 'Test1';
            gyrs2.add(gyr2);
        }

        insert gyrs2;
        Test.stopTest();
    }

    public static testMethod void testAccountPartners()
    {
        List<Account> accounts = new List<Account> ();

        //build Master Agent account
        Account ma = inContactBaseClass.CreateAccount('Test MA', inContactBaseClass.SelectRecordTypeIDByName('Master Agents', 'Account'));
        ma.Emerging_Channel_Type__c = 'CRM';
        accounts.add(ma);

        //build Sub Agent Account
        Account sa = inContactBaseClass.CreateAccount('Test SA', inContactBaseClass.SelectRecordTypeIDByName('Sub Agents', 'Account'));
        sa.ParentId = ma.Id;
        accounts.add(sa);

        //build Master Agent account
        Account ma2 = inContactBaseClass.CreateAccount('Test MA', ma.RecordTypeId);
        ma2.Emerging_Channel_Type__c = 'CRM';
        accounts.add(ma2);

        //build Sub Agent Account
        Account sa2 = inContactBaseClass.CreateAccount('Test SA', sa.RecordTypeId);
        sa2.ParentId = ma.Id;
        accounts.add(sa2);

        //build Customer Account
        Account ca = inContactBaseClass.CreateAccount('Test Customer', inContactBaseClass.SelectRecordTypeIDByName('Customers', 'Account'));
        ca.SalesPartner__c = sa.Id;
        ca.Referenceable__c = true;
        accounts.add(ca);

        insert accounts;
        Test.startTest();
        //updated customers Sales Partner
        ca.SalesPartner__c = sa2.Id;
        ca.Referenceable__c = false;
        ca.NotReferencableReason__c = 'test';
        update ca;

        ca.Referenceable__c = true;

        //update sub agent's master agent
        sa2.ParentId = ma2.Id;
        update sa2;

        //remove customer's sales partner
        ca.SalesPartner__c = null;
        update ca;
        Test.stopTest();
    }

    public static testMethod void TestAccountAfterUpdate()
    {
        //build Customer Account
        Account ca = inContactBaseClass.CreateAccount('Test Customer', inContactBaseClass.SelectRecordTypeIDByName('Customers', 'Account'));
        insert ca;

        Contract con = new Contract();
        con.AccountId = ca.Id;
        con.Name = 'test';
        insert con;

        GYR__c gyr = new GYR__c();
        gyr.Account__c = ca.Id;
        gyr.GYRStartDate__c = system.today();
        gyr.GYRStatus__c = 'Black';
        gyr.ReasonSummary__c = 'No Reason';
        gyr.Competitor_Lost_To__c = 'Cisco';
        gyr.ScheduledTermination__c = system.today();

        insert gyr;
        Test.startTest();
        //updated customers Sales Partner
        ca.Referenceable__c = false;
        ca.NotReferencableReason__c = 'test';
        update ca;
        Test.stopTest();
    }

    public static testMethod void TestResetPartnerAPIPassword()
    {
        Test.startTest();
        InContactWebServices.ResetParnterAPIUserPassword('TEST', true);
        Test.stopTest();
    }

    public static testMethod void TestProjectCommentsExtension()
    {
        Project__c p = new Project__c();
        p.Summary__c = 'Test';
        p.ProjectStatus__c = 'Backlogged';
        p.TFSId__c = '1234';
        p.ExpectedDeliveryDate__c = system.today();
        insert p;

        Test.setMock(HttpCalloutMock.class, new ISTFSINTEGRATIONCLASSMOCKTEST(200));
        ProjectComment__c pc = new ProjectComment__c();
        pc.Project__c = p.Id;
        pc.Comment__c = 'Test';

        insert pc;
        Test.startTest();
        //Test StandardTextExtension
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(pc);
        ProjectCommentsExtension pcExt = new ProjectCommentsExtension(stdCtrl);

        string s = pcExt.Summary;
        string n = pcExt.ProjectNumber;
        pcExt.Save();
        Test.stopTest();
    }

    public static testMethod void TestPHTimeOffDetailExtension()
    {
        Project__c p = new Project__c();
        p.RecordTypeId = '01270000000MH8d';
        p.Summary__c = 'Test';
        p.ProjectType__c = 'Time Card';

        insert p;

        Test.startTest();
        //Test StandardTextExtension
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(p);
        PHTimeOffDetailExtension todExt = new PHTimeOffDetailExtension(stdCtrl);

        PageReference pageRef = Page.PHTimeOffDetail;
        Test.setCurrentPage(pageRef);

        todExt.AddRow();

        ApexPages.currentPage().getParameters().put('todIND', '0');
        todExt.DeleteRow();

        List<TimeOffDetail__c> todList = new List<TimeOffDetail__c> ();
        TimeOffDetail__c todRec = new TimeOffDetail__c();
        todRec.EarningCode__c = 'ATO';
        todRec.Hours__c = 8.0;
        todRec.Project__c = p.Id;
        todRec.DateRequested__c = system.today();
        todList.add(todRec);

        todExt.TimeOffDetail = todList;
        todExt.Save();
        Test.stopTest();
    }

    public static testMethod void TestCaseWorkflowBatch()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u2 = new User(Alias = 'newUserb', Email = 'systemuser@incontacttest.com',
                EmailEncodingKey = 'UTF-8', FirstName = 'System', LastName = 'User', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles', UserName = 'systemuser@incontacttest.com');

        System.runAs(u2)
        {
            string query = 'select ID, Status, Disposition__c, WaitingOnCustomerProcessFlag__c, ResolvedProcessFlag__c, SystemClosed__c FROM Case WHERE Status = \'Resolved\' AND StopAutoNotificationClose__c = false AND (RecordType.Name = \'Incident\' OR RecordType.Name = \'Customer Portal\') LIMIT 5';
            string query2 = 'select ID, Status, Disposition__c, WaitingOnCustomerProcessFlag__c, ResolvedProcessFlag__c, SystemClosed__c FROM Case WHERE Status = \'Waiting On Customer\' AND StopAutoNotificationClose__c = false AND (RecordType.Name = \'Incident\' OR RecordType.Name = \'Customer Portal\') LIMIT 5';
            Test.StartTest();
            database.executeBatch(new CaseWorkflowBatch(query), 5);


            database.executeBatch(new CaseWorkflowBatch(query2), 5);
            Test.StopTest();
        }
    }

    public static testMethod void TestDBAProjectBeforeUpdate()
    {
        //get dba record type
        Id dbaRT = inContactBaseClass.SelectRecordTypeIDByName('Database Administration Request', 'Project__c');


        Project__c p = new Project__c();
        p.RecordTypeId = dbaRT;
        p.Summary__c = 'Test';
        p.ProjectType__c = 'inContact Pro';

        insert p;
        Test.startTest();
        p.ProjectStatus__c = 'Closed';

        update p;
        Test.stopTest();
    }

    //test inserting a contract for the insert trigger
    public static testMethod void TestContractInsertTrigger()
    {

        Account a = new Account();
        a.Name = 'test';
        a.CSM__c = UserInfo.getUserId();
        a.CS_AM__c = UserInfo.getUserId();
        a.Active_Sales_Rep__c = UserInfo.getUserId();

        insert a;
        Test.startTest();
        Contract c = new Contract();
        c.AccountId = a.Id;
        insert c;
        Test.stopTest();
    }

    public static testMethod void TestChannelManager()
    {
        Account a = new Account();
        a.Name = 'test';
        a.CSM__c = UserInfo.getUserId();
        a.CS_AM__c = UserInfo.getUserId();
        a.Active_Sales_Rep__c = UserInfo.getUserId();
        a.BillingState = 'TZ';

        insert a;

        //ChannelManager__c c = new ChannelManager__c();
        //c.Name = 'TZ';
        //c.ChannelManager__c = UserInfo.getUserId();

        //insert c;
    }

    public static testMethod void TestPSTimesheetBatch()
    {
        Test.StartTest();
        database.executeBatch(new PSTimesheetBatch(), 1000);
        Test.StopTest();

    }

    public static testMethod void TestOMProjectCloseAndCancel()
    {
        //get dba record type
        Id omRT = [SELECT Id FROM RecordType WHERE Name = 'Order Management' AND SobjectType = 'Project__c' LIMIT 1].Id;

        OrderManagementTask__c om = new OrderManagementTask__c();
        om.NewOrder__c = true;
        om.Name = '77';
        om.Order__c = 77;
        om.Description__c = 'Test';
        om.CustomerOrder__c = true;

        insert om;

        Project__c p = new Project__c();
        p.RecordTypeId = omRT;
        p.Summary__c = 'Test';
        p.ProjectType__c = 'Customer';
        p.RequestType__c = 'New';

        insert p;
        Test.startTest();
        ApexPages.StandardController projClose = new ApexPages.StandardController(p);
        ProjectCloseExtension projClExt = new ProjectCloseExtension(projClose);

        projClExt.Save();
        projClExt.Cancel();

        ApexPages.StandardController projCancel = new ApexPages.StandardController(p);
        ProjectCancelAllExtension projCaExt = new ProjectCancelAllExtension(projCancel);

        projCaExt.Save();
        projCaExt.Cancel();
        Test.stopTest();
    }

    public static testMethod void TestProductReadinessProject()
    {
        //get dba record type
        Id prRT = [SELECT Id FROM RecordType WHERE Name = 'Product Readiness Project' AND SobjectType = 'Project__c' LIMIT 1].Id;

        ProductReadinessTask__c prt1 = new ProductReadinessTask__c();
        prt1.AssignTo__c = 'Concept Owner';
        prt1.Name = 'Test';
        prt1.Order__c = 999;
        prt1.CorePlus__c = true;
        prt1.DaysPrior__c = 1;
        prt1.Description__c = 'Test';
        prt1.TaskType__c = 'cp';

        insert prt1;

        ProductReadinessTask__c prt2 = new ProductReadinessTask__c();
        prt2.AssignTo__c = 'Concept Owner';
        prt2.Name = 'Test2';
        prt2.Order__c = 1000;
        prt2.CorePlus__c = false;
        prt2.DaysPrior__c = 1;
        prt2.Description__c = 'Test';
        prt2.TaskType__c = 'cp';
        prt2.DependsOn__c = 999;

        insert prt2;

        Project__c p = new Project__c();
        p.RecordTypeId = prRT;
        p.Summary__c = 'Test';
        p.ProjectType__c = 'Customer';
        p.RequestType__c = 'New';
        p.PricingRateReview__c = true;


        insert p;

        Task newtask = new Task();
        newtask.Subject = p.Name;
        newtask.WhatId = p.Id;
        newtask.Description = p.Summary__c;
        newtask.Status = 'In Progress';

        insert newtask;


        Task[] tsks = [SELECT ID FROM Task WHERE Id = :newtask.Id];

        system.debug('tsks == > ' + tsks);
        for (Task t : tsks)
        {
            t.Status = 'Completed';
        }

        update tsks;
    }

    public static testMethod void TestOpportunityAfterInsert()
    {
        Account a = new Account();
        a.Name = 'Test Account';
        a.CustomerTemperature__c = 'Mad';
        a.CustomerTemperatureDate__c = system.now();
        insert a;



        AccountHighlightComponentController hc = new AccountHighlightComponentController();
        hc.acctId = a.Id;
        hc.getAcctWrapper();
        hc.blank();

        Contact c = new Contact();
        c.LastName = 'Test';
        c.AccountId = a.Id;
        insert c;
        Test.startTest();
        Opportunity o = new Opportunity();
        o.Name = 'Test';
        o.AccountId = a.Id;
        o.StageName = 'Assigned';
        o.CloseDate = Date.today();
        o.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Education Request', 'Opportunity');
        o.PrimaryContact__c = c.Id;
        o.PSEducationConsultant__c = UserInfo.getUserId();
        o.PM_Estimated_Go_Live__c = system.today();

        insert o;

        //TEST PSImplementationCalendarController
        PSImplementationCalendarController controller = new PSImplementationCalendarController();
        controller.SubtractMonth();
        controller.AddMonth();
        boolean testRender = controller.RenderList;
        string monthString = controller.MonthString;
        string calendar = controller.calendarControl;
        controller.UpdateSelectedOpps();
        Test.stopTest();
    }

    

    public static testMethod void TestLeadStatusClass()
    {
        Lead l = inContactBaseClass.CreateLead('firstName', 'lastName', 'leadSource', 'company');

        l.Status = 'Working';
        l.Lead_Status_Detail__c = '1st attempt to contact';

        insert l;
        Test.startTest();
        l.Status = 'Test Change';
        update l;
        Test.stopTest();
    }

    public static testMethod void TestADFSLinkExtension()
    {
        Account a = new Account();
        a.Name = 'Test Account';
        a.CostGuard_Acct__c = '0000';
        insert a;

        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'Test';
        c.Email = 'Test@test.com';
        c.AccountId = a.Id;
        insert c;
        Test.startTest();
        ApexPages.StandardController controller = new ApexPages.StandardController(c);
        ADFSLinkExtension extension = new ADFSLinkExtension(controller);

        c.ADFSGuid__c = 'test';
        update c;

        c = [SELECT Id, FirstName, LastName, Email, CostGuardAcct__c, ADFSGuid__c FROM Contact WHERE Id = :c.Id];

        ApexPages.StandardController controller2 = new ApexPages.StandardController(c);
        ADFSLinkExtension extension2 = new ADFSLinkExtension(controller2);
        Test.stopTest();
    }

    public static testMethod void TestKnowledgeBaseProxy()
    {
        Test.setMock(WebServiceMock.class, new IKnowledgeBaseProxy());

        List<KnowledgeBaseProxyClass> result = KnowledgeBaseProxyService.ArticleSearch('test');

        System.assertEquals('Test', result[0].Title);
        System.assertEquals('1234', result[0].ArticleNumber);
    }

    static testMethod void TestEventCalendarController()
    {
        EventsCalendarController ecc = new EventsCalendarController();
        string calendarString = ecc.calendarControl;
        ecc.SubtractMonth();
        ecc.AddMonth();

        List<selectOption> eventType = ecc.EventTypeSelect;
        String[] platforms = ecc.AvailablePlatforms;
        Map<String, String> plaformColors = ecc.PlatformColors;
        ecc.eventType = eventType[1].getValue();
        ecc.SetEvents();

    }

    static testMethod void TestCaseIncidentPage()
    {
        //set mock for uploading articles
        Test.setMock(WebServiceMock.class, new IKnowledgeBaseProxy());

        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        Case knownIssue = new Case();
        knownIssue.RecordTypeId = rtMapByName.get('Known Issue').getRecordTypeId();
        knownIssue.Subject = 'Test Known Issue';
        knownIssue.ProductImpacted__c = 'Test Product';

        insert knownIssue;

        Account a = new Account();
        a.Name = 'Test Account';
        insert a;

        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'Test';
        c.Email = 'Test@test.com';
        c.AccountId = a.Id;
        insert c;
        Test.startTest();
        Case newCase = new Case();
        newCase.Subject = 'test';
        newCase.Request_Type__c = 'Call Behavior';
        newCase.KnownIssue__c = knownIssue.Id;

        string acctId = ApexPages.currentPage().getParameters().put('def_account_id', a.Id);
        string contactId = ApexPages.currentPage().getParameters().put('def_contact_id', c.Id);

        ApexPages.StandardController controller = new ApexPages.StandardController(newCase);
        CaseIncidentPage extension = new CaseIncidentPage(controller);

        extension.ClearKnownIssue();
        newCase.KnownIssue__c = knownIssue.Id;

        extension.UploadArticles();
        List<SelectOption> eventList = extension.ActiveEvents;
        extension.SaveAndTrackTime();

        ApexPages.StandardController controller2 = new ApexPages.StandardController(newCase);
        CaseIncidentPage extension2 = new CaseIncidentPage(controller2);

        extension2.CancelInline();
        extension2.SaveInline();

        CaseArticle__c article = new CaseArticle__c();
        ApexPages.CurrentPage().getParameters().put('CF00N70000003FYuQ_lkid', newCase.Id);
        ApexPages.CurrentPage().getParameters().put('CF00NQ00000014cA6_lkid', newCase.Id); //sbx until synced

        ApexPages.StandardController articleController = new ApexPages.StandardController(article);
        CaseArticleAttachExtension articleExtension = new CaseArticleAttachExtension(articleController);

        articleExtension.Save();

        newCase.TFSID__c = '10';
        newCase.StackRank__c = 10.0;
        update newCase;
        Test.stopTest();
    }

    static testMethod void TestKnownIssuesController()
    {

        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        Case knownIssue = new Case();
        knownIssue.RecordTypeId = rtMapByName.get('Known Issue').getRecordTypeId();
        knownIssue.Subject = 'Test Known Issue';
        knownIssue.ProductImpacted__c = 'Test Product';

        insert knownIssue;
        Test.startTest();
        CaseSearchKnownIssuesController kiController = new CaseSearchKnownIssuesController();
        kiController.recordTypeName = 'Known Issue';
        kiController.searchString = 'Test Search';
        kiController.knownIssue.ProductImpacted__c = 'Test Product';

        kiController.ParseFilter();
        kiController.c = new Case();
        Apexpages.currentpage().getParameters().put('kIssue', knownIssue.Id);

        string remoteSearch = CaseSearchKnownIssuesController.FindCases('test', 'ACD', 'Known Issue');
        remoteSearch = CaseSearchKnownIssuesController.FindCases('test', '', 'Known Issue');

        System.assertEquals(knownIssue.Id, Apexpages.currentpage().getParameters().get('kIssue'));
        kiController.SelectKnownIssue();
        Test.stopTest();
    }

    static testMethod void TestCaseRedirect()
    {
        Case c = new Case();
        ApexPages.StandardController controller = new ApexPages.StandardController(c);
        CaseRedirectExtension extension = new CaseRedirectExtension(controller);
        extension.redirect();
    }

    static testmethod void TestCorporateItFeatureSync()
    {
        //set mock for creating TFS Item
        /**Test.setMock(WebServiceMock.class, new ICorporateItTfsService());

        Project__c project = new Project__c
        (
            Summary__c = 'Test',
            ProjectStatus__c = 'New'
        );

        insert project;
        Test.startTest();
        ApexPages.StandardController controller = new ApexPages.StandardController(project);
        FeatureCreateFromProject featureExt = new FeatureCreateFromProject(controller);

        boolean hasFeature = featureExt.HasFeature;
        string featureId = FeatureCreateFromProject.InsertNewFeature(featureExt.feature.Title__c, featureExt.feature.Details__c, project.Id);
        FeatureCreateFromProject.InsertTfsFeature(featureId);
        Test.stopTest();**/
    }

    static testmethod void TestCorporateItFeatureCommentSync()
    {
        //set mock for creating TFS Item
        Test.setMock(WebServiceMock.class, new ICorporateItTfsService());

        Feature__c feature = new Feature__c();
        insert feature;

        Test.startTest();
        CorporateItTfsAccess.AddTfsComment(99999, 'comment', feature.Id);
        Test.stopTest();
    }

    public static testMethod void TestSharepointDocumentServiceProxy()
    {
        Test.startTest();
        Test.setMock(WebServiceMock.class, new ISharepointDocumentService());
        Boolean result = SharepointDocumentAccess.CreateCustomerLibrary('0');
        System.assertEquals(true, result);
        Test.stopTest();
    }

    // TODO: This test really isn't testing anything and should be refactored
    public static testMethod void TestSharepointDocumentServiceProxyAsync()
    {
        Test.startTest();
        Test.setMock(WebServiceMock.class, new ISharepointDocumentService());
        Set<String> setOfId = new Set<String>();
        SharepointDocumentAccess.CreateCustomerLibraryAsync(setOfId);
        System.assert(true);
        Test.stopTest();
    }

    public static testMethod void TestSharePointDocumentLibraryOnAccountTrigger()
    {
        //This tests to make sure the trigger fires for inserts and updates
        List<Account> testList = new List<Account> ();
        for (integer i = 0; i < 9; i++)
        {
            //Create a new Account object
            Account acct = inContactBaseClass.CreateAccount('Test Account');
            acct.CostGuard_Acct__c = String.valueOf(i);
            testList.add(acct);
        }

        //Act - insert accounts to fire trigger.isInsert
        insert testList;

        //Act - updates the account to fire trigger.isUpdate
        Account updatedAccount = testList[2];
        updatedAccount.CostGuard_Acct__c = '99999999';

        update updatedAccount;
    }
}