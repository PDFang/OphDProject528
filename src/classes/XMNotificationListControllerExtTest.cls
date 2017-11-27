@isTest
public class XMNotificationListControllerExtTest {

    public static testMethod void TestPreviewMessagesExcluded() {
        Case testCase = createTestData();

        XMRestEventServiceHttpMock httpMockCallout = new XMRestEventServiceHttpMock(200,'Complete','[{"Name": "sForceTest1"}]',null);

        Test.setMock(HttpCalloutMock.class, httpMockCallout);

        List<xmNotification__c> notifications = new List<xmNotification__c>();

        //add two notifications, one is a preview and one is normal
        //Name, Request_Type__c, xMatters_Form__c, Request_Date__c, Status__c, Related_Notification__c, CreatedBy.Name, CreatedBy.Id, CreatedDate
        notifications.add(new xmNotification__c(
                Request_Type__c = 'Maintenance Notification',
                Case__c = testCase.Id,
                xMatters_Form__c = 'testform',
                Request_Date__c = date.today()
        ));

        notifications.add(new xmNotification__c(
                Request_Type__c = 'Maintenance Preview',
                Case__c = testCase.Id,
                xMatters_Form__c = 'testform',
                Request_Date__c = date.today()
        ));


        insert notifications[0];
        insert notifications[1];

        ApexPages.StandardController caseController = new ApexPages.StandardController(testCase);

        test.startTest();

        XMNotificationListControllerExtension extension = new XMNotificationListControllerExtension(caseController);
        test.stopTest();

        system.assertEquals(testCase.Id, extension.caseId, 'Incorrect caseId used by the controller extension');
        system.assertEquals(1, extension.notifications.size(), 'Wrong number of notifications retrieved');
        system.assertEquals('Maintenance Notification', extension.notifications[0].Request_Type__c, 'Wrong notification loaded by controller extension');
    }

    private static Case createTestData(){
        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'Test Account',
                Type = 'Customers',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId()
        );

        insert testAccount;

        Map<String,Schema.RecordTypeInfo> contactRecordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact testContact = new Contact(
                LastName = 'Test Contact',
                FirstName = 'Test',
                Email = 'contact1@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccount.Id
        );

        insert testContact;

        Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();
        Case testCase = new Case(
                RecordTypeId = recordTypeMap.get('Incident').getRecordTypeId(),
                Subject = 'testIncidentPriorityAssignment Test',
                Description = 'testIncidentPriorityAssignment Test',
                Status = 'New',
                AccountId = testAccount.Id,
                Severity__c = 'S2',
                Related_to_Previous_Known_Issue__c = 'No',
                Security_Issue__c = 'No',
                Product_or_Service__c = 'Service Disruption',
                Request_Type__c = 'Dialer',
                Contact = testContact
        );

        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        testCase.setOptions(dmo);

        insert testCase;

        return testCase;
    }
}