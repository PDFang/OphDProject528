public with sharing class ConsoleCaseControlsExtension extends ConsoleRemoteActions
{
    private final Case c;
    private AccountClass accountInfo;

    public ConsoleCaseControlsExtension(ApexPages.StandardController controller) 
    {
        this.c = (Case)controller.getRecord();
        
       if(c.AccountId != null)
       {
           accountInfo = new AccountClass(c.AccountId);
       }
       else
       {
           accountInfo = null;
       }
       
    }

    public CaseMilestone[] getOpenMilestones()
    {
        CaseMilestone[] milestones = new CaseMilestone[]{};
        
        milestones = [SELECT TargetDate, IsViolated, MilestoneType.Name FROM CaseMilestone WHERE IsCompleted = false AND CaseId = :c.Id];
        
        return milestones;
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