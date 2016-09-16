@isTest
private class SalesEngineeringLogicTests
{
    
    
	static testMethod void TestSalesEngineeringLogic()
    {
        
        Account a = new Account();
        a.Name = 'Test Account';
        a.CustomerTemperature__c = 'Mad';
        a.CustomerTemperatureDate__c = system.now();
        insert a;
        
        List<Opportunity> opportunities = new List<Opportunity>();
        
        for(integer i=0;i<10;i++)
        {
            Opportunity o = new Opportunity();
            o.Name = 'Test' + string.valueOf(i);
            o.AccountId = a.Id;
            o.StageName = 'Assigned';
            o.CloseDate = Date.today();
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
            o.SalesEngineer__c = UserInfo.getUserId();
            opportunities.add(o);
        }
        
        insert opportunities;
        //[SELECT Id FROM User WHERE Id = :UserInfo.getUserId() AND IsActive = true AND UserType = 'Standard' LIMIT 1].Id
        opportunities[1].SalesEngineer__c = userinfo.getUserId();
        update opportunities[1];
        
        Integer numberOfProjects = [SELECT Count() FROM Project__c];
        system.assertEquals(numberOfProjects,10);
    }
}