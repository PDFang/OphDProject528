/**
 * Created by arnab.karsarkar on 1/3/2017.
 */
@isTest
public with sharing class ISWorkItemCreateExtnTest {

    private static testMethod void testWorkItemCreatePage(){

        Project__c testProject = CreateProject();
        Test.setCurrentPageReference(new PageReference('Page.ISWorkItemCreatePage'));
        System.currentPageReference().getParameters().put('CF00N390000043TyR_lkid', testProject.Id);

        ISTFSWorkItem__c isw = new ISTFSWorkItem__c();
        ApexPages.StandardController controller = new ApexPages.StandardController(isw);
        ISWorkItemCreateExtn extension = new ISWorkItemCreateExtn(controller);
        Schema.DescribeSObjectResult d = Schema.SObjectType.ISTFSWorkItem__c;
        Map<String,Schema.RecordTypeInfo> rtByNameMap = d.getRecordTypeInfosByName();

        extension.definitionOfDone = 'testDefDone';
        extension.acceptanceCriteria = 'testAccptCriteria';
        extension.recordTyp = rtByNameMap.get('User Story').getRecordTypeId();
        extension.getFields();
        extension.getRecordTypes();
        extension.Save();
        integer countItem = [select count() from ISTFSWorkItem__c limit 1];
        system.assertEquals(1, countItem);
        extension.SaveNew();
        extension.cancel();
    }

    private static testMethod void testWorkItemCreatePageDBError(){

        Project__c testProject = CreateProject();
        Test.setCurrentPageReference(new PageReference('Page.ISWorkItemCreatePage'));
        System.currentPageReference().getParameters().put('CF00N390000043TyR_lkid', testProject.Id);

        ISTFSWorkItem__c isw = new ISTFSWorkItem__c();
        ApexPages.StandardController controller = new ApexPages.StandardController(isw);
        ISWorkItemCreateExtn extension = new ISWorkItemCreateExtn(controller);
        extension.definitionOfDone = 'testDefDone';
        extension.acceptanceCriteria = 'testAccptCriteria';
        extension.recordTyp = null;
        extension.getFields();
        extension.getRecordTypes();
        extension.Save();
        integer countItem = [select count() from ISTFSWorkItem__c limit 1];
        system.assertEquals(0, countItem);
    }

    private static testMethod void testWorkItemCreatePageError1(){

        Project__c testProject = CreateProject();
        Test.setCurrentPageReference(new PageReference('Page.ISWorkItemCreatePage'));
        System.currentPageReference().getParameters().put('CF00N390000043TyR_lkid', testProject.Id);
        Schema.DescribeSObjectResult d = Schema.SObjectType.ISTFSWorkItem__c;
        Map<String,Schema.RecordTypeInfo> rtByNameMap = d.getRecordTypeInfosByName();
        ISTFSWorkItem__c isw = new ISTFSWorkItem__c();
        ApexPages.StandardController controller = new ApexPages.StandardController(isw);
        ISWorkItemCreateExtn extension = new ISWorkItemCreateExtn(controller);
        extension.definitionOfDone = '{testDefDone}';
        extension.acceptanceCriteria = 'testAccptCriteria';
        extension.recordTyp = rtByNameMap.get('User Story').getRecordTypeId();
        extension.getFields();
        extension.getRecordTypes();
        extension.Save();
        integer countItem = [select count() from ISTFSWorkItem__c limit 1];
        system.assertEquals(0, countItem);
    }

    private static testMethod void testWorkItemCreatePageRedirectTest(){

        Project__c testProject = CreateProject();
        Test.setCurrentPageReference(new PageReference('Page.ISWorkItemCreatePage'));
        System.currentPageReference().getParameters().put('CF00N390000043TyR_lkid', testProject.Id);
        Schema.DescribeSObjectResult d = Schema.SObjectType.ISTFSWorkItem__c;
        Map<String,Schema.RecordTypeInfo> rtByNameMap = d.getRecordTypeInfosByName();
        ISTFSWorkItem__c isw = new ISTFSWorkItem__c();
        ApexPages.StandardController controller = new ApexPages.StandardController(isw);
        ISWorkItemCreateExtn extension = new ISWorkItemCreateExtn(controller);
        extension.definitionOfDone = 'testDefDone';
        extension.acceptanceCriteria = '{testAccptCriteria}';
        extension.recordTyp = rtByNameMap.get('User Story').getRecordTypeId();
        extension.getFields();
        extension.getRecordTypes();
        extension.Save();
        integer countItem = [select count() from ISTFSWorkItem__c limit 1];
        system.assertEquals(0, countItem);
    }



    static Project__c CreateProject(){

        Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c;
        Map<String,Schema.RecordTypeInfo> rtByNameMap = d.getRecordTypeInfosByName();

        // known issue - https://success.salesforce.com/issues_view?id=a1p300000008XHBAA2
        // No choice but not to use 'IT Project Request' record type as it sends an workflow email alert
        Project__c testProject = new Project__c(
                TargetCompletionDate__c = system.today().addDays(5),
                Priority__c = 'High',
                Summary__c = 'Test Project',
                ProblemStatement__c = 'Need a feature',
                ProjectType__c = 'Corporate IT',
                ProjectSubType__c = 'SalesForce',
                What_kind_of_request__c = 'Feature Enhancement',
                ProjectStatus__c = 'New',
                Area__c = 'SalesForce',
                Team__c = 'Operations',
                TFSId__c = '1234',
                RecordTypeId = rtByNameMap.get('PSA Projects').getRecordTypeId(),
                //RecordTypeId = rtByNameMap.get(PROJECT_TYPE_IT).getRecordTypeId(),
                RequestedDeliveryDate__c = system.today().addDays(7),
                SyncToTFS__c = true
        );
        insert testProject;
        return testProject;
    }
}