public class CaseSegmentBannerExtension 
{

    private final Case c;

    public CaseSegmentBannerExtension(ApexPages.StandardController controller) {
        this.c = (Case)controller.getRecord();
    }
    
    public string getBannerBackground()
    {
        //return string
        String background;
        
        if(c.CustomerSegment__c=='Small')
        {
            background = InContactConfiguration.SmallBG;
        }
        else if(c.CustomerSegment__c=='Mid-Market')
        {
            background = InContactConfiguration.MidMarketBG;
        }
        else if(c.CustomerSegment__c=='Major')
        {
            background = InContactConfiguration.MajorBG;
        }
        else if(c.CustomerSegment__c=='Key')
        {
            background = InContactConfiguration.KeyBG;
        }
        else if(c.CustomerSegment__c=='Strategic')
        {
            background = InContactConfiguration.StrategicBG;
        }
        else
        {
            background = '';
        }
        
        return background;
        
    }
    
    static testMethod void TestCaseBanner()
    {
        String banner;
        
        //build account to test
        Account a = new Account();
        a.Name = 'Test';
        a.CustomerSegment__c = 'Small';
        
        insert a;
        
        //set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        
        //build case to test
        Case c = new Case();
        c.subject = 'test';
        c.AccountId = a.Id;
        c.description = 'test';
        c.setOptions(dmo);
        
        insert c;
        
        //get update case info
        Case c1 = new Case();
        c1 = [SELECT Id, CustomerSegment__c FROM Case WHERE Id = :c.Id];
        
        system.debug('********************************* ' + c.CustomerSegment__c);
        
        //run page for Small segment
        ApexPages.StandardController stdCtrl1 = new ApexPages.StandardController(c1);
        CaseSegmentBannerExtension bannerExtension1 = new CaseSegmentBannerExtension(stdCtrl1);
        
        //return bg color
        banner = bannerExtension1.getBannerBackground();
        
        //update to mid-market and run page
        a.CustomerSegment__c = 'Mid-Market';
        update a;
        
        //get update case info
        Case c2 = new Case();
        c2 = [SELECT Id, CustomerSegment__c FROM Case WHERE Id = :c.Id];
        
        ApexPages.StandardController stdCtrl2 = new ApexPages.StandardController(c2);
        CaseSegmentBannerExtension bannerExtension2 = new CaseSegmentBannerExtension (stdCtrl1);
        
        //return bg color
        banner = bannerExtension2.getBannerBackground();
        
        //update segment to major and run page
        a.CustomerSegment__c = 'Major';
        update a;
        
        //get update case info
        Case c3 = new Case();
        c3 = [SELECT Id, CustomerSegment__c FROM Case WHERE Id = :c.Id];
        
        ApexPages.StandardController stdCtrl3 = new ApexPages.StandardController(c3);
        CaseSegmentBannerExtension bannerExtension3 = new CaseSegmentBannerExtension (stdCtrl1);
        
        //return bg color
        banner = bannerExtension3.getBannerBackground();
        
        //update segment to key and run page
        a.CustomerSegment__c = 'Key';
        update a;
        
        //get update case info
        c = [SELECT Id, CustomerSegment__c FROM Case WHERE Id = :c.Id];
        
        ApexPages.StandardController stdCtrl4 = new ApexPages.StandardController(c);
        CaseSegmentBannerExtension bannerExtension4 = new CaseSegmentBannerExtension(stdCtrl1);
        
        //return bg color
        banner = bannerExtension2.getBannerBackground();
        
        //update segment to strategic and run page
        a.CustomerSegment__c = 'Strategic';
        update a;
        
        //get update case info
        c = [SELECT Id, CustomerSegment__c FROM Case WHERE Id = :c.Id];
        
        ApexPages.StandardController stdCtrl5 = new ApexPages.StandardController(c);
        CaseSegmentBannerExtension bannerExtension5 = new CaseSegmentBannerExtension(stdCtrl1);
        
        //return bg color
        banner = bannerExtension5.getBannerBackground();
        
        //clear segment and run page
        a.CustomerSegment__c = '';
        update a;
        
        //get update case info
        c = [SELECT Id, CustomerSegment__c FROM Case WHERE Id = :c.Id];
        
        ApexPages.StandardController stdCtrl6 = new ApexPages.StandardController(c);
        CaseSegmentBannerExtension bannerExtension6 = new CaseSegmentBannerExtension(stdCtrl1);
        
        //return bg color
        banner = bannerExtension6.getBannerBackground();
       }
}