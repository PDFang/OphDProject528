public class AccountServiceLevelBannerExtention {

	private final Account acct;
		
	public AccountServiceLevelBannerExtention(ApexPages.StandardController stdCtrl)
	{
		this.acct = (Account)stdCtrl.getRecord();
		BuildURL();
	}
	
	private void BuildURL()
	{
		//Determine which image to point to
		if(acct.Customer_Priority__c != NULL)
		{
			if(acct.Customer_Priority__c.toUpperCase().contains('PLATINUM'))
			{
				BannerUrl = InContactConfiguration.platinumLogoURL; 
				ServiceLevel = InContactConfiguration.PlatinumName;
			}
			else if (acct.Customer_Priority__c.toUpperCase().contains('GOLD'))
			{
				BannerUrl = InContactConfiguration.goldLogoURL;
				ServiceLevel = InContactConfiguration.GoldName;
			}
			else if (acct.Customer_Priority__c.toUpperCase().contains('SILVER'))
			{
				BannerUrl = InContactConfiguration.silverLogoURL;
				ServiceLevel = InContactConfiguration.SilverName;
			}
			else if (acct.Customer_Priority__c.toUpperCase().contains('BASIC'))
			{
				BannerUrl = InContactConfiguration.basicLogoURL;
				ServiceLevel = InContactConfiguration.BasicName;
			}
			else
			{
				BannerUrl = '';
				ServiceLevel = InContactConfiguration.SignatureName;
			}
		}
		else
		{
			BannerUrl = '';
			ServiceLevel = InContactConfiguration.SignatureName;
		}
	}
	
	public string BannerUrl { get; private set; }
	
	public string ServiceLevel { get; private set; }

	static testMethod void testAccountServiceLevel()
	{
		//create test account
		Account acct = new Account();
		acct.Name = 'Test Account SL Extension';
		acct.Customer_Priority__c = 'Silver Service Package';
		insert acct;
		
		//call controller
		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(acct);
        AccountServiceLevelBannerExtention controller = new AccountServiceLevelBannerExtention(stdCtrl);
        controller = new AccountServiceLevelBannerExtention(stdCtrl);
        
        system.assertEquals(controller.BannerUrl, InContactConfiguration.silverLogoURL);
        
        //test for Gold
        acct.Customer_Priority__c = 'Gold Service Package';
        update acct;
        
        controller.BuildURL();
        system.assertEquals(controller.BannerUrl, InContactConfiguration.goldLogoURL);
        
        
        //test for Platinum
        acct.Customer_Priority__c = 'Platinum Service Package';
        update acct;
        
        controller.BuildURL();
        system.assertEquals(controller.BannerUrl, InContactConfiguration.platinumLogoURL);
        
        //test for Silver
        acct.Customer_Priority__c = 'Silver Service Package';
        update acct;
        
        controller.BuildURL();
        system.assertEquals(controller.BannerUrl, InContactConfiguration.silverLogoURL);
        
        //test for Platinum
        acct.Customer_Priority__c = 'Basic Service Package';
        update acct;
        
        controller.BuildURL();
        system.assertEquals(controller.BannerUrl, InContactConfiguration.basicLogoURL);
        
        //test for Signature
        acct.Customer_Priority__c = '';
        update acct;
        
        controller.BuildURL();
        system.assertEquals(controller.BannerUrl, '');
	}
}