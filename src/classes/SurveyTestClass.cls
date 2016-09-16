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
    
    //Test Account Manager  Survey - Placeholder
   static testMethod void TestCaseSendAMSurveyClass()
    {
        Account a = inContactBaseClass.CreateAccount('AMSurveytestName');
        a.Site = 'Test';
        a.CSM__c = UserInfo.getUserId(); 
        a.CadebillAccountNo__c = 111000;
                
        insert a;
        System.debug('*********Insert accounts***********');
        
        //get record type IDs
        Id rtWO = '01270000000LuErAAK';
        Id rtCustOther = '01270000000Lrn4AAC';
        
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
        ct.Referenceable__c = true;            
        insert ct;
        
        //create tech support test case     
        Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, rtWO, a.Name);
        c.Request_Type__c = 'Adds/Moves/Changes';
        c.Product_or_Service__c = 'DIA';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';
		c.OwnerId = '00G70000002C7K7EAK'; // TSM Queue Id
        insert c;
        
		c.ResolvedBy__c = UserInfo.getUserId();
        c.Status = 'Closed';
        update c;

        test.startTest();
        //Trigger Send Survey
        CaseSendSurvey.SendAMSurvey(new Set<Id>{c.Id});
 		test.stopTest();
    }
 	
    //Test SDS Survey - Placeholder
   static testMethod void TestCaseSendSDSSurveyClass()
    {
        Account a = inContactBaseClass.CreateAccount('SurveytestName');
        a.Site = 'Test';
        a.CSM__c = UserInfo.getUserId(); 
        a.CadebillAccountNo__c = 111000;
                
        insert a;
        System.debug('*********Insert accounts***********');
        
        //get record type IDs
        Id rtWO = '01270000000LuErAAK';
        Id rtCustOther = '01270000000Lrn4AAC';
        
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
        ct.Referenceable__c = true;            
        insert ct;
        
        //create tech support test case     
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
        CaseSendSurvey.SendSDSSurvey(new Set<Id>{c.Id});
        test.stopTest();
    }
       
    //Uptivity/Premise Survey Test Method
    static testMethod void TestPremiseCaseSendSurveyClass() 
    {
        //get record type IDs
        Id rtWFOPremCust = '01270000000MzcRAAS';
        Id rtIU = '01270000000MzcW'; 
        Id rtCustOther = '01270000000Lrn4AAC';
        List<Account> testAccounts = new List<Account>();
        List<Contact> testContacts = new List<Contact>();
        List<Case> testCases = new List<Case>(); 
        
        //create Uptivity accounts
        Account a = inContactBaseClass.CreateAccount('PremiseSurveyTestName',rtWFOPremCust);
        a.Site = 'Test';
		a.CSM__c = UserInfo.getUserId(); 
        testAccounts.add(a);
        
        Account pa2 = inContactBaseClass.CreateAccount('SurveytestName', rtWFOPremCust);
        pa2.Site = 'Test2';
        pa2.CSM__c = UserInfo.getUserId(); 
        testAccounts.add(pa2);

        insert testAccounts;
        System.debug('***********Insert account*************');
        
        //create contacts
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
        ct.Referenceable__c = true;            
        testContacts.add(ct);
        
        Contact ct2 = inContactBaseClass.CreateContact(pa2.Id, 'firstName2', 'lastName2', 'email2@test.com', rtCustOther);
        ct2.Referenceable__c = true;            
        testContacts.add(ct2);
        
        insert testContacts;
        
		//create case    
        Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, rtIU, a.Name);
        c.Request_Type__c = 'WFO';
        c.Product_or_Service__c = 'WFO - Premise';
        c.Priority = 'P4';
        c.OwnerId = '00G70000002Cwz9'; //Premise Tech Support Queue Id
        testCases.add(c);        
                
        Case c2 = inContactBaseClass.CreateCase(a.Id, ct.Id, rtIU, a.Name);
        c2.Request_Type__c = 'WFO';
        c2.Product_or_Service__c = 'WFO - Premise';
        c2.Priority = 'P4';
  	    c2.OwnerId = '00G70000002D06EEAS'; //Premise TSM Queue Id
        testCases.add(c2);
        
        insert testCases;
        
        //Update status to test CaseBeforeUpdate trigger code
        c.Status = 'Closed';
        update c;
        
        c2.Status = 'Closed';
        update c2;
        
        //Trigger Send Survey
        CaseSendSurvey.TechSupportSurveyMain(new Set<Id>{c.Id});  
    }
    
    //Uptivity/Premise Optimization Survey Test Method
    static testMethod void TestSendPremiseOptimizationSurveyClass() 
    {
        //get record type IDs
        Id rtWFOPremCust = '01270000000MzcRAAS';
        Id rtIU = '01270000000MzcW'; 
        Id rtCustOther = '01270000000Lrn4AAC';
        List<Account> testAccounts = new List<Account>();
        List<Contact> testContacts = new List<Contact>();
        List<Case> testCases = new List<Case>();
        
        //create Uptivity account
        Account a = inContactBaseClass.CreateAccount('PremiseOptimizationSurveyTestName',rtWFOPremCust);
        a.Site = 'Test';
        testAccounts.add(a);
                                    
        insert testAccounts;
        System.debug('***********Insert account*************');
        
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
        ct.Referenceable__c = true;            
        testContacts.add(ct);
        
        insert testContacts;
        
		//create case    
        Case c = inContactBaseClass.CreateCase(a.Id, ct.Id, rtIU, a.Name);
        c.Request_Type__c = 'WFO';
        c.Product_or_Service__c = 'WFO - Premise';
        c.Priority = 'P4';
        c.OwnerId = '00G70000002Cwz7';
        testCases.add(c);
        
        insert testCases;
        
        //Update status to test CaseBeforeUpdate trigger code
        c.Status = 'Closed';
        update c;
        
        test.startTest();
        //Trigger Send Survey
        CaseSendSurvey.SendPremiseInstallationSurvey(new Set<Id>{c.Id});
        test.stopTest();
    }
     
    //Customer Success Survey Test Method
    static testMethod void TestSendCSSurveyClass() 
    {
        //get record type IDs
        Account a = inContactBaseClass.CreateAccount('CustomerSuccessSurveytestName');
        a.Site = 'Test';
        a.CSM__c = UserInfo.getUserId(); 
        a.CadebillAccountNo__c = 111000;
                
        insert a;
        System.debug('*********Insert accounts***********');
        
        //get record type IDs
        Id rtWO = '01270000000LuErAAK';
        Id rtSR = '01270000000LuEq';
        Id rtCustOther = '01270000000Lrn4AAC';
        
        //create contact
        Contact ct = inContactBaseClass.CreateContact(a.Id, 'firstName', 'lastName', 'email@test.com', rtCustOther);
        ct.Referenceable__c = true;            
        insert ct;
        
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
        
        //create Service Request test case     
        Case src = inContactBaseClass.CreateCase(a.Id, ct.Id, rtSR, a.Name);
        src.Request_Type__c = 'Connectivity';
        src.Product_or_Service__c = 'Toll Free';
        src.Priority = 'P4';

        insert src;
     
        c.Status = 'Closed';
        update src;
        
        test.startTest();
        //Trigger Send Survey
        CaseSendSurvey.SendCSSurvey(new Set<Id>{c.Id});  
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
        CaseSendSurvey.SendCSSurvey(new Set<Id>{c.Id});  
        test.stopTest();
    }
}//End Survey Test Class