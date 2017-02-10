@isTest(SeeAllData=true)
private class SurveyTestClass 
{
	//Test SaaS Tech Support Survey
   static testMethod void TestCaseSendSurveyClass()
    {
        //Create test account
        Account a = inContactBaseClass.CreateAccount('TechSupportSurveytestName');
        a.Site = 'Test';
        a.CSM__c = UserInfo.getUserId(); 
        a.CadebillAccountNo__c = 111000;
                
        insert a;
        System.debug('*********Insert accounts***********');
        
        //get record type IDs
        Id rtIn = '01270000000LuEp';
        Id rtCustOther = '01270000000Lrn4AAC';
        
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
        ct.Referenceable__c = true;            
        insert ct;
        
        System.debug('*********Insert Contact ***********');
        //create tech support test case     
        Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, rtIn, 'Tech Support Incident Survey Generation Test');
        c.Request_Type__c = 'Add/Move/Change';
        c.Product_or_Service__c = 'Circuits';
        c.Freqeuncy__c = 'Occasional';
        c.Severity__c = 'S4';
        c.Priority = 'P4';
        c.OwnerId = '00G70000001ciRaEAI'; //Tech Support Queue Id
      	insert c;

        c.ResolvedBy__c = UserInfo.getUserId();
        c.Status = 'Closed';
        update c;

        test.startTest();
        //Trigger Send Survey
        CaseSendSurvey.TechSupportSurveyMain(new Set<Id>{c.Id});
        test.stopTest();
    }

    //Test no contact email address on contact record
    static testMethod void TestNoEmailAddressClass() 
    {
        //get record type IDs
        Account a = inContactBaseClass.CreateAccount('SurveyNoContactEmailAddress');
        a.Site = 'Test';
        a.CSM__c = UserInfo.getUserId(); 
        a.CadebillAccountNo__c = 111000;
                
        insert a;
        System.debug('*********Insert accounts***********');
        
        //get record type IDs
        Id rtWO = '01270000000LuErAAK';
        Id rtCustOther = '01270000000Lrn4AAC';
        
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', '', rtCustOther);
        ct.Referenceable__c = true;            
        insert ct;
        
        //ct.email = '';
        //update ct;
        
        //create Work Order test case     
        Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, rtWO, a.Name);
        c.Request_Type__c = 'Adds/Moves/Changes';
        c.Product_or_Service__c = 'DIA';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';
                
        insert c;

        c.Status = 'Closed';
        update c;
        
        test.startTest();
        //Trigger Send Survey
        CaseSendSurvey.TechSupportSurveyMain(new Set<Id>{c.Id});
        test.stopTest();
    }
}