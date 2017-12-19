@IsTest
public class ESConsoleTest {

    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String ACCOUNT_TYPE_PARTNERS = 'Partners';
    static final String CONTACT_TYPE_PARTNER = 'Partner Contact';
    static final String ACCOUNT_PARTNER_TYPE_ACCOUNT = 'Partner Account';
    static final String ACCOUNT_PARTNER_TYPE_GROUP = 'Public Group';
    static final String PROJECT_TYPE_PARENT_SAAS = 'PS Parent Project - SaaS';
    static final String PROJECT_TYPE_PHASE_PREMISE = 'PS Project Phase Premise WFO';
    static final String PROJECT_TYPE_PARENT_PREMISE = 'PS Parent Project - Premise';
    static final String OPPORTUNITY_TYPE_NEW = 'New Opportunity';
    static final String CASE_TYPE_INCIDENT = 'Incident';
    static final String CASE_TYPE_EVENT = 'Event';

    static final Set<String> recordTypeSet = new Set<String>
    {
            ACCOUNT_TYPE_CUSTOMERS,
            ACCOUNT_TYPE_PARTNERS,
            CONTACT_TYPE_PARTNER,
            ACCOUNT_PARTNER_TYPE_ACCOUNT,
            ACCOUNT_PARTNER_TYPE_GROUP,
            OPPORTUNITY_TYPE_NEW,
            PROJECT_TYPE_PARENT_SAAS,
            PROJECT_TYPE_PARENT_PREMISE,
            PROJECT_TYPE_PHASE_PREMISE,
            CASE_TYPE_EVENT
    };

    static Map<String, Id> recordTypeMap = null;
    static List<User> userList = null;
    static List<Account> accountList = null;
    static List<Opportunity> oppList = null;
    static List<Project__c> projList = null;

    @TestSetup
    static void createTestData(){

        recordTypeMap = new Map<String, Id>();
        for(RecordType record : [
                Select Id, Name from RecordType
                where Name IN :recordTypeSet
        ])
        {
            recordTypeMap.put(record.Name, record.Id);
        }

        createUsers();
        createAccounts();
        createOpportunities();
        CreateProjects();

    } // end of createTestData()

    static void createUsers() {

        userList = new List<User>();
        Profile profile = [SELECT Id from Profile where Name = 'Implementation Management'];

        userList.add(
                new User(
                        FirstName = 'ES',
                        LastName = 'User1',
                        Email = 'user1@incontact.com',
                    	Team__c = 'Expert Services',
                        Username = 'esuser1@incontact.com',
                        Alias = 'test',
                        profileId = profile.Id,
                        EmailEncodingKey = 'UTF-8',
                        TimeZoneSidKey = 'America/Los_Angeles',
                        LocaleSidKey = 'en_US',
                        LanguageLocaleKey = 'en_US'
                )
        );
        userList.add(
                new User(
                        FirstName = 'IM',
                        LastName = 'User2',
                       	Email = 'user2@incontact.com',
                     	Team__c = 'CCI4',
                        Username = 'imuser1@incontact.com',
                      	Alias = 'test',
                    	profileId = profile.Id,
                        EmailEncodingKey = 'UTF-8',
                        TimeZoneSidKey = 'America/Los_Angeles',
                        LocaleSidKey = 'en_US',
                        LanguageLocaleKey = 'en_US'
                )
        );

        // avoid mixed dml operation
        system.runAs( new user( Id = UserInfo.getUserID() ) ) {
            insert userList;
        }
    } // end of createUsers

    static void createAccounts() {

        accountList = new List<Account>();
        accountList.add(
                new Account(
                        Name = 'ProjectTriggerHandlerTest Customer 1',
                        Type = 'Customer',
                        RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS)
                )
        );
        insert accountList;
    } // end of createAccounts

    static void createOpportunities(){

        oppList = new List<Opportunity>();
        oppList.add(
                new Opportunity(
                        Name = 'ProjectTriggerHandlerTest Opp 1',
                        AccountId = accountList[0].Id,
                        RecordTypeId = recordTypeMap.get(OPPORTUNITY_TYPE_NEW),
                        StageName = 'Prospecting',
                        CloseDate = Date.today(),
                        Probability = 25,
                        Partner_Deal__c = 'NO',
                        Contract_Type__c = 'New Customer',
                        inContact__c = 'YES',
                        inContact_Setup_Fee__c = 1000,
                        inContact_Seats__c = 1,
                        inContact_MRC_Min__c = 1000,
                        inContact_Ports__c = 1,
                        inContact_MRC_Exp__c = 1000,
                        ECHO__c = 'NO',
                        eLearning__c = 'NO',
                        Hiring__c = 'NO',
                        WFM__c = 'NO'
                )
        );
        insert oppList;
    } // end of createOpportunities()

    static void createProjects() {

        projList = new List<Project__c>();
        projList.add(
            new Project__c(
                TotalWorkLogHours__c = 40,
                ES_AssetCount__c = 4,
                ES_ProjectComplexity__c = 10,
                ES_Project_Color__c = 'ffffff',
                EstimatedProjectGoLiveDate__c = Date.today(),
                Account__c = accountList[0].Id,
                Opportunity__c = oppList[0].Id,
                OwnerId = userList[0].Id,
                Summary__c = 'Test Project 1',
                ES_PrevQ_PercentComplete__c = 40,
                PercentComplete__c = 40,
                RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_PREMISE),
                Phase_Status__c = 'Align',
                ProjectStatus__c = 'Align',
                ClosedDate__c = Date.today(),
                Team__c = 'Expert Services'
            )
        );
        insert projList;
    } // end of createProjects()


    static testMethod void projectMethodTests(){
        Test.startTest();

        PageReference myVfPage = Page.ExpertServicesDashboard;
        Test.setCurrentPage(myVfPage);
        ESConsole testController = new ESConsole();

        // Test phaseStatusMethod
        List<Project__c> projList = [Select Id from Project__c Where Summary__c = 'Test Project 1'];
        testController.projId = projList[0].Id;
        testController.fieldName = 'Build';
        testController.phaseStatusMethod();
        List<Project__c> resultList = [Select Phase_Status__c, ProjectStatus__c, Team__c from Project__c Where Id = : projList[0].Id];
        // Assertions
        System.Assert(resultList[0].Phase_Status__c == 'Build');
        System.Assert(resultList[0].ProjectStatus__c == 'Build');
        System.Assert(resultList[0].Team__c == 'Expert Services');

        // Test percentCompleteMethod
        testController.percentVal = 40;
        testController.percentCompleteMethod();
        List<Project__c> resultList2 = [Select PercentComplete__c from Project__c Where Id = : projList[0].Id];
        // Assertions
        System.Assert(resultList2[0].PercentComplete__c == 40);

        // Test projectColorMethod
        testController.colorHex = '000000';
        testController.projectColorMethod();
        List<Project__c> resultList3 = [Select ES_Project_Color__c from Project__c Where Id = : projList[0].Id];
        // Assertions
        System.Assert(resultList3[0].ES_Project_Color__c == '000000');

        // Test projectCompleteMethod
        testController.projectCompleteMethod();
        List<Project__c> resultList4 = [Select PercentComplete__c, Phase_Status__c, ProjectStatus__c from Project__c Where Id = : projList[0].Id];
        // Assertions
        System.Assert(resultList4[0].Phase_Status__c == 'Closed');
        System.Assert(resultList4[0].ProjectStatus__c == 'Completed');
        System.Assert(resultList4[0].PercentComplete__c == 100);

        // Test projectScoreMethod
        testController.projectScoreMethod();
        List<Project__c> resultList5 = [Select ES_Project_Scored__c from Project__c Where Id = : projList[0].Id];
        // Assertions
        System.Assert(resultList5[0].ES_Project_Scored__c == false);

        // Test estimatedGoLiveMethod
        testController.estimatedGoLive = '2017-01-01';
        testController.estimatedGoLiveMethod();   
        date myDate = date.newInstance(2017, 01, 01);
        List<Project__c> resultList6 = [Select EstimatedProjectGoLiveDate__c from Project__c Where Id = : projList[0].Id];
        // Assertions
        System.Assert(resultList6[0].EstimatedProjectGoLiveDate__c == myDate);

        Test.stopTest();
    }

    static testMethod void noteMethodTests(){
        Test.startTest();

        PageReference myVfPage = Page.ExpertServicesDashboard;
        Test.setCurrentPage(myVfPage);
        ESConsole testController = new ESConsole();

        // Test insertNotesMethod
        List<Project__c> projList = [Select Id from Project__c Where Summary__c = 'Test Project 1'];
        testController.projId = projList[0].Id;
        testController.noteTitle = 'Test Note Title';
        testController.noteBody = 'Test Note Body';
        testController.insertNotesMethod();
        List<Note> resultList = [Select Id, Title, Body From Note Where ParentId = : projList[0].Id ];
        // Assertions
        System.Assert(resultList[0].Title == 'Test Note Title');
        System.Assert(resultList[0].Body == 'Test Note Body');

        // Test getNotesMethod
        testController.getNotesMethod();
        // Assertions
        System.Assert(testController.queryNotesResult != null);

        Test.stopTest();
    }

    static testMethod void attachmentMethodTests(){
        Test.startTest();

        PageReference myVfPage = Page.ExpertServicesDashboard;
        Test.setCurrentPage(myVfPage);
        ESConsole testController = new ESConsole();

        // Test uploadFileMethod
        List<Project__c> projList = [Select Id from Project__c Where Summary__c = 'Test Project 1'];
        testController.projId = projList[0].Id;
        testController.fileBody = 'VGhpcyBpcyBhIHRleHQgZG9jLg==';
        testController.fileName = 'testDoc.txt';
        testController.uploadFileMethod();
        List<Attachment> resultList = [Select Id, Name, Body, ParentId From Attachment Where ParentId = : projList[0].Id ];
        // Assertions
        System.Assert(resultList[0].Name == 'testDoc.txt');
        System.Assert(resultList[0].Body == Blob.valueOf('VGhpcyBpcyBhIHRleHQgZG9jLg=='));

        // Test getAttachmentsMethod
        testController.getAttachmentsMethod();
        // Assertions
        System.Assert(testController.resultStringAttachments != null);

        Test.stopTest();
    }
}