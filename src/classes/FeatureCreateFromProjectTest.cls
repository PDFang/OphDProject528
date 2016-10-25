@isTest
public class FeatureCreateFromProjectTest {
    static final string PROJECT_TYPE_PSA = 'PSA Projects';
       
    private  static testmethod void  FeatureCreateTest(){
        
        Project__c testProject = CreateProject();
        
       
        test.startTest();
        ApexPages.StandardController controller = new ApexPages.StandardController(testProject);
        FeatureCreateFromProject feature = new FeatureCreateFromProject(controller);
        feature.getArea();
        feature.getTeam();
        feature.selectedArea = 'SalesForce';
        feature.selectedTeam = 'Operations';
        feature.save();
        feature.Cancel();
        test.stopTest();
        
        Project__c result = [select TFSId__c, Area__c, Team__c,SyncToTFS__c from Project__c where Id = :testProject.Id];          
        system.assertEquals('SalesForce', result.Area__c);
        system.assertEquals('Operations', result.Team__c);
        
    } 
    
    @isTest static void  FeatureCalloutTest(){
        
        Project__c testProject = CreateProject();
        testProject.Area__c = 'SalesForce';
        testProject.Team__c = 'Operations';
        update testProject;
       
        test.startTest();
        ApexPages.StandardController controller = new ApexPages.StandardController(testProject);
        FeatureCreateFromProject feature = new FeatureCreateFromProject(controller);
        Test.setMock(HttpCalloutMock.class, new ISTFSINTEGRATIONCLASSMOCKTEST());
        feature.callTFS();
        test.stopTest();
        
        Project__c result = [select TFSId__c, Area__c, Team__c,SyncToTFS__c from Project__c where Id = :testProject.Id];        
        system.assertEquals(false, result.SyncToTFS__c);
        system.assertEquals(result.TFSId__c, '1234');    
    }   
    
    
    private static Project__c CreateProject(){
      
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
                TFSId__c = '0',
                RecordTypeId = rtByNameMap.get(PROJECT_TYPE_PSA).getRecordTypeId(),
                //RecordTypeId = rtByNameMap.get(PROJECT_TYPE_IT).getRecordTypeId(),
                RequestedDeliveryDate__c = system.today().addDays(7),
                SyncToTFS__c = false
        );
        insert testProject;        
        return testProject;
    }
    
    
}