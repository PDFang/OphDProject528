@isTest
private class DemoOpportunityTriggerHandlerTest {

    static testmethod void updateOpportunityNameTest(){
        
        //Create a test Account
        Account acct = inContactBaseClass.CreateAccount('Test Account');
        acct.CadebillAccountNo__c = 9999991;
        insert acct;
        
        User salesUser = [Select Id from User where Profile.Name = 'Sales Management' and isActive = true limit 1];
        
        test.startTest();
        // create few opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        for(Integer i = 0; i < 20; i++){
            oppList.add(new Opportunity(
            	Name = 'Opportunity ' + i,
                AccountId = acct.Id,
                StageName = '1 - Identification / Qualification',
                CloseDate = system.today().addMonths(1)
            ));
        }
        // Running test as sales user
        system.runAs(salesUser){
        	insert oppList;
        }            
        test.stopTest();
        
        // assert results
        for( Opportunity opp :[
            Select Name, Account.Name from Opportunity where Id IN :oppList
        ]){
            system.assert(opp.Name.endsWith(opp.Account.Name));
        }
        
    } // end of updateOpportunityNameTest()    	
    
}