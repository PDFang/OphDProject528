public class AccountHighlightsExtension 
{
    private final Account a;
    private GYR__c gyr;
    private Integer openCases;
    public boolean isVerizon{get;set;}
    public boolean isSiemens{get;set;}
    
    public AccountHighlightsExtension(ApexPages.StandardController controller) 
    {
        this.a = (Account)controller.getRecord();
        isVerizon = false;
        
        if([SELECT COUNT() FROM GYR__c WHERE Account__c = :a.Id AND GYREndDate__c = NULL] == 0)
        {
            gyr = new GYR__c();
        }
        else
        {
            gyr = [SELECT GYRStatus__c FROM GYR__c WHERE Account__c = :a.Id AND GYREndDate__c = NULL LIMIT 1];
        }
        
        openCases = [SELECT COUNT() FROM Case WHERE AccountId = :a.Id AND IsClosed = False AND RecordType.Name IN('Incident','Customer Portal')];
        
        if(a.Costguard_Acct__c == '4593141' || a.Parent.Costguard_Acct__c == '4593141' || a.SaasPartnerAccount__r.Parent.CostGuard_Acct__c == '4593141')
        {
           isVerizon = true;
        }
        
        if(a.Costguard_Acct__c == '4593133' || a.Parent.Costguard_Acct__c == '4593133' || a.SaasPartnerAccount__r.Parent.CostGuard_Acct__c == '4593133')
        {
           isSiemens = true;
        }
    }
    
    public string GYRStatus
    {
        get
        {
            if(gyr.GYRStatus__c == null)
            {
                return 'Green';
            }
            else
            {
                return gyr.GYRStatus__c;
            }
        }
    }
    
    public Integer NumberOfOpenIncidents
    {
        get{return openCases;}
    }
    
      
    static testMethod void TestAccountHighlights() 
    {
        //create test account
        Account a = new Account();
        a.Name = 'testName';
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
        Contact ct = new Contact();
        ct.LastName = 'LastName';
        ct.Email = 'test@test.com';
        ct.RecordTypeId = rtCustOther;
        ct.AccountId = a.Id;
                    
        insert ct;
        
        //set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        
        
        //create test case      
        Case c = new Case();
        c.AccountId = a.Id;
        c.Subject = a.Name;
        c.ContactId = ct.Id;
        c.RecordTypeId = rtWO;
        c.Request_Type__c = 'Adds/Moves/Changes';
        c.Product_or_Service__c = 'DIA';
        c.Status = 'New';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';
        
        c.setOptions(dmo);
        
        insert c;
        
        //Test Account highlights
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(a);
        AccountHighlightsExtension acctHigh = new AccountHighlightsExtension(stdCtrl);      
        
    }

}