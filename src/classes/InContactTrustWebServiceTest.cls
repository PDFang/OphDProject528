/**
 * Created by mohandaas.rangaswamy on 12/14/2017.
 */
@isTest
public class InContactTrustWebServiceTest {


    static testMethod void TestTrustWebService()
    {

        SiteConfiguration__c sbx = new SiteConfiguration__c();
        sbx.Name = inContactBaseClass.OrgId15Digit;
        sbx.AutoEventEmails__c = true;
        sbx.DaysToDisplayKnownIssues__c = 30;
        sbx.OrgId__c = inContactBaseClass.OrgId15Digit;
        sbx.EventResolvedPriorities__c = 'P1;P2;';
        sbx.EventResolvedEmails__c = true;

        insert sbx;

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

        test.startTest();

        List<inContactTrustWebService.MaintenanceNotification> notifications = inContactTrustWebService.SelectMaintenanceNotificationsByCustomerAndDates(100001, system.today() - 30, system.today());
        inContactTrustWebService.EventNodeList nodeList = inContactTrustWebService.SelectEventsByNodeAndDate('inContact', system.today() - 7);
        inContactTrustWebService.CustomerNodeEvents testNodeEvents = inContactTrustWebService.SelectTrustNodesByCustomerAndDaysBack(100001, 30);
        testNodeEvents = inContactTrustWebService.SelectTrustNodesByCustomerAndDaysBack(100002, 30);
        List<Case> knonwIssues = inContactTrustWebService.SelectKnownIssuesByCustomer(100001, '');

        inContactTrustWebService.TrustNode trustNode = new inContactTrustWebService.TrustNode(system.now(), system.now(), 'case-id', 'node', 'type');
        inContactTrustWebService.MaintenanceNotification maintenanceNotification = new inContactTrustWebService.MaintenanceNotification(system.now(), system.now(), 'subjectCon', 'descriptionCon', 'eventTypeCon', 'carrierCon', 'platformCon', 'cNumber', 'productImpacted');
        inContactTrustWebService.KnownIssue knownIssue = new inContactTrustWebService.KnownIssue(system.now(), system.now(), 'subjectCon', 'summaryCon', 'recreateStepsCon', 'workAroundCon', 'statusCon', 'cNumber');

        test.stopTest();

    }

}