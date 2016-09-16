@IsTest()
public class TfsIntegrationTestClass 
{

    static testMethod void TestTfsWorkItemCreateExtension()
    {
        TfsWorkItem__c workItem = new TfsWorkItem__c();
        workItem.StepsToRecreate__c = 'test';
        
        string recordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Incident - Premise', 'Case');
        Case c = TestUtilities.CreateCase(null, null, recordTypeId, 'Test Case');
        insert c;
        
        
        Apexpages.currentpage().getParameters().put('caseId',c.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(workItem);
        TfsWorkItemCreateExtension extension = new TfsWorkItemCreateExtension(controller);
        
        extension.SaveWorkItem();
        Test.startTest();
        extension.CreateTfsItem();
        Test.stopTest();
    }
}