@isTest
public class XMRestEventServiceTests {
    public testMethod static void startExternalEventProcessing_WillProcessRecords(){

        XMRestEventServiceHttpMock httpMockCallout = new XMRestEventServiceHttpMock(200,'Complete','[{"Name": "sForceTest1"}]',null);

        insertProductEventMap();
        Case createdCase = insertCase('inContact', 'C9 - inContact');

        Case eventCase = [SELECT Id, CaseNumber, PlatformsImpacted__c, ProductImpacted__c FROM Case WHERE Id = :createdCase.Id];

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

        XMEventData actualEventData = (XMEventData) JSON.deserialize(httpMockCallout.requestBodyPassed, XMEventData.class);

        // Check eventGroupInfo in the returned json
        system.assertEquals(eventCase.Id, actualEventData.eventGroupInfo.salesforceCaseId);

        // Check the platformGroup to ensure it has the right Implemented Product group
        system.assertEquals('IP_{PartnerPrefix}_inContact_C9-inContact', actualEventData.platformGroups[0]);

        // Check the template properties
        system.assertEquals(eventCase.ProductImpacted__c, actualEventData.templateProperties.get('productImpacted'));
        system.assertEquals(eventCase.CaseNumber, actualEventData.templateProperties.get('caseNumber'));
    }

    public testMethod static void startExternalEventProcessing_NoClusterAndNoConfig(){

        XMRestEventServiceHttpMock httpMockCallout = new XMRestEventServiceHttpMock(200,'Complete','[{"Name": "sForceTest1"}]',null);

        insertProductEventMap();
        Case createdCase = insertCase('DIA', 'Transport Services');

        Case eventCase = [SELECT Id, CaseNumber, PlatformsImpacted__c, ProductImpacted__c FROM Case WHERE Id = :createdCase.Id];

        // Create XMNotificationObject
        XMNotification__c xMattersNotification = new XMNotification__c();
        xMattersNotification.Case__c = eventCase.Id;
        xMattersNotification.Request_Type__c = 'Event Platforms Add';
        xMattersNotification.Status__c = 'New';
        xMattersNotification.Request_Date__c = system.today();
        xMattersNotification.AddedPlatforms__c = 'DIA Circuit';

        insert xMattersNotification;

        // Start test and perform fake callout
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, httpMockCallout);

        XMRestEventService service = new XMRestEventService();
        service.startExternalEventProcessing(xMattersNotification);

        test.stopTest();

        XMEventData actualEventData = (XMEventData) JSON.deserialize(httpMockCallout.requestBodyPassed, XMEventData.class);

        // Check eventGroupInfo in the returned json
        system.assertEquals(eventCase.Id, actualEventData.eventGroupInfo.salesforceCaseId);

        // Check the platformGroup to ensure it has the right Implemented Product group
        system.assertEquals('IP_{PartnerPrefix}_DIA_NONE', actualEventData.platformGroups[0]);

        // Check the template properties
        system.assertEquals(eventCase.ProductImpacted__c, actualEventData.templateProperties.get('productImpacted'));
        system.assertEquals(eventCase.CaseNumber, actualEventData.templateProperties.get('caseNumber'));
    }


    private static void insertProductEventMap(){

        List<ProductEventMap__c> productEventMaps = new  List< ProductEventMap__c>();

        ProductEventMap__c inContactPem = new ProductEventMap__c();
        inContactPem.Name = 'inContact';
        inContactPem.Product__c = 'inContact';
        inContactPem.ImplementedProduct__c = 'inContact';
        inContactPem.Platform__c = 'Cluster - inContact';
        inContactPem.HasClusters__c = true;

        productEventMaps.add(inContactPem);


        ProductEventMap__c noClusterPem = new ProductEventMap__c();
        noClusterPem.Name = 'DIA';
        noClusterPem.Product__c = 'DIA';
        noClusterPem.ImplementedProduct__c = 'inContact';
        noClusterPem.Platform__c = 'DIA Circuit';
        noClusterPem.HasClusters__c = false;

        productEventMaps.add(noClusterPem);
        insert productEventMaps;
    }

    private static Case insertCase(String productImpacted, String platformImpacted){

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
        eventCase.ProductImpacted__c = productImpacted;
        eventCase.PlatformsImpacted__c = platformImpacted;
        eventCase.Subject = 'Test Event';
        eventCase.EventType__c = 'Service Disruption';
        eventCase.RecordTypeId = eventRecordType;
        eventCase.Status = 'New';
        eventCase.InternalEvent__c = false;
        eventCase.EventStartDateTime__c = system.now();

        eventCase.setOptions(dmo);
        insert eventCase;

        return eventCase;
    }

    // This is required to create a case
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