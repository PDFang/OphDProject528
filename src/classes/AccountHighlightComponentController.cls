public class AccountHighlightComponentController 
{
    private AccountWrapper wrapper;
    
    public PageReference blank() {
        return null;
    }
    
    
    public String acctId{ get; set; }
    
    public AccountWrapper getAcctWrapper()
    {
        AccountWrapper aw;
        
        if(acctId != null)
        {
            aw = new AccountWrapper(acctId);
            wrapper = aw;
        }
        else
        {
            aw = new AccountWrapper();
        }
        
        return aw; 
        
    }
    
    public class AccountWrapper
    {
        public integer incidents{get;set;}
        public decimal healthScore{get;set;}
        public string healthScoreImage{get;set;}
        public string customerPriority{get;set;}
        public string customerSegment{get;set;}
        public string accountPassword{get;set;}
        public boolean isVerizon{get;set;}
        public boolean isSiemens{get;set;}
        public boolean isPlatPartner{get;set;}
        public datetime DiscDate{get;set;}
        public String RecType{get;set;}
        public String goLiveBackground{public get; private set;}
        public String psPackageHours{public get; private set;}
        
        
        public Account acct{get;set;}
        
        public AccountWrapper()
        {
            
            
        }
        
        public AccountWrapper(String aId)
        {
            this.acct = [SELECT Implementation__c,ImplementationsCertifiedPartnerLookup__c, HipaaAccount__c, GovernmentAccount__c, Environment__c, UnsupportedEnvironment__c, TechnicalSuccessManagerprimary__r.Name, CadebillAccountNo__c,inContactGoLive__c, RecordType.Name, Parent.PartnerLevel__c, SalesPartnerMasterAgent__r.PartnerLevel__c,PartnerLevel__c, Billing_Group__c,CustomerMoodLastUpdatedBy__r.Name, Parent.RecordType.Name, CG_Disconnect_Date__c, Parent.CadebillAccountNo__c, SaasPartnerAccount__r.Parent.CadebillAccountNo__c,  CustomerSegment__c, AccountPassword__c, Customer_Priority__c, Health_Score__c, Health_Score_Image__c FROM Account WHERE Id = :aId];
            
            DiscDate = acct.CG_Disconnect_Date__c;
            RecType = acct.RecordType.Name;
            customerPriority = acct.Customer_Priority__c;
            customerSegment = acct.CustomerSegment__c;
            accountPassword = acct.AccountPassword__c;
            healthScore = acct.Health_Score__c;
            
            
            if(acct.Billing_Group__c == 'Verizon')
            {
                isVerizon = true;
            }
            
            if(acct.Billing_Group__c == 'SEN')
            {
                isSiemens = true;
            }
            
            if((acct.RecordType.Name == 'Sub Agents' && acct.Parent.PartnerLevel__c == 'Referral Platinum')
               || (acct.RecordType.Name == 'Master Agents' && acct.PartnerLevel__c == 'Referral Platinum')
               || (acct.RecordType.Name == 'Customers' && acct.SalesPartnerMasterAgent__r.PartnerLevel__c == 'Referral Platinum')
              )
            {
                isPlatPartner = true;
            }
            
            
            incidents = [SELECT COUNT() FROM Case WHERE AccountId = :aId AND IsClosed = False AND RecordType.Name IN('Incident','Customer Portal')];
            
            AggregateResult[] psPackages = [SELECT SUM(TimeRemaining__c) FROM InternalReleaseNote__c WHERE Account__c = :aId];
            
            
            if(!psPackages.isEmpty())
            {
                psPackageHours = string.valueOf((Double)psPackages[0].get('expr0'));
            }
            
            

            if(acct.Health_Score__c <= 65)
            {
                healthScoreImage = 'Mad';
            }
            else if(acct.Health_Score__c <= 84)
            {
                healthScoreImage = 'Meh';
            }
            else if(acct.Health_Score__c <= 100)
            {
                healthScoreImage = 'Happy';
            }
            else
            {
                healthScoreImage = 'Black';
            }
            
            
            if(acct.inContactGoLive__c == null)
            {
                goLiveBackground = 'red';
            }
            else if(acct.inContactGoLive__c.daysBetween(system.today()) <= 30)
            {
                goLiveBackground = 'orange';
            }
            else if(acct.inContactGoLive__c.daysBetween(system.today()) <= 60)
            {
                goLiveBackground = 'yellow';
            }
            else if(acct.inContactGoLive__c.daysBetween(system.today()) <= 90)
            {
                goLiveBackground = 'green';
            }
            else 
            {
                goLiveBackground = 'transparent';
            }
            
        }
        
    }
    
    
    /*static testMethod void TestAccountHighlights() 
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

AccountHighlightComponentController acctHigh = new AccountHighlightComponentController();
acctHigh.acctId = a.Id;
acctHigh.getAcctWrapper();      

}*/
}