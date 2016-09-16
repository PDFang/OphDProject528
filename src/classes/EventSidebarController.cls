public class EventSidebarController 
{
    public Case[] events{public get;private set;}
    
    public EventSidebarController()
    {
        UpdateEvents();
    }
    
    public boolean RenderNoEventMessage
    {
        get
        {
            if(events.isEmpty())
            {
                return true;
            }
            else
            {
                return false;
            }
        }
    }
    
    public void UpdateEvents()
    {
        events = CaseEventClass.GetOpenEvents();
    }
    
    public string JsonEvents
    {
        get
        {
            return JSON.serialize(events);
        }
    }
    

}