public class AccountSegmentBannerExtension {

    //account called on page
    private final Account a;

    public AccountSegmentBannerExtension(ApexPages.StandardController controller) 
    {
        this.a = (Account)controller.getRecord();
    }
    
    public string getBannerBackground()
    {
        //return string
        String background;
        
        //get correct background string based on Customer Segment
        if(a.CustomerSegment__c=='Small')
        {
            background = InContactConfiguration.SmallBG;
        }
        else if(a.CustomerSegment__c=='Mid-Market')
        {
            background = InContactConfiguration.MidMarketBG;
        }
        else if(a.CustomerSegment__c=='Major')
        {
            background = InContactConfiguration.MajorBG;
        }
        else if(a.CustomerSegment__c=='Key')
        {
            background = InContactConfiguration.KeyBG;
        }
        else if(a.CustomerSegment__c=='Strategic')
        {
            background = InContactConfiguration.StrategicBG;
        }
        else
        {
            background = '';
        }
        
        return background;
        
    }
    
    static testMethod void TestAccountBanner()
    {
        String banner;
        
        //build account to test
        Account a = new Account();
        a.Name = 'Test';
        a.CustomerSegment__c = 'Small';
        
        insert a;
        
        //run page for Small segment
        ApexPages.StandardController stdCtrl1 = new ApexPages.StandardController(a);
        AccountSegmentBannerExtension bannerExtension1 = new AccountSegmentBannerExtension (stdCtrl1);
        
        //return bg color
        banner = bannerExtension1.getBannerBackground();
        
        //update to mid-market and run page
        a.CustomerSegment__c = 'Mid-Market';
        update a;
        
        ApexPages.StandardController stdCtrl2 = new ApexPages.StandardController(a);
        AccountSegmentBannerExtension bannerExtension2 = new AccountSegmentBannerExtension (stdCtrl1);
        
        //return bg color
        banner = bannerExtension2.getBannerBackground();
        
        //update segment to major and run page
        a.CustomerSegment__c = 'Major';
        update a;
        
        ApexPages.StandardController stdCtrl3 = new ApexPages.StandardController(a);
        AccountSegmentBannerExtension bannerExtension3 = new AccountSegmentBannerExtension (stdCtrl1);
        
        //return bg color
        banner = bannerExtension3.getBannerBackground();
        
        //update segment to key and run page
        a.CustomerSegment__c = 'Key';
        update a;
        
        ApexPages.StandardController stdCtrl4 = new ApexPages.StandardController(a);
        AccountSegmentBannerExtension bannerExtension4 = new AccountSegmentBannerExtension (stdCtrl1);
        
        //return bg color
        banner = bannerExtension2.getBannerBackground();
        
        //update segment to strategic and run page
        a.CustomerSegment__c = 'Strategic';
        update a;
        
        ApexPages.StandardController stdCtrl5 = new ApexPages.StandardController(a);
        AccountSegmentBannerExtension bannerExtension5 = new AccountSegmentBannerExtension (stdCtrl1);
        
        //return bg color
        banner = bannerExtension5.getBannerBackground();
        
        //clear segment and run page
        a.CustomerSegment__c = '';
        update a;
        
        ApexPages.StandardController stdCtrl6 = new ApexPages.StandardController(a);
        AccountSegmentBannerExtension bannerExtension6 = new AccountSegmentBannerExtension (stdCtrl1);
        
        //return bg color
        banner = bannerExtension6.getBannerBackground();
    }

}