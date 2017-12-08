public with sharing class ConsoleAccountHighlightPanelExtension  extends ConsoleRemoteActions
{
    private Account acct;
    private AccountClass accountInfo;

    public ConsoleAccountHighlightPanelExtension(ApexPages.StandardController controller) 
    {
        acct = (Account)controller.getRecord();
        accountInfo = new AccountClass(acct.Id);
    }
        
    public string PsPackageHours
    {
        get
        {
            AggregateResult[] psPackages = [SELECT SUM(TimeRemaining__c) FROM InternalReleaseNote__c WHERE Account__c = :acct.Id];
            
                        
            if(!psPackages.isEmpty() && psPackages[0].get('expr0') != null)
            {
                return string.valueOf((Double)psPackages[0].get('expr0'));
            }
            else
            {
                return '0.0';
            }
        }
    }
    
    public string NumberOfOpenIncidents
    {
        get
        {
            integer incidents = [SELECT COUNT() FROM Case WHERE AccountId = :acct.Id AND IsClosed = False AND RecordType.Name IN('Incident','Customer Portal')];
            return string.valueOf(incidents);
        }
    }
    
    
    public AccountClass.BannerClass GetBanner
    {
        get
        {
            if(accountInfo != null)
            {
                return accountInfo.banner;
            }
            else
            {
                return null;
            }
        }
    }
    
    

}