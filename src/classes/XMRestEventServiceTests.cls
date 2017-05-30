@isTest
public class XMRestEventServiceTests {
    public testMethod static void startExternalEventProcessing_WillProcessRecords(){

        XMRestEventServiceHttpMock httpMockCallout = new XMRestEventServiceHttpMock(200,'Complete','[{"Name": "sForceTest1"}]',null);

        insertProductEventMap();
        Case eventCase = insertCase();

        // Create XMNotificationObject
        XMNotification__c xMattersNotification = new XMNotification__c();
        xMattersNotification.Case__c = eventCase.Id;
        xMattersNotification.Request_Type__c = 'Event Initial Confirmation';
        xMattersNotification.Status__c = 'New';
        xMattersNotification.Request_Date__c = system.today();

        insert xMattersNotification;

        // Start test and perform fake callout
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, httpMockCallout);

        XMRestEventService service = new XMRestEventService();
        service.startExternalEventProcessing(xMattersNotification);

        test.stopTest();

        system.debug('look here ==> ' + httpMockCallout.requestBodyPassed);
    }

    public testMethod static void  getSupportedPartners_Will_ReturnPartnerList(){
        String[] results = XMRestEventService.getSupportedPartners();

        system.assert(results.size() > 0);
    }

    private static void insertProductEventMap(){
        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'inContact';
        pem.Product__c = 'inContact';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;
    }

    private static Case insertCase(){
        createSiteConfig();

        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;

        // Get the details for the case event object
        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        //Get Event record type id
        Id eventRecordType = rtMapByName.get('Event').getRecordTypeId();

        // Create case used for test
        Case eventCase = new Case();
        eventCase.Description = 'This is a sample case to test the xMatters integration';
        eventCase.ProductImpacted__c = 'inContact';
        eventCase.PlatformsImpacted__c = 'C9 - inContact';
        eventCase.Subject = 'Test Event';
        eventCase.EventType__c = 'Service Disruption';
        eventCase.RecordTypeId = eventRecordType;
        eventCase.Status = 'New';
        eventCase.InternalEvent__c = false;

        eventCase.setOptions(dmo);
        insert eventCase;

        return eventCase;
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