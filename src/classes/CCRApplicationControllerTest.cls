/**
 * Created by mike.burkhard on 12/26/2017.
 */
@IsTest
public with sharing class CCRApplicationControllerTest {
    public static testMethod void testApplicationList() {
        ChangeControlRequest__c ccr = insertTestData();

        PageReference pageRef = Page.CCRApplicationManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', ccr.Id);
        CCRApplicationController controller = new CCRApplicationController();

        test.startTest();
        String values = controller.applicationList;
        test.stopTest();

        list<string> deserialized = (List<string>)JSON.deserialize(values, list<string>.class);

        Map<String, Boolean> expectedValues = new Map<String, Boolean>();
        expectedValues.put('Support Site', false);
        expectedValues.put('Where Is', false);

        for(String value : deserialized) {
            if(expectedValues.containsKey(value)) {
                expectedValues.put(value, true);
            }
        }

        for(String key : expectedValues.keySet()) {
            system.assert(expectedValues.get(key), key + ' was not returned from applicationList');
        }
    }

    public static testMethod void testGetAllApplications() {
        ChangeControlRequest__c ccr = insertTestData();

        test.startTest();
        String values = CCRApplicationController.GetAllApplications(ccr.Id);
        test.stopTest();

        List<CCRApplication__c> deserialized = (List<CCRApplication__c>)JSON.deserialize(values, List<CCRApplication__c>.class);

        List<CCRApplication__c> expectedApplications = [Select Id, Application__c, Description__c, ChangeControlRequest__c From CCRApplication__c where ChangeControlRequest__c =: ccr.Id];

        for(CCRApplication__c app : expectedApplications) {
            Boolean appFound = false;
            for(CCRApplication__c actualApp : deserialized) {
                if(app.Application__c == actualApp.Application__c){
                    appFound = true;
                    break;
                }
            }

            system.assert(appFound, app + ' not returned from GetAllApplications');
        }
    }

    public static testMethod void testUpdateUpSertApplication() {
        ChangeControlRequest__c ccr = insertTestData();

        List<CCRApplication__c> applications = [select Application__c, Description__c, ChangeControlRequest__c, Id from CCRApplication__c where Application__c = 'Support Site Unit Test'];

        CCRApplication__c ccrApplication = applications[0];
        ccrApplication.Application__c = 'Support Site Unit Test - Updated';
        ccrApplication.Description__c = 'test - Support Site - Updated';

        String updatedValues = JSON.serialize(ccrApplication);

        test.startTest();
        CCRApplicationController.UpSertApplication(updatedValues);
        test.stopTest();

        List<CCRApplication__c> ccrApplications = [select Application__c, Description__c from CCRApplication__c];
        system.assertEquals(2, ccrApplications.size());

        List<Boolean> results = new List<Boolean>();
        results.add(false);
        results.add(false);

        for(CCRApplication__c app : ccrApplications) {
            if(app.Application__c.startsWith('Support Site')) {
                system.assert(!results[0], 'Support Site was found twice after update');
                system.assertEquals('Support Site Unit Test - Updated', app.Application__c);
                system.assertEquals('test - Support Site - Updated', app.Description__c);
                results[0] = true;
            }
            else {
                system.assert(!results[1], 'Where Is was found twice after update');
                system.assertEquals('Where Is Unit Test', app.Application__c);
                system.assertEquals('test - Where Is', app.Description__c);
                results[1] = true;
            }
        }

        Boolean fullResult = true;
        for(Boolean result : results) {
            if(!result) {
                fullResult = false;
                break;
            }
        }
        system.assert(fullResult, 'Support Site was not inserted');
    }

    public static testMethod void testInsertUpSertApplication() {
        ChangeControlRequest__c ccr = insertTestData();

        CCRApplication__c ccrApplication = new CCRApplication__c(
                Application__c = 'New App',
                ChangeControlRequest__c = ccr.Id,
                Description__c = 'New App Description'
        );

        String newValues = JSON.serialize(ccrApplication);

        test.startTest();
        String callResult = CCRApplicationController.UpSertApplication(newValues);
        test.stopTest();

        system.assert(callResult.contains('"result" : "Success"'));

        List<CCRApplication__c> ccrApplications = [select Application__c, Description__c from CCRApplication__c];
        system.assertEquals(3, ccrApplications.size());

        List<Boolean> results = new List<Boolean>();
        results.add(false);
        results.add(false);
        results.add(false);

        for(CCRApplication__c app : ccrApplications) {
            if(app.Application__c.startsWith('Support Site')) {
                system.assert(results[0] == false, 'Support Site found twice after insert');
                system.assertEquals('Support Site Unit Test', app.Application__c);
                system.assertEquals('test - Support Site', app.Description__c);
                results[0] = true;
            }
            else if(app.Application__c.startsWith('Where Is')){
                system.assert(results[1] == false, 'Where Is found twice after insert');
                system.assertEquals('Where Is Unit Test', app.Application__c);
                system.assertEquals('test - Where Is', app.Description__c);
                results[1] = true;
            }
            else {
                system.assert(results[2] == false, 'New App was found twice after insert');
                system.assertEquals('New App', app.Application__c);
                system.assertEquals('New App Description', app.Description__c);
                results[2] = true;
            }
        }

        Boolean fullResult = true;
        for(Boolean result : results) {
            if(!result) {
                fullResult = false;
                break;
            }
        }
        system.assert(fullResult, 'New App was not inserted');
    }

    public static testMethod void testDeleteApplication() {
        ChangeControlRequest__c ccr = insertTestData();

        List<CCRApplication__c> applications = [select Id from CCRApplication__c where Application__c = 'Support Site Unit Test'];

        CCRApplication__c ccrApplication = applications[0];

        test.startTest();
        String callResult = CCRApplicationController.DeleteApplication(ccrApplication.Id);
        test.stopTest();

        system.assert(callResult.contains('"result" : "Success"'));

        List<CCRApplication__c> ccrApplications = [select Application__c, Description__c from CCRApplication__c];
        system.assertEquals(1, ccrApplications.size());

        system.assertEquals('Where Is Unit Test', ccrApplications[0].Application__c, 'Wrong application deleted in DeleteApplication');
    }

    public static testMethod void testUpSertApplicationDMLFailure() {
        ChangeControlRequest__c ccr = insertTestData();

        List<CCRApplication__c> applications = [select Application__c, Description__c, ChangeControlRequest__c, Id from CCRApplication__c where Application__c = 'Support Site Unit Test'];

        CCRApplication__c ccrApplication = applications[0];
        ccrApplication.Application__c = 'Support Site Unit Test - Updated';
        ccrApplication.Description__c = 'test - Support Site - Updated';

        String updatedValues = JSON.serialize(ccrApplication);

        test.startTest();
        CCRApplicationController.DeleteApplication(ccrApplication.Id);
        String callResult = CCRApplicationController.UpSertApplication(updatedValues);
        test.stopTest();

        system.assertNotEquals('Success', callResult);
        system.assert(callResult.contains('"result" : "Failed"'));
    }

    public static testMethod void testcancel() {
        ChangeControlRequest__c ccr = insertTestData();

        PageReference pageRef = Page.CCRApplicationManage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', ccr.Id);
        CCRApplicationController controller = new CCRApplicationController();

        test.startTest();
        pagereference ref = controller.cancel();
        test.stopTest();

        system.assertEquals(true, ref.getRedirect());
    }

    private static ChangeControlRequest__c insertTestData() {
        List<RecordType> ccrRecordType = [select Id from RecordType where Name = 'Corporate IT' and SobjectType = 'ChangeControlRequest__c'];
        //Call ChangeControlRequest object
        ChangeControlRequest__c changeControlRequest =
                new ChangeControlRequest__c(
                        Summary__c = 'Testing CCRs',
                        CCRStartTime__c = system.today(),
                        ChangeReason__c = 'Fix',
                        Monitoring_set_up_on_device__c = 'Yes',
                        Impact__c = 'SEV 1',
                        Urgency__c = 'HIGH',
                        RFCType__c = 'NORMAL',
                        Cluster__c = 'B2;B3',
                        ReleasePicklist__c = 'Architecture',
                        ContingencyOwner__c = userInfo.getUserId(),
                        ContingencyDeadline__c = system.today() + 4,
                        Description__c = 'Test summary',
                        DescriptionOfTesting__c = 'Test summary',
                        ContingencyPlan__c = 'Test summary',
                        ReleaseDate__c = system.today() + 4,
                        SystemsAppsProcessesImpacted__c = 'Test summary',
                        Experience__c = '0 - This has been successfully completed before',
                        PrepTimeRequired__c = '3 - 15-30 days',
                        RequiresUserEducation__c = '2 - Minimal',
                        BusinessImpact__c = '3 - Major, not high profile',
                        Documentation__c = '4 - Considerable amount',
                        ResourcesRequired__c = '2 - 2 people, same group',
                        MaintenanceWindow__c = '8 - Outside',
                        Security__c = '2 - Access affected',
                        Validation__c = '3 - Minor',
                        Backout__c = '2 - In place, easy to do',
                        OutageScope__c = '6 - Partial System',
                        RecordTypeId = ccrRecordType[0].Id
                );

        insert changeControlRequest;

        //create each type of task
        List<RecordType> recordTypes = [select Id from RecordType where Name in ('Communication Task', 'Validation Task', 'Work Task') and SobjectType = 'CCRTask__c'];

        List<CCRTask__c> ccrTasks = new List<CCRTask__c>();
        for(RecordType r : recordTypes) {
            ccrTasks.add(new CCRTask__c(
                    Order__c = 1,
                    AssignedTo__c = userinfo.getUserId(),
                    Description__c = 'Validation',
                    Duration__c = 1,
                    Status__c = 'OPEN',
                    RecordTypeID = r.id,
                    ChangeControlRequest__c = changeControlRequest.Id
            ));
        }

        insert ccrTasks;

        CollaborationGroup feedItemGroup = new CollaborationGroup(
                Name = 'Unit Test Chatter Group',
                CollaborationType = 'Private'
        );
        insert feedItemGroup;

        //insert the new topics
        List<Topic> newTopics = new List<Topic>();

        newTopics.add(new Topic(
                Description = 'Support Site Unit Test',
                Name = 'Support Site Unit Test'
        ));

        newTopics.add(new Topic(
                Description = 'Where Is Unit Test',
                Name = 'Where Is Unit Test'
        ));

        insert newTopics;

        List<CCRApplication__c> ccrApplications = new List<CCRApplication__c>();
        ccrApplications.add(new CCRApplication__c(
                Application__c = 'Support Site Unit Test',
                ChangeControlRequest__c = changeControlRequest.Id,
                Description__c = 'test - Support Site'
        ));

        ccrApplications.add(new CCRApplication__c(
                Application__c = 'Where Is Unit Test',
                ChangeControlRequest__c = changeControlRequest.Id,
                Description__c = 'test - Where Is'
        ));
        insert ccrApplications;

        return changeControlRequest;
    }
}