@isTest
public class TfsWorkItemTestClass 
{
	
    static testMethod void TestTfsWorkItemTriggers()
    {
        //set mock for creating TFS Item
        Test.setMock(WebServiceMock.class, new ITfsIntegrationProxy()); 
        
        TfsWorkItem__c workItem = new TfsWorkItem__c();
        workItem.Name = '45';
        
        insert workItem;
        
        string uptivityIncidentRecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Incident - Premise', 'Case');
        Case c = TestUtilities.CreateCase(null, null, uptivityIncidentRecordTypeId, 'Test Case');
        c.TfsWorkItem__c = workItem.Id;
        insert c;
        
        //fire off callout
        workItem.StackRank__c = 2.5;
        update workItem;
        
        //testing changing of uptivity status updates the case
        workItem.UptivityState__c = 'Awaiting Support Info';
        update workItem;
        
        c = [SELECT Id, Status FROM Case WHERE Id = :c.Id];
        system.assertEquals('Awaiting Support Info', c.Status);
        
        workItem.UptivityState__c = 'Customer Verify';
        update workItem;
        
        c = [SELECT Id, Status FROM Case WHERE Id = :c.Id];
        system.assertEquals('Customer Verify', c.Status);
    }
    
    static testMethod void TestTfsWorkItemCreateExtension()
    {
        TestUtilities.CreateTfsAssignment('Uptivity Incident','iWFO Sustain 1');
        
        //set mock for creating TFS Item
        Test.setMock(WebServiceMock.class, new ITfsIntegrationProxy());
        
        //create test account
        Account a = inContactBaseClass.CreateAccount('testName');
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
                
        insert a;
        System.debug('Insert accounts.');
        
        //get record type IDs
        Id rtIncident = '01270000000LuEpAAK';
        Id rtInfo = '01270000000LuEqAAK';
        Id rtWO = '01270000000LuErAAK';
        Id rtCustOther = '01270000000Lrn4AAC';
        
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
                            
        insert ct;
        
        //create test case      
        Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, rtWO, a.Name);
        c.Request_Type__c = 'Adds/Moves/Changes';
        c.Product_or_Service__c = 'DIA';
        c.Status = 'New';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';
        
        insert c;
        
        TfsWorkItem__c workItem = new TfsWorkItem__c();
        
        
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(workItem);
        TfsWorkItemCreateExtension tfsExtensionNoCaseId = new TfsWorkItemCreateExtension(stdCtrl);
        
        
        ApexPages.currentPage().getParameters().put('caseId','bad case id');
        TfsWorkItemCreateExtension tfsExtensionBadCaseId = new TfsWorkItemCreateExtension(stdCtrl);
        
        ApexPages.currentPage().getParameters().put('caseId',string.valueOf(c.Id));
        
        TfsWorkItemCreateExtension tfsExtension = new TfsWorkItemCreateExtension(stdCtrl);
        
        system.assertEquals(c.Subject, workItem.Title__c);
        system.assert(tfsExtension.renderPage);
        
        workItem.ExistsIn__c = 'Production';
        workItem.FoundBy__c = 'Customer';
        
        tfsExtension.SaveWorkItem();
        tfsExtension.CreateTfsItem();
        tfsExtension.GoToCase();
        
        //system.assert(tfsExtension.workItem.Id != null);
        
    }
    
    
}