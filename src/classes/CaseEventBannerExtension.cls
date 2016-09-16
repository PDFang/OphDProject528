public class CaseEventBannerExtension 
{
    private Case c;
    public string URLForPage{public get;private set;}
    public boolean renderForm{public get;private set;}
    public boolean allowNotifications{public get;private set;}

    public CaseEventBannerExtension(ApexPages.StandardController controller) 
    {
        this.c = (Case)controller.getRecord();
        
        URLForPage = ApexPages.currentPage().getHeaders().get('Host');
        
        
        renderForm = inContactBaseClass.HasEditAccess(c.Id,UserInfo.getUserId());
        
        if(c.RecordType.Name == 'Event' && c.Owner.Name != 'NOC Queue')
        {
            allowNotifications = false;
        }
        else
        {
            allowNotifications = true;
        }
    }
    
    public PageReference Confirm()
    {
        
        PageReference confirmPage = Page.CaseConfirmEvent;
        confirmPage.setRedirect(true);
        
        return confirmPage;
    }
    
    public void SyncChildPriority()
    {
        Case[] childCases = [SELECT Priority FROM Case WHERE ParentId = :c.Id];
        
        if(!childCases.isEmpty())
        {
            for(Case ca:childCases)
            {
                ca.Priority = c.Priority;
            }
            
            update childCases;
        }
    }
    
    public void ChatRoomEmail()
    {
        Case chatCase = new Case();
        chatCase.Id = c.Id;
        chatCase.SendChatRoomEmail__c = true;
        
        update chatCase;
    }
    
    public void Blank()
    {
    
    }

}