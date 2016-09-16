global class InContactCsatWebService
{

private static string NoDataURL = 'http://chart.apis.google.com/chart?chxr=1,0,5&chxs=0,676767,10.5,0,l,676767|1,676767,9.5,0,l,676767&chxt=x,y&chbh=a,4,6&chs=250x240&cht=bvs&chco=FF8600&chds=0,5&chdl=Average+Score&chdlp=b&chg=20,50&chtt=Data+Not+Available';
private static string Delimiter = ':::';
private static string LookupRecord = 'CSAT-0000'; // LookupRecord number that the surveys are based on. Only one LookupRecord needed.
InContactCsat__c CsatObject = GetRecord();

/// <summary>
/// Updates Account Management URL string.
/// </summary>
/// <param name="UrlUpdate">Full URL string. Should include 3 URLs separated by ":::"</param>
/// <returns></returns>
webService static string UpdateAccountManagement(String UrlUpdate) 
{
    InContactCsat__c CurrentCsat = GetRecord();
    CurrentCsat.AccountManagement__c = UrlUpdate;
    try
    {
        update CurrentCsat;
    }
    catch(Exception e)
    {
        return e.GetMessage();
    }
    return CurrentCsat.AccountManagement__c;
}
/// <summary>
/// Updates Call Center URL string.
/// </summary>
/// <param name="UrlUpdate">Full URL string. Should include 3 URLs separated by ":::"</param>
/// <returns></returns>
webService static string UpdateCallCenter(String UrlUpdate) 
{
    InContactCsat__c CurrentCsat = GetRecord();
    CurrentCsat.CallCenter__c = UrlUpdate;
    try
    {
        update CurrentCsat;
    }
    catch(Exception e)
    {
        return e.GetMessage();
    }
    return CurrentCsat.CallCenter__c;
}
/// <summary>
/// Updates Education Enablement URL string.
/// </summary>
/// <param name="UrlUpdate">Full URL string. Should include 3 URLs separated by ":::"</param>
/// <returns></returns>
webService static string UpdateEducationEnablement(String UrlUpdate) 
{
    InContactCsat__c CurrentCsat = GetRecord();
    CurrentCsat.Enablement__c = UrlUpdate;
    try
    {
        update CurrentCsat;
    }
    catch(Exception e)
    {
        return e.GetMessage();
    }
    return CurrentCsat.Enablement__c;
}
/// <summary>
/// Updates Global Service Delivery URL string.
/// </summary>
/// <param name="UrlUpdate">Full URL string. Should include 3 URLs separated by ":::"</param>
/// <returns></returns>
webService static string UpdateGlobalServiceDelivery(String UrlUpdate) 
{
    InContactCsat__c CurrentCsat = GetRecord();
    CurrentCsat.GlobalServiceDelivery__c = UrlUpdate;
    try
    {
        update CurrentCsat;
    }
    catch(Exception e)
    {
        return e.GetMessage();
    }
    return CurrentCsat.GlobalServiceDelivery__c;
}
/// <summary>
/// Updates Implementation URL string.
/// </summary>
/// <param name="UrlUpdate">Full URL string. Should include 3 URLs separated by ":::"</param>
/// <returns></returns>
webService static string UpdateImplementation(String UrlUpdate) 
{
    InContactCsat__c CurrentCsat = GetRecord();
    CurrentCsat.Implementation__c = UrlUpdate;
    try
    {
        update CurrentCsat;
    }
    catch(Exception e)
    {
        return e.GetMessage();
    }
    return CurrentCsat.Implementation__c;
}
/// <summary>
/// Updates inContact Overall URL string.
/// </summary>
/// <param name="UrlUpdate">Full URL string. Should include 3 URLs separated by ":::"</param>
/// <returns></returns>
webService static string UpdateinContactOverall(String UrlUpdate) 
{
    InContactCsat__c CurrentCsat = GetRecord();
    CurrentCsat.InContactOverall__c = UrlUpdate;
    try
    {
        update CurrentCsat;
    }
    catch(Exception e)
    {
        return e.GetMessage();
    }
    return CurrentCsat.InContactOverall__c;
}
/// <summary>
/// Updates NOC URL string.
/// </summary>
/// <param name="UrlUpdate">Full URL string. Should include 3 URLs separated by ":::"</param>
/// <returns></returns>
webService static string UpdateNoc(String UrlUpdate) 
{
    InContactCsat__c CurrentCsat = GetRecord();
    CurrentCsat.Noc__c = UrlUpdate;
    try
    {
        update CurrentCsat;
    }
    catch(Exception e)
    {
        return e.GetMessage();
    }
    return CurrentCsat.Noc__c;
}
/// <summary>
/// Updates Operations URL string.
/// </summary>
/// <param name="UrlUpdate">Full URL string. Should include 3 URLs separated by ":::"</param>
/// <returns></returns>
webService static string UpdateOperations(String UrlUpdate) 
{
    InContactCsat__c CurrentCsat = GetRecord();
    CurrentCsat.Operations__c = UrlUpdate;
    try
    {
        update CurrentCsat;
    }
    catch(Exception e)
    {
        return e.GetMessage();
    }
    return CurrentCsat.Operations__c;
}
/// <summary>
/// Updates Provisioning URL string.
/// </summary>
/// <param name="UrlUpdate">Full URL string. Should include 3 URLs separated by ":::"</param>
/// <returns></returns>
webService static string UpdateProvisioning(String UrlUpdate) 
{
    InContactCsat__c CurrentCsat = GetRecord();
    CurrentCsat.Provisioning__c = UrlUpdate;
    try
    {
        update CurrentCsat;
    }
    catch(Exception e)
    {
        return e.GetMessage();
    }
    return CurrentCsat.Provisioning__c;
}
/// <summary>
/// Updates Professional Services URL string.
/// </summary>
/// <param name="UrlUpdate">Full URL string. Should include 3 URLs separated by ":::"</param>
/// <returns></returns>
webService static string UpdateProfessionalServices(String UrlUpdate) 
{
    InContactCsat__c CurrentCsat = GetRecord();
    CurrentCsat.ProfessionalServices__c = UrlUpdate;
    try
    {
        update CurrentCsat;
    }
    catch(Exception e)
    {
        return e.GetMessage();
    }
    return CurrentCsat.ProfessionalServices__c;
}
/// <summary>
/// Updates Service Delivery Support URL string.
/// </summary>
/// <param name="UrlUpdate">Full URL string. Should include 3 URLs separated by ":::"</param>
/// <returns></returns>
webService static string UpdateServiceDeliverySupport(String UrlUpdate) 
{
    InContactCsat__c CurrentCsat = GetRecord();
    CurrentCsat.ServiceDeliverySupport__c = UrlUpdate;
    try
    {
        update CurrentCsat;
    }
    catch(Exception e)
    {
        return e.GetMessage();
    }        
    return CurrentCsat.ServiceDeliverySupport__c;
}
/// <summary>
/// Updates Tech Support URL string.
/// </summary>
/// <param name="UrlUpdate">Full URL string. Should include 3 URLs separated by ":::"</param>
/// <returns></returns>
webService static string UpdateTechSupport(String UrlUpdate) 
{
    InContactCsat__c CurrentCsat = GetRecord();
    CurrentCsat.TechSupport__c = UrlUpdate;
    try
    {
        update CurrentCsat;
    }
    catch(Exception e)
    {
        return e.GetMessage();
    }
    return CurrentCsat.TechSupport__c;
}
/// <summary>
/// Returns a list of current URLs.
/// </summary>
/// <returns></returns>
webService static List<string> GetCurrentURLs() 
{
    List<string> urls = new List<string>();
    InContactCsat__c CurrentCsat = GetRecord();
    
    urls.Add(CurrentCsat.AccountManagement__c);
    urls.Add(CurrentCsat.CallCenter__c);
    urls.Add(CurrentCsat.Enablement__c);
    urls.Add(CurrentCsat.GlobalServiceDelivery__c);
    urls.Add(CurrentCsat.Implementation__c);
    urls.Add(CurrentCsat.InContactOverall__c);
    urls.Add(CurrentCsat.Noc__c);
    urls.Add(CurrentCsat.Operations__c);
    urls.Add(CurrentCsat.Provisioning__c);
    urls.Add(CurrentCsat.ProfessionalServices__c);
    urls.Add(CurrentCsat.ServiceDeliverySupport__c);
    urls.Add(CurrentCsat.TechSupport__c);
    
    return urls;
}

/// <summary>
/// Populate object based on LookupRecord number.
/// </summary>
/// <returns></returns>  
private static InContactCsat__c GetRecord()
{
    InContactCsat__c newObj;
    try
    {
        newObj = [Select AccountManagement__c, CallCenter__c, Enablement__c, GlobalServiceDelivery__c, Implementation__c, InContactOverall__c, Noc__c, Operations__c, Provisioning__c, ProfessionalServices__c, ServiceDeliverySupport__c, TechSupport__c FROM InContactCsat__c WHERE Name=:LookupRecord];
    }
    catch(Exception e)
    {
        newObj = new InContactCsat__c();
    }
    return newObj;
}

/// <summary>
/// Returns array of URLs for populating fields
/// </summary>
/// <param name="url">Full URL string to be split</param>
/// <returns></returns>


}