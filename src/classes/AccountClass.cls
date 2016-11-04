public class AccountClass 
{
    // a test comment
    private id accountId;
    private Account acct;
    public BannerClass banner{public get; private set;}
    
    public AccountClass(id acctId)
    {
        accountId = acctId;
        SetAccount();
    }
    
    public void SetAccount()
    {
        acct = [SELECT Id, BannerFontColor__c, BannerText__c, BannerBackgroundColor__c, Parent.BannerFontColor__c, Parent.BannerText__c, Parent.BannerBackgroundColor__c, ParentId FROM Account WHERE Id = :accountId];
        SetBannerInfo();
    }
    
    private void SetBannerInfo()
    {
        banner = new BannerClass();
        if(acct.ParentId != null)
        {
            if(acct.Parent.BannerText__c != null && acct.Parent.BannerBackgroundColor__c != null && acct.Parent.BannerFontColor__c != null)
            {
                banner.BackgroundColor = acct.Parent.BannerBackgroundColor__c;
                banner.FontColor = acct.Parent.BannerFontColor__c;
                banner.DisplayText = acct.Parent.BannerText__c;
                return;
            }
        }
        
        if(acct.BannerText__c != null && acct.BannerBackgroundColor__c != null && acct.BannerFontColor__c != null)
        {
            banner.BackgroundColor = acct.BannerBackgroundColor__c;
            banner.FontColor = acct.BannerFontColor__c;
            banner.DisplayText = acct.BannerText__c;
            return;
        }
        
        banner = null;
    
    }
    
    public class BannerClass
    {
        public string BackgroundColor{get;set;}
        public string FontColor{get;set;}
        public string DisplayText{get;set;}
        
        public BannerClass(){}
    }
}