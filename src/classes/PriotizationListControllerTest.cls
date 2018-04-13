/**
 * Created by arnab.karsarkar on 3/9/2017.
 */
@isTest
public with sharing class PriotizationListControllerTest {

    static final String PROJECT_TYPE_PMO = 'PMO Project';
    static final String PROJECT_TYPE_IT = 'IT Project Request';
    static final Set<String> recordTypeSet = new Set<String>
    {
            PROJECT_TYPE_PMO,
            PROJECT_TYPE_IT
    };
    static Map<String, Id> recordTypeMap = null;

    static list<String> ChannelSet = new list<String>();


    // create a permission set and assign to the user
    private static void createPermissionSetUser(){
        //CreatePermissionSet
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test';
        ps.Label = 'Test';
        insert ps;
        // Assign the custom permission
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'ChangeGlobalPriortyPermission'][0].Id;
        insert sea;

        // assign current user
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = UserInfo.getUserId();
        psa.PermissionSetId = ps.Id;
        insert psa;

    }

    // Add one record to the Permission history object
    private static void CreateHistoryRecord(){

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];

        User u1 = new User(Alias = 'test1', Email='test1@testorg.com',
                EmailEncodingKey='UTF-8', LastName='testTesting1', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='test17652345422@testorg.com');
        insert u1;

        system.runAs(u1){
            Project_Prioritization_History__c hist = new Project_Prioritization_History__c(
                    Channel__c = 'Foundation'
            );
            insert hist;
        }

    }

    private static void createTestData(){
        recordTypeMap = new Map<String, Id>();
        for(RecordType record : [
                Select Id, Name from RecordType
                where Name IN :recordTypeSet
        ])
        {
            recordTypeMap.put(record.Name, record.Id);
        }

        List<Project__c> projectListPMO = new List<Project__c>();
        List<Project__c> projectListIT = new List<Project__c>();
        GanttProjectPriotizationListController gp = new GanttProjectPriotizationListController();

        for(integer i = 0; i < gp.filterOptions.size(); i++){
            ChannelSet.add(gp.filterOptions[i].getValue());
        }

        for(integer i = 0; i < ChannelSet.size(); i++){
            Project__c project = new Project__c();
            project.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PMO);
            project.Summary__c = 'Test' + i;
            project.Description__c = 'Test Desc' + i;
            project.Primary_Product__c = ChannelSet[i];
            project.BattingOrder__c = i;
            project.Ops_Backlog_Priority__c = i;
            project.ExpectedDeliveryDate__c = system.today().addDays(10);
            projectListPMO.add(project);
        }

        insert projectListPMO;

        for(integer i = 0; i < projectListPMO.size(); i++){
            Project__c project = new Project__c();
            project.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_IT);
            project.Summary__c = 'Test' + i;
            project.Description__c = 'Test Desc' + i;
            project.ParentProject__c = projectListPMO[i].id;
            projectListIT.add(project);
        }

        insert projectListIT;


        SiteConfiguration__c sbx = new SiteConfiguration__c();
        sbx.Name = inContactBaseClass.OrgId15Digit;
        sbx.AutoEventEmails__c = true;
        sbx.DaysToDisplayKnownIssues__c = 30;
        sbx.OrgId__c = inContactBaseClass.OrgId15Digit;
        sbx.EventResolvedPriorities__c = 'P1;P2;';
        sbx.EventResolvedEmails__c = true;
        sbx.ProjectSortExcludedStatus__c = 'Active/Being Worked,User Acceptance,Ready to Deploy,Completed,Closed,Canceled';

        insert sbx;
    }


    // test permission
    public static testMethod void  testPermission(){
        createPermissionSetUser();
        CreateHistoryRecord();
        GanttProjectPriotizationListController gp = new GanttProjectPriotizationListController();
        Test.setCurrentPageReference(new PageReference('Page.GanttProjectList'));
        System.currentPageReference().getParameters().put('programName', 'Foundation');
        gp.editAccessCheck();
        system.assertEquals(true,gp.hasEditAccess);
        system.assertEquals(false,gp.showUnlock);
    }

    // test picklists
    public static testMethod void  testPicklistValues(){
        createPermissionSetUser();
        CreateHistoryRecord();
        GanttProjectPriotizationListController gp = new GanttProjectPriotizationListController();
        system.assertNotEquals(0,gp.filterOptions.size());
    }


    // test picklists
    public static testMethod void  testUnprioritized(){
        list<ProjectListDataFields> dataList = new list<ProjectListDataFields>();
        createTestData();
        test.startTest();
        string projects =  GanttProjectPriotizationListController.GetUnpriortizedProjects('Foundation', 'PMO');
        dataList = (list<ProjectListDataFields>)JSON.deserialize(projects, list<ProjectListDataFields>.Class);
        system.debug('datalist size =>' + dataList.size());
        //system.assertEquals(1, dataList.size());
        GanttProjectPriotizationListController.GetUnpriortizedProjects('All', 'IT');
        test.stopTest();
    }

    // test picklists
    public static testMethod void  testPrioritized(){
        list<ProjectListDataFields> dataList = new list<ProjectListDataFields>();
        createTestData();
        test.startTest();
        string projects =  GanttProjectPriotizationListController.GetPriortizedProjects('Foundation', 'PMO');
        dataList = (list<ProjectListDataFields>)JSON.deserialize(projects, list<ProjectListDataFields>.Class);
        system.debug('datalist size =>' + dataList.size());
        //system.assertEquals(5, dataList.size());
        GanttProjectPriotizationListController.GetPriortizedProjects('All', 'IT');
        Test.stopTest();
    }

    // test validate history record & cancel Edit
    public static testMethod void  testValidateEdit(){
        CreateHistoryRecord();
        string error = GanttProjectPriotizationListController.ValidateEdit('Foundation');
        system.debug('error =>' + error);
        string expected = 'You cannot edit the..';
        system.assertEquals(expected.startsWith('You'), error.startsWith('You'));

        string sfdcId = GanttProjectPriotizationListController.ValidateEdit('Business Operations');
        integer expectedIdLength = 18;
        system.assertEquals(expectedIdLength, sfdcId.length());
        GanttProjectPriotizationListController.ContinueSession(sfdcId);
        GanttProjectPriotizationListController.CancelEdit(sfdcId);
        Project_Prioritization_History__c[] hist = [select id from Project_Prioritization_History__c where id = :sfdcId];
        system.assertEquals(0, hist.size());

    }

    // test unlock Edit
    public static testMethod void  testUnlockEdit(){
        CreateHistoryRecord();
        GanttProjectPriotizationListController.UnlockEdit('Foundation');
    }
    // test save recird
    public static testMethod void  testSave(){

        CreateHistoryRecord();
        User userTest = [select Id from User where Username = 'test17652345422@testorg.com'];
        system.runAs(userTest) {
            createTestData();
            Project__c[] PMOProjects = [select Id, BattingOrder__c from Project__c where RecordType.Name = :PROJECT_TYPE_PMO and BattingOrder__c = 0];
            string JSONString = '[{"ProjectId":"' + PMOProjects[0].id + '","Priority":6}]';
            Test.startTest();
            string error = GanttProjectPriotizationListController.Save(JSONString, 'Foundation', null);
            Test.stopTest();
            Project__c[] ITProjects = [select Id, RoadMapPriority__c from Project__c where RecordType.Name = :PROJECT_TYPE_IT and ParentProject__c = :PMOProjects[0].Id];
            //system.assertEquals(6, ITProjects[0].RoadMapPriority__c);

        }
    }

    /*** Creating a test method for SortProjectPriorityController **/

    public static testMethod void testSortControlScript(){
        createTestData();
        SortProjectPriorityController sp = new SortProjectPriorityController();
        list<Project__c> lstProjects = sp.getProjectLists();
        //system.assertEquals(5, lstProjects.size());
        string sfdcId = lstProjects[0].Id;
        sp.sort();
        Project__c newProject = [select Id, BattingOrder__c from Project__c where Id = :sfdcId];
        system.assertEquals(1, newProject.BattingOrder__c);
        sp.refreshProjects();
    }

}