public class ConsoleQuickLinksController 
{
    private final List<QuickLinks__c> ql;
	public Map<String, List<QuickLinks__c>> mpquickLinkURLs {get; Set;}
	public set<String> setCategory {get; Set;}


    public ConsoleQuickLinksController()
    {
		setCategory = new set<String>();
		mpquickLinkURLs = new Map<String, List<QuickLinks__c>>();
		Map<String, QuickLinks__c> quckLinks = QuickLinks__c.getall();

		for (QuickLinks__c qls : quckLinks.values())
		{
			
			setCategory.add(qls.Category__c);
			if (mpquickLinkURLs.containsKey(qls.Category__c))
				mpquickLinkURLs.get(qls.Category__c).add(qls);
			else
				mpquickLinkURLs.put(qls.Category__c, new List<QuickLinks__c>{qls}); 
		}
		
        //ql = QuickLinks__c.getall().values();
    }
    
    public List<QuickLinks__c> getQuickLinks
    {
        get
        {
            return ql;
        }
    }
}