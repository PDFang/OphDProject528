global class ConsoleBannerAlertController 
{
    
    public ConsoleBannerAlertController()
    {
    }
    
    public string alertMessage
    {
        get
        {
            return inContactWebServices.GetAlertMessage();
        }
    }
    
    @RemoteAction
    global static string GetAlertMessages()
    {
        return inContactWebServices.GetAlertMessage();
    }
}