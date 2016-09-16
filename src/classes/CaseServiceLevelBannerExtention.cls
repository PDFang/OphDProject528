public class CaseServiceLevelBannerExtention 
{

	private final Case c;
	private final Account acct;
		
	public CaseServiceLevelBannerExtention(ApexPages.StandardController stdCtrl)
	{
		this.c = (Case)stdCtrl.getRecord();
		//get account priority from the account
		acct = [SELECT Id, Customer_Priority__c FROM Account WHERE Id = :c.AccountId];
		
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
	
	public string ServiceLevel {get; private set;}
	
	static testMethod void testCaseServiceLevel()
	{
		//create test account
		Account acct = new Account();
		acct.Name = 'Test Account SL Extension';
		acct.Customer_Priority__c = 'Silver Service Package';
		insert acct;
		
		//set default assignment rule		
		database.DMLOptions dmo = new database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		
		Case c = new Case();
		c.Subject = 'Test Case SL Extension';
		c.Description = 'Test';
		c.Status = 'New';
		c.AccountId = acct.Id;
		c.setOptions(dmo);
		insert c;
		
		//call controller
		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(c);
        CaseServiceLevelBannerExtention controller = new CaseServiceLevelBannerExtention(stdCtrl);
        controller = new CaseServiceLevelBannerExtention(stdCtrl);
        
        system.assertEquals(controller.BannerUrl, InContactConfiguration.silverLogoURL);
        
        //test for Gold
        acct.Customer_Priority__c = 'Gold Service Package';
        update acct;
        
        CaseServiceLevelBannerExtention controller2 = new CaseServiceLevelBannerExtention(stdCtrl);
        controller2 = new CaseServiceLevelBannerExtention(stdCtrl);
        system.assertEquals(controller2.BannerUrl, InContactConfiguration.goldLogoURL);
        
        
        //test for Platinum
        acct.Customer_Priority__c = 'Platinum Service Package';
        update acct;
        
        CaseServiceLevelBannerExtention controller3 = new CaseServiceLevelBannerExtention(stdCtrl);
        controller3 = new CaseServiceLevelBannerExtention(stdCtrl);
        system.assertEquals(controller3.BannerUrl, InContactConfiguration.platinumLogoURL);
        
        //test for Platinum
        acct.Customer_Priority__c = 'Basic Service Package';
        update acct;
        
        CaseServiceLevelBannerExtention controller4 = new CaseServiceLevelBannerExtention(stdCtrl);
        controller4 = new CaseServiceLevelBannerExtention(stdCtrl);
        system.assertEquals(controller4.BannerUrl, InContactConfiguration.basicLogoURL);
        
        //test for Blank
        acct.Customer_Priority__c = '';
        update acct;
        
        CaseServiceLevelBannerExtention controller5 = new CaseServiceLevelBannerExtention(stdCtrl);
        controller5 = new CaseServiceLevelBannerExtention(stdCtrl);
        system.assertEquals(controller5.BannerUrl, '');
	}
	
}