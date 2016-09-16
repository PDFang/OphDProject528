public class InContactCsat
{

private static string NoDataURL = 'http://chart.apis.google.com/chart?chxr=1,0,5&chxs=0,676767,10.5,0,l,676767|1,676767,9.5,0,l,676767&chxt=x,y&chbh=a,4,6&chs=250x240&cht=bvs&chco=FF8600&chds=0,5&chdl=Average+Score&chdlp=b&chg=20,50&chtt=Data+Not+Available';
private static string Delimiter = ':::';
private static string LookupRecord = 'CSAT-0020'; // LookupRecord number that the surveys are based on. Only one LookupRecord needed.
InContactCsat__c CsatObject = GetRecord();

// Fields

public String InContactOverallMonthToDate{
    get
    {
        if(InContactOverallMonthToDate != null)
        {
            return InContactOverallMonthToDate;
        }
        else
        {
            if(CsatObject.InContactOverall__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.InContactOverall__c)[0];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{InContactOverallMonthToDate = value;}
}

public String InContactOverallQuarterToDate
{
    get
    {
        if(InContactOverallQuarterToDate != null)
        {
            return InContactOverallQuarterToDate;
        }
        else
        {
            if(CsatObject.InContactOverall__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.InContactOverall__c)[1];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{InContactOverallQuarterToDate = value;}
}

public String InContactOverallYearToDate
{
    get
    {
        if(InContactOverallYearToDate != null)
        {
            return InContactOverallYearToDate;
        }
        else
        {
            if(CsatObject.InContactOverall__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.InContactOverall__c)[2];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{InContactOverallYearToDate = value;}
}



public String AccountManagementMonthToDate
{
    get
    {
        if(AccountManagementMonthToDate != null)
        {
            return AccountManagementMonthToDate;
        }
        else
        {
            if(CsatObject.AccountManagement__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.AccountManagement__c)[0];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{AccountManagementMonthToDate = value;}
}

public String AccountManagementQuarterToDate
{
    get
    {
        if(AccountManagementQuarterToDate != null)
        {
            return AccountManagementQuarterToDate;
        }
        else
        {
            if(CsatObject.AccountManagement__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.AccountManagement__c)[1];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{AccountManagementQuarterToDate = value;}
}

public String AccountManagementYearToDate
{
    get
    {
        if(AccountManagementYearToDate != null)
        {
            return AccountManagementYearToDate;
        }
        else
        {
            if(CsatObject.AccountManagement__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.AccountManagement__c)[2];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{AccountManagementYearToDate = value;}
}

public String CallCenterMonthToDate
{
    get
    {
        if(CallCenterMonthToDate != null)
        {
            return CallCenterMonthToDate;
        }
        else
        {
            if(CsatObject.CallCenter__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.CallCenter__c)[0];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{CallCenterMonthToDate = value;}
}

public String CallCenterQuarterToDate
{
    get
    {
        if(CallCenterQuarterToDate != null)
        {
            return CallCenterQuarterToDate;
        }
        else
        {
            if(CsatObject.CallCenter__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.CallCenter__c)[1];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }    
    }
    set{CallCenterQuarterToDate = value;}
}

public String CallCenterYearToDate
{
    get
    {
        if(CallCenterYearToDate != null)
        {
            return CallCenterYearToDate;
        }
        else
        {
            if(CsatObject.CallCenter__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.CallCenter__c)[2];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{CallCenterYearToDate = value;}
}

public String EnablementMonthToDate
{
    get
    {
        if(EnablementMonthToDate != null)
        {
            return EnablementMonthToDate;
        }
        else
        {
            if(CsatObject.Enablement__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Enablement__c)[0];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
        }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{EnablementMonthToDate = value;}
}

public String EnablementQuarterToDate
{
    get
    {
        if(EnablementQuarterToDate != null)
        {
            return EnablementQuarterToDate;
        }
        else
        {
            if(CsatObject.Enablement__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Enablement__c)[1];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }    
    }
    set{EnablementQuarterToDate = value;}
}

public String EnablementYearToDate
{
    get
    {
        if(EnablementYearToDate != null)
        {
            return EnablementYearToDate;
        }
        else
        {
            if(CsatObject.Enablement__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Enablement__c)[2];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{EnablementYearToDate = value;}
}

public String GlobalServiceDeliveryMonthToDate
{
    get
    {
        if(GlobalServiceDeliveryMonthToDate != null)
        {
            return GlobalServiceDeliveryMonthToDate;
        }
        else
        {
            if(CsatObject.GlobalServiceDelivery__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.GlobalServiceDelivery__c)[0];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{GlobalServiceDeliveryMonthToDate = value;}
}

public String GlobalServiceDeliveryQuarterToDate
{
    get
    {
        if(GlobalServiceDeliveryQuarterToDate != null)
        {
            return GlobalServiceDeliveryQuarterToDate;
        }
        else
        {
            if(CsatObject.GlobalServiceDelivery__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.GlobalServiceDelivery__c)[1];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }    
    }
    set{GlobalServiceDeliveryQuarterToDate = value;}
}

public String GlobalServiceDeliveryYearToDate
{
    get
    {
        if(GlobalServiceDeliveryYearToDate != null)
        {
            return GlobalServiceDeliveryYearToDate;
        }
        else
        {
            if(CsatObject.GlobalServiceDelivery__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.GlobalServiceDelivery__c)[2];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{GlobalServiceDeliveryYearToDate = value;}
}

public String ImplementationMonthToDate
{
    get
    {
        if(ImplementationMonthToDate != null)
        {
            return ImplementationMonthToDate;
        }
        else
        {
            if(CsatObject.Implementation__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Implementation__c)[0];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{ImplementationMonthToDate = value;}
}

public String ImplementationQuarterToDate
{
    get
    {
        if(ImplementationQuarterToDate != null)
        {
            return ImplementationQuarterToDate;
        }
        else
        {
            if(CsatObject.Implementation__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Implementation__c)[1];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }    
    }
    set{ImplementationQuarterToDate = value;}
}

public String ImplementationYearToDate
{
    get
    {
        if(ImplementationYearToDate != null)
        {
            return ImplementationYearToDate;
        }
        else
        {
            if(CsatObject.Implementation__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Implementation__c)[2];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{ImplementationYearToDate = value;}
}

public String NocMonthToDate
{
    get
    {
        if(NocMonthToDate != null)
        {
            return NocMonthToDate;
        }
        else
        {
            if(CsatObject.Noc__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Noc__c)[0];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{NocMonthToDate = value;}
}

public String NocQuarterToDate{
    get
    {
        if(NocQuarterToDate != null)
        {
            return NocQuarterToDate;
        }
        else
        {
            if(CsatObject.Noc__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Noc__c)[1];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }    
    }
    set{NocQuarterToDate = value;}
}

public String NocYearToDate
{
    get
    {
        if(NocYearToDate != null)
        {
            return NocYearToDate;
        }
        else
        {
            if(CsatObject.Noc__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Noc__c)[2];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }   
        }
    }
    set{NocYearToDate = value;}
}

public String OperationsMonthToDate
{
    get
    {
        if(OperationsMonthToDate != null)
        {
            return OperationsMonthToDate;
        }
        else
        {
            if(CsatObject.Operations__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Operations__c)[0];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{OperationsMonthToDate = value;}
}

public String OperationsQuarterToDate
{
    get
    {
        if(OperationsQuarterToDate != null)
        {
            return OperationsQuarterToDate;
        }
        else
        {
            if(CsatObject.Operations__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Operations__c)[1];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }    
    }
    set{OperationsQuarterToDate = value;}
}

public String OperationsYearToDate
{
    get
    {
        if(OperationsYearToDate != null)
        {
            return OperationsYearToDate;
        }
        else
        {
            if(CsatObject.Operations__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Operations__c)[2];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{OperationsYearToDate = value;}
}

public String ProvisioningMonthToDate
{
    get
    {
        if(ProvisioningMonthToDate != null)
        {
            return ProvisioningMonthToDate;
        }
        else
        {
            if(CsatObject.Provisioning__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Provisioning__c)[0];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{ProvisioningMonthToDate = value;}
}

public String ProvisioningQuarterToDate
{
    get
    {
        if(ProvisioningQuarterToDate != null)
        {
            return ProvisioningQuarterToDate;
        }
        else
        {
            if(CsatObject.Provisioning__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Provisioning__c)[1];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }   
    set{ProvisioningQuarterToDate = value;}
}

public String ProvisioningYearToDate
{
    get
    {
        if(ProvisioningYearToDate != null)
        {
            return ProvisioningYearToDate;
        }
        else
        {
            if(CsatObject.Provisioning__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.Provisioning__c)[2];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{ProvisioningYearToDate = value;}
}

public String ProfessionalServicesMonthToDate
{
    get
    {
        if(ProfessionalServicesMonthToDate != null)
        {
            return ProfessionalServicesMonthToDate;
        }
        else
        {
            if(CsatObject.ProfessionalServices__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.ProfessionalServices__c)[0];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{ProfessionalServicesMonthToDate = value;}
}

public String ProfessionalServicesQuarterToDate
{
    get
    {
        if(ProfessionalServicesQuarterToDate != null)
        {
            return ProfessionalServicesQuarterToDate;
        }
        else
        {
            if(CsatObject.ProfessionalServices__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.ProfessionalServices__c)[1];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }    
    }
    set{ProfessionalServicesQuarterToDate = value;}
}

public String ProfessionalServicesYearToDate
{
    get
    {
        if(ProfessionalServicesYearToDate != null)
        {
            return ProfessionalServicesYearToDate;
        }
        else
        {
        if(CsatObject.ProfessionalServices__c != null)
        {
                try 
                {
                    return UrlSplit(CsatObject.ProfessionalServices__c)[2];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{ProfessionalServicesYearToDate = value;}
}

public String ServiceDeliverySupportMonthToDate
{
    get
    {
        if(ServiceDeliverySupportMonthToDate != null)
        {
            return ServiceDeliverySupportMonthToDate;
        }
        else
        {
            if(CsatObject.ServiceDeliverySupport__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.ServiceDeliverySupport__c)[0];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{ServiceDeliverySupportMonthToDate = value;}
}

public String ServiceDeliverySupportQuarterToDate
{
    get
    {
        if(ServiceDeliverySupportQuarterToDate != null)
        {
            return ServiceDeliverySupportQuarterToDate;
        }
        else
        {
            if(CsatObject.ServiceDeliverySupport__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.ServiceDeliverySupport__c)[1];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }    
    }
    set{ServiceDeliverySupportQuarterToDate = value;}
}

public String ServiceDeliverySupportYearToDate
{
    get
    {
        if(ServiceDeliverySupportYearToDate != null)
        {
            return ServiceDeliverySupportYearToDate;
        }
        else
        {
        if(CsatObject.ServiceDeliverySupport__c != null)
        {
                try 
                {
                    return UrlSplit(CsatObject.ServiceDeliverySupport__c)[2];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{ServiceDeliverySupportYearToDate = value;}
}

public String TechSupportMonthToDate
{
    get
    {
        if(TechSupportMonthToDate != null)
        {
            return TechSupportMonthToDate;
        }
        else
        {
            if(CsatObject.TechSupport__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.TechSupport__c)[0];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{TechSupportMonthToDate = value;}
}

public String TechSupportQuarterToDate
{
    get
    {
        if(TechSupportQuarterToDate != null)
        {
            return TechSupportQuarterToDate;
        }
        else
        {
            if(CsatObject.TechSupport__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.TechSupport__c)[1];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }    
    }
    set{TechSupportQuarterToDate = value;}
}

public String TechSupportYearToDate
{
    get
    {
        if(TechSupportYearToDate != null)
        {
            return TechSupportYearToDate;
        }
        else
        {
            if(CsatObject.TechSupport__c != null)
            {
                try 
                {
                    return UrlSplit(CsatObject.TechSupport__c)[2];
                } 
                catch (Exception e) 
                {
                    return e.getMessage();
                }
            }
            else
            {
                return NoDataURL;
            }
        }
    }
    set{TechSupportYearToDate = value;}
}


// Methods


/// <summary>
/// Returns array of URLs for populating fields
/// </summary>
/// <param name="url">Full URL string to be split</param>
/// <returns></returns>
private string[] UrlSplit(string Url)
{
    string[] NewArray = Url.split(Delimiter,0);
    return NewArray;
}
/// <summary>
/// Combines URLs for saving in InContactCsat object
/// </summary>
/// <param name="MonthToDateUrl">Month To Date URL</param>
/// <param name="QuarterToDateUrl">Quarter To Date URL</param>
/// <param name="YearToDateUrl">Year To Date URL</param>
/// <returns></returns>
private string UrlCombine(string MonthToDateUrl, string QuarterToDateUrl, string YearToDateUrl)
{
    return MonthToDateURL + Delimiter + QuarterToDateUrl + Delimiter + YearToDateUrl;
}

/// <summary>
/// Insert Object on Initial setup
/// </summary>
/// <returns></returns>
public void InsertRecord()
{
    insert CsatObject;
}

/// <summary>
/// Populate object based on LookupRecord number.
/// </summary>
/// <returns></returns>
private static InContactCsat__c GetRecord()
{
    InContactCsat__c NewObj;
    try
    {
        NewObj = [Select AccountManagement__c, CallCenter__c, Enablement__c, GlobalServiceDelivery__c, Implementation__c, InContactOverall__c, Noc__c, Operations__c, Provisioning__c, ProfessionalServices__c, ServiceDeliverySupport__c, TechSupport__c FROM InContactCsat__c WHERE Name=:LookupRecord];
    }
    catch(Exception e)
    {
        NewObj = new InContactCsat__c();
    }
    return NewObj;
}
/// <summary>
/// Update record with new URLs
/// </summary>
/// <returns></returns>
public void UpdateRecord()
{
    CsatObject.AccountManagement__c = UrlCombine(AccountManagementMonthToDate,AccountManagementQuarterToDate, AccountManagementYearToDate);
    CsatObject.CallCenter__c = UrlCombine(CallCenterMonthToDate,CallCenterQuarterToDate, CallCenterYearToDate);
    CsatObject.Enablement__c = UrlCombine(EnablementMonthToDate,EnablementQuarterToDate, EnablementYearToDate);
    CsatObject.GlobalServiceDelivery__c = UrlCombine(GlobalServiceDeliveryMonthToDate,GlobalServiceDeliveryQuarterToDate, GlobalServiceDeliveryYearToDate);
    CsatObject.Implementation__c = UrlCombine(ImplementationMonthToDate,ImplementationQuarterToDate, ImplementationYearToDate);
    CsatObject.InContactOverall__c = UrlCombine(InContactOverallMonthToDate,InContactOverallQuarterToDate, InContactOverallYearToDate);
    CsatObject.Noc__c = UrlCombine(NocMonthToDate,NocQuarterToDate, NocYearToDate);
    CsatObject.Operations__c = UrlCombine(OperationsMonthToDate,OperationsQuarterToDate, OperationsYearToDate);
    CsatObject.Provisioning__c = UrlCombine(ProvisioningMonthToDate,ProvisioningQuarterToDate, ProvisioningYearToDate);
    CsatObject.ProfessionalServices__c = UrlCombine(ProfessionalServicesMonthToDate,ProfessionalServicesQuarterToDate, ProfessionalServicesYearToDate);
    CsatObject.ServiceDeliverySupport__c = UrlCombine(ServiceDeliverySupportMonthToDate,ServiceDeliverySupportQuarterToDate, ServiceDeliverySupportYearToDate);
    CsatObject.TechSupport__c = UrlCombine(TechSupportMonthToDate,TechSupportQuarterToDate, TechSupportYearToDate);
    update CsatObject;
}

static testMethod void TestInContactCsat()
{
	//InContactCsat test = new InContactCsat();
	//test.UpdateRecord();
	
	InContactCsat__c cs = new InContactCsat__c();
	cs.AccountManagement__c = 'http://www.incontact.com';
	cs.CallCenter__c = 'http://www.incontact.com';
	cs.Enablement__c = 'http://www.incontact.com';
	cs.GlobalServiceDelivery__c = 'http://www.incontact.com';
	cs.Implementation__c = 'http://www.incontact.com';
	cs.InContactOverall__c = 'http://www.incontact.com';
	cs.Noc__c = 'http://www.incontact.com';
	cs.Operations__c = 'http://www.incontact.com';
	cs.ProfessionalServices__c = 'http://www.incontact.com';
	cs.Provisioning__c = 'http://www.incontact.com';
	cs.ServiceDeliverySupport__c = 'http://www.incontact.com';
	cs.TechSupport__c = 'http://www.incontact.com';
	insert cs;
	
	
	InContactCsat ic = new InContactCsat();
	//ic.LookupRecord = 'CSAT-0001';
	//ic.UpdateRecord();
	
	
	ic.AccountManagementMonthToDate = 'http://www.incontact.com';
	ic.AccountManagementQuarterToDate = 'http://www.incontact.com';
	ic.AccountManagementYearToDate = 'http://www.incontact.com';
	ic.CallCenterMonthToDate = 'http://www.incontact.com';
	ic.CallCenterQuarterToDate = 'http://www.incontact.com';
	ic.CallCenterYearToDate = 'http://www.incontact.com';
	ic.EnablementMonthToDate = 'http://www.incontact.com';
	ic.EnablementQuarterToDate = 'http://www.incontact.com';
	ic.EnablementYearToDate = 'http://www.incontact.com';
	ic.GlobalServiceDeliveryMonthToDate = 'http://www.incontact.com';
	ic.GlobalServiceDeliveryQuarterToDate = 'http://www.incontact.com';
	ic.GlobalServiceDeliveryYearToDate = 'http://www.incontact.com';
	ic.ImplementationMonthToDate = 'http://www.incontact.com';
	ic.ImplementationQuarterToDate = 'http://www.incontact.com';
	ic.ImplementationYearToDate = 'http://www.incontact.com';
	ic.InContactOverallMonthToDate = 'http://www.incontact.com';
	ic.InContactOverallQuarterToDate = 'http://www.incontact.com';
	ic.InContactOverallYearToDate = 'http://www.incontact.com';
	ic.NocMonthToDate = 'http://www.incontact.com';
	ic.NocQuarterToDate = 'http://www.incontact.com';
	ic.NocYearToDate = 'http://www.incontact.com';
	ic.OperationsMonthToDate = 'http://www.incontact.com';
	ic.OperationsQuarterToDate = 'http://www.incontact.com';
	ic.OperationsYearToDate = 'http://www.incontact.com';
	ic.ProfessionalServicesMonthToDate = 'http://www.incontact.com';
	ic.ProfessionalServicesQuarterToDate = 'http://www.incontact.com';
	ic.ProfessionalServicesYearToDate = 'http://www.incontact.com';
	ic.ProvisioningMonthToDate = 'http://www.incontact.com';
	ic.ProvisioningQuarterToDate = 'http://www.incontact.com';
	ic.ProvisioningYearToDate = 'http://www.incontact.com';
	ic.ServiceDeliverySupportMonthToDate = 'http://www.incontact.com';
	ic.ServiceDeliverySupportQuarterToDate = 'http://www.incontact.com';
	ic.ServiceDeliverySupportYearToDate = 'http://www.incontact.com';
	ic.TechSupportMonthToDate = 'http://www.incontact.com';
	ic.TechSupportQuarterToDate = 'http://www.incontact.com';
	ic.TechSupportYearToDate = 'http://www.incontact.com';
	
	//ic.InsertRecord();
	ic.UpdateRecord();
	
	InContactCsatWebService.UpdateAccountManagement('http://www.incontact.com');
	InContactCsatWebService.UpdateCallCenter('http://www.incontact.com');
	InContactCsatWebService.UpdateEducationEnablement('http://www.incontact.com');
	InContactCsatWebService.UpdateGlobalServiceDelivery('http://www.incontact.com');
	InContactCsatWebService.UpdateImplementation('http://www.incontact.com');
	InContactCsatWebService.UpdateinContactOverall('http://www.incontact.com');
	InContactCsatWebService.UpdateNoc('http://www.incontact.com');
	InContactCsatWebService.UpdateOperations('http://www.incontact.com');
	InContactCsatWebService.UpdateProfessionalServices('http://www.incontact.com');
	InContactCsatWebService.UpdateProvisioning('http://www.incontact.com');
	InContactCsatWebService.UpdateServiceDeliverySupport('http://www.incontact.com');
	InContactCsatWebService.UpdateTechSupport('http://www.incontact.com');
	
	List<string> testString = InContactCsatWebService.GetCurrentURLs();
}
}