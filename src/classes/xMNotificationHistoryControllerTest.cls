/**
 * Created by Arnab KarSarkar on 1/22/2018.
 */

@IsTest
public class xMNotificationHistoryControllerTest {


    public static void setup(){
        //setup test data

        Id rtCustOther = '01270000000Lrn4AAC';

        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.CadebillAccountNo__c = 9999999;
        acc.NICE_QM_Cluster__c = 'EN1';
        acc.NICE_WFM_Cluster__c = 'NWFM 1-2';
        acc.Verint_Cluster__c = 'V1';
        acc.inContact_Cluster__c =  'C9';

        insert acc;

        xmPerson__c person = new xmPerson__c(
                xmPersonUID__c = 'aefgh-1234-cdeft'
        );
        insert person;

        Map<String, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact testContact = new Contact(
                FirstName = 'XMPersonManagementControllerTest',
                LastName = 'Contact',
                Email = 'contact1@incontact.com',
                RecordTypeId = recordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = acc.Id,
                xmPerson__c = person.Id
        );

        insert testContact;

        SiteConfiguration__c siteConfig = new SiteConfiguration__c();
        siteConfig.Name = inContactBaseClass.OrgId15Digit; //UserInfo.getOrganizationId();
        siteConfig.AutoEventEmails__c = false;
        siteConfig.DaysToDisplayKnownIssues__c = 30;
        siteConfig.OrgId__c =  inContactBaseClass.OrgId15Digit; //UserInfo.getOrganizationId();
        siteConfig.EventResolvedPriorities__c = 'P1;P2;';
        siteConfig.EventResolvedEmails__c = false;

        insert siteConfig;

        ProductEventMap__c testProduct = new ProductEventMap__c();
        testProduct.Name = 'Test Product';
        testProduct.Product__c = 'Test Product';
        testProduct.ImplementedProduct__c = 'Test Product';
        testProduct.Platform__c = 'Cluster - inContact';
        testProduct.HasClusters__c = false;

        insert testProduct;


        Map<String,Schema.RecordTypeInfo> testIncidentTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testEvent = new Case(
                RecordTypeId = testIncidentTypeMap.get('Event').getRecordTypeId(),
                Subject = 'testEventInitialConfirmationNotification Event',
                Description = 'testEventInitialConfirmationNotification',
                Status = 'New',
                EventType__c = 'Service Disruption',
                PlatformsImpacted__c = 'C6 - inContact',
                ProductImpacted__c = 'Test Product',
                InternalEvent__c = false,
                Priority = 'P1'
        );

        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        testEvent.setOptions(dmo);

        insert testEvent;

        xmNotification__c xmNotification = new xmNotification__c(
                Case__c = testEvent.Id,
                Request_Date__c = system.now(),
                Request_Type__c = 'Event Initial Confirmation'
        );
        insert xmNotification;


        xmDelivery__c xmDelivery = new xmDelivery__c();
        xmDelivery.DeliveryStatus__c = 'Success';
        xmDelivery.Message__c = 'TEST - Adding notification for device';
        xmDelivery.xMattersPerson__c = person.Id;
        xmDelivery.XMNotification__c = xmNotification.Id;
        xmDelivery.Device__c = 'testuser@incontact.com';
        xmDelivery.Device_Type__c = 'Work Email';
        xmDelivery.Message__c =  '';
        xmDelivery.Delivery_Date__c = System.today();

        insert xmDelivery;


    }

    public static testMethod  void testController(){
        setup();
        Test.startTest();
            Test.setCurrentPage(Page.xMNotificationHistory);
            Contact[] testContact = [select Id from Contact where FirstName = 'XMPersonManagementControllerTest' Limit 1];
            xMNotificationHistoryController cntrl = new xMNotificationHistoryController(new ApexPages.standardController(testContact[0]));
            system.assertEquals(1, cntrl.NotificationHistoryList.size());

        Test.stopTest();

    }

}

