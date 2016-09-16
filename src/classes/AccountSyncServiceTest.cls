@isTest
public class AccountSyncServiceTest 
{
	@testSetup static void setup()
    {
        
        ServiceConnection__c serCon = new ServiceConnection__c();
        serCon.Name = 'AccountSync';
        serCon.EndPoint__c = 'https://test.com/AccountSync';
        serCon.Password__c = 'pw';
        serCon.Username__c = 'test';
        insert serCon;
        
        
        //Create a new Account object
        Account acct = inContactBaseClass.CreateAccount('Test Account Customer');
        acct.CadebillAccountNo__c = 100001;
        insert acct;
    }
    
    static testMethod void testAccountSyncAccountUpdate()
    {        
        Test.setMock(WebServiceMock.class, new AccountSyncServiceMock());
        
        Test.startTest();
        //run webservice
        AccountSyncWebServices.AccountSync(100001);
        Test.stopTest();
    }
}