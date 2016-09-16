@isTest
private class CommunityCaseTest 
{
    
    public static testMethod void TestCommunityCaseCloseExtension() 
    {
		//create test account
        Account a = inContactBaseClass.CreateAccount('testName');
        a.Site = 'Test';
                
        insert a;
        System.debug('Insert accounts.');
        
        //get record type IDs
        Id rtUptivityIncident = inContactBaseClass.SelectRecordTypeIDByName('Incident - Premise','Case'); 
        Id rtContact = inContactBaseClass.SelectRecordTypeIDByName('Customer-Other','Contact');
        
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtContact);
        insert ct;
        
                
        //create test case      
        Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, rtUptivityIncident, a.Name);
        c.Request_Type__c = 'WFO';
        c.Product_or_Service__c = 'WFO-Fusion';
        c.Status = 'New';
        c.Priority = 'P4';
        
        insert c;
        
        CaseComment comment = new CaseComment();
    	comment.CommentBody = 'Test';
    	
        //Test StandardTextExtension
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(comment);
        ApexPages.currentPage().getParameters().put('parent_id', c.id);
        CommunityCaseCloseExtension extension = new CommunityCaseCloseExtension(stdCtrl);
        
		extension.Save();
		extension.Cancel();        
    }
    
}