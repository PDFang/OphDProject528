@isTest
public class CommonLibraryWebServicesTests 
{
    @testSetup static void setup()
    {
        //Create a new Account object
        Account acct = inContactBaseClass.CreateAccount('Test Account Customer');
        acct.CadebillAccountNo__c = 100001000;
        insert acct;
        
        Account masterAgent = inContactBaseClass.CreateAccount('Test Account Master Agent');
        masterAgent.CompanyId__c = '1525';
        insert masterAgent;
        
        Account subAgent = inContactBaseClass.CreateAccount('Test Account Sub Agent');
        subAgent.SalesEntityID__c = '1234';
        insert subAgent;
        
        Contact cntact = inContactBaseClass.CreateContact(acct.Id, 'firstName', 'lastName', 'email@test.com');
        cntact.ADFSGuid__c = 'abcdefg';
        insert cntact;
        
        Invoice__c i = new Invoice__c();
        i.Charge__c = 123;
        i.Invoice_Date__c = system.today() - 200;
        i.Transaction_Date__c  = system.today() - 200;
        i.SFDC_Acct_ID__c = acct.Id;
        i.InvoiceHistoryID__c = 'I1234';
        insert i;
        
    }
    
    static testMethod void Test_GetAccountIdsFromAccountNo_ReturnsAccountId()
    {
        double accountNo = 100001000;
        Integer[] acctNos = new Integer[]{integer.valueOf(accountNo)};
            
        CommonLibraryWebServices.AccountIdMap[] acctMap = CommonLibraryWebServices.GetAccountIdsFromAccountNo(acctNos);
            
        Account testAccount = [SELECT Id FROM Account WHERE CadebillAccountNo__c = :accountNo];
        system.assertEquals(testAccount.Id, acctMap[0].AccountId);
        
    }
    
    static testMethod void Test_GetAccountIdsFromCompanyId_ReturnsAccountId()
    {
        string companyId = '1525';
        String[] compIds = new String[]{companyId};
            
        CommonLibraryWebServices.CompanyIdMap[] compMap = CommonLibraryWebServices.GetAccountIdsFromCompanyId(compIds);
            
        Account testAccount = [SELECT Id FROM Account WHERE CompanyId__c = :companyId];
        system.assertEquals(testAccount.Id, compMap[0].AccountId);
        
    }
    
    static testMethod void Test_GetAccountIdsFromAgentId_ReturnsAccountId()
    {
        string agentId = '1234';
        String[] agtIds = new String[]{agentId};
            
        CommonLibraryWebServices.AgentIdMap[] agtMap = CommonLibraryWebServices.GetAccountIdsFromAgentId(agtIds);
            
        Account testAccount = [SELECT Id FROM Account WHERE SalesEntityId__c = :agentId];
        system.assertEquals(testAccount.Id, agtMap[0].AccountId);
        
    }
    
    static testMethod void Test_AddSaasPartnerAccount_CreatesAccount()
    {
        integer accountNo = 100001000;
         Account testAccount = [SELECT Id FROM Account WHERE CadebillAccountNo__c = :accountNo];
        CommonLibraryWebServices.TelcoSaasMap[] telcoSaasMap = new CommonLibraryWebServices.TelcoSaasMap[]{new CommonLibraryWebServices.TelcoSaasMap(accountNo,999999)};
        CommonLibraryWebServices.AddSaasPartnerAccount(telcoSaasMap);
        
        Account actual = [SELECT Id FROM Account WHERE CadebillAccountNo__c = 999999];
        system.assert(actual != null);
        
    }
    
    static testMethod void Test_DeleteAccountInvoices_DeletesInvoices()
    {
        integer accountNo = 100001000;
         Account testAccount = [SELECT Id FROM Account WHERE CadebillAccountNo__c = :accountNo];
        CommonLibraryWebServices.DeleteAccountInvoices(new String[]{testAccount.Id});
        
        system.assertEquals(0,[SELECT Count() FROM Invoice__c WHERE SFDC_Acct_ID__c = :testAccount.Id]);
        
    }
    
    static testMethod void Test_UpdateContactsByAdfsGuid_UpdatesContacts()
    {
        string adfsGuid = 'abcdefg';
        CommonLibraryWebServices.UpdateContactsByAdfsGuid(adfsGuid, 'NewName', 'lastName', 'email@test.com', '', '100 Main St', 'Boise', 'ID', '83702', 'USA');
        Contact con = [SELECT ID, FirstName, MailingStreet FROM Contact WHERE ADFSGuid__c = :adfsGuid LIMIT 1];
        
        system.assertEquals('NewName', con.FirstName);
        system.assertEquals('100 Main St',con.MailingStreet);
        
    }
}