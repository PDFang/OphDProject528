@isTest
private class OpportunitiesCSUpsells {

	public static list<Opportunity> CSopportunities = new List<Opportunity>();    
    public static list<Opportunity> opportunities = new List<Opportunity>();
    public static Id csRecordTypeNew = null;
    public static Id csRecordTypeSales = null;
    public static void createActOppy()
    {
		List<Account> accounts = new List<Account>();
        
        
        //get user for active sales rep
        ID anyUser = [SELECT ID FROM User WHERE IsActive = TRUE LIMIT 1].Id;
       
        //get CS-Upsell record type id
        Id csRecordType = [SELECT rt.Id FROM RecordType rt WHERE rt.sobjectType = 'Opportunity' AND rt.Name = 'SaaS Request'].Id;
        
        //get Sales record type id
        csRecordTypeNew = [SELECT rt.Id FROM RecordType rt WHERE rt.sobjectType = 'Opportunity' AND rt.Name = 'New Opportunity'].Id;
        csRecordTypeSales = [SELECT rt.Id FROM RecordType rt WHERE rt.sobjectType = 'Opportunity' AND rt.Name = 'Qualified Opportunity'].Id;
        
        system.debug('---------------  Start Test  --------------------');
        //Build Test account
		for (Integer i=0; i < 20; i++){
			Account a = new Account();
			a.Name = 'testName' + i;
			a.Site = string.valueOf(i);
			a.Active_Sales_Rep__c = anyUser;
			accounts.add(a);
		}
		insert accounts;
        system.debug('---------------  accounts inserted  --------------------');        
        
        //create CS-Upsells Opportunity
		for(Account a:accounts)
		{        
        	Opportunity o = new Opportunity();
        	o.name=a.Name + 'Opportunity';
        	o.AccountID = a.ID;
        	o.StageName='Selling & Scoping';
        	o.CloseDate=date.Today();
        	o.RecordTypeID = csRecordType;
        	o.Probability = 25;
        	o.Partner_Deal__c = 'NO';
        	o.Project__c = true;
        	o.Project_Budget__c = true;
        	o.Project_Owner__c = true;
        	o.Project_Timeline__c = true;
        	o.Project_Detail__c = 'blah blah';
        	o.Project_Owner_Detail__c = 'me';
        	o.Project_Budget_Detail__c = 1000;
        	o.Project_Timeline_Detail__c = date.today();
        	o.Contract_Type__c = 'New Customer';
        	o.inContact__c = 'YES';
        	o.inContact_Setup_Fee__c = 1000;
        	o.inContact_Seats__c = 1;
        	o.inContact_MRC_Min__c = 1000;
        	o.inContact_Ports__c = 1;
        	o.inContact_MRC_Exp__c = 1000;
        	o.ECHO__c = 'NO';
        	o.eLearning__c = 'NO';
        	o.Hiring__c = 'NO';
        	o.WFM__c = 'NO';
        	o.OwnerId = anyUser;
        	o.Account_Sales_Rep__c = anyUser;
        	CSopportunities.add(o);
		}
        
         insert CSopportunities;
        
        //test for Stage Name Chage
        for(Account a:accounts)
		{        
        	Opportunity o = new Opportunity();
        	o.name=a.Name + 'Opportunity';
        	o.AccountID = a.ID;
        	o.StageName='Selling & Scoping';
        	o.RecordTypeId = csRecordTypeNew;
        	o.CloseDate=date.Today();
        	o.Probability = 25;
        	o.Partner_Deal__c = 'NO';
        	o.Project__c = true;
        	o.Project_Budget__c = true;
        	o.Project_Owner__c = true;
        	o.Project_Timeline__c = true;
        	o.Project_Detail__c = 'blah blah';
        	o.Project_Owner_Detail__c = 'me';
        	o.Project_Budget_Detail__c = 1000;
        	o.Project_Timeline_Detail__c = date.today();
        	o.Contract_Type__c = 'New Customer';
        	o.inContact__c = 'YES';
        	o.inContact_Setup_Fee__c = 1000;
        	o.inContact_Seats__c = 1;
        	o.inContact_MRC_Min__c = 1000;
        	o.inContact_Ports__c = 1;
        	o.inContact_MRC_Exp__c = 1000;
        	o.ECHO__c = 'NO';
        	o.eLearning__c = 'NO';
        	o.Hiring__c = 'NO';
        	o.WFM__c = 'NO';
        	o.OwnerId = anyUser;
        	o.Account_Sales_Rep__c = anyUser;
        	opportunities.add(o);
		}
        insert opportunities; 
        
        
    }
    
    public static testMethod void validateCSUpsales()
    {
        createActOppy(); 
        Set<ID> newOpps = new Set<ID>();
        
        
 		Test.startTest();        
 		for(Opportunity o:CSopportunities)
        {
        	o.RecordTypeId = csRecordTypeSales;
        	newOpps.add(o.Id);
        }
        update CSopportunities;                
		                  
        for (Opportunity o:[SELECT Id, Account_Sales_Rep__c, OwnerId, Account.Active_Sales_Rep__c, Probability, Name, Account_Sales_Rep__r.Name FROM Opportunity WHERE Id IN :newOpps])
        {
        	system.assertEquals(o.Account_Sales_Rep__c,o.Account.Active_Sales_Rep__c);
        	System.assertEquals(25,o.Probability);
        	System.assertEquals(o.Account_Sales_Rep__c,o.OwnerId);
        	system.debug('*******************************************************************');
        	system.debug('Opportunity Name: ' + o.Name);
        	system.debug('Account Sales Rep: ' + o.Account_Sales_Rep__r.Name);
        	system.debug('*******************************************************************');
        }
       Test.stopTest();
    }
       
    public static testMethod void validateCSStage()
    {
        createActOppy(); 
        Set<ID> stNewOpps = new Set<ID>();
        Test.startTest();
        for(Opportunity o:opportunities)
        {
        	o.RecordTypeId = csRecordTypeNew;
            o.StageName = '2 - Determining Problem / Impact';
        	stNewOpps.Add(o.Id);
        }
        update opportunities;                
        
        for (Opportunity o:[SELECT Id, Name, RecordTypeId FROM Opportunity WHERE Id IN :stNewOpps])
        {
        	
        	System.assertEquals(o.RecordTypeId,csRecordTypeSales);
        	system.debug('*******************************************************************');
        	system.debug('Opportunity Name: ' + o.Name);
        	system.debug('*******************************************************************');
        }		
       Test.stopTest();
        
    }
        
}