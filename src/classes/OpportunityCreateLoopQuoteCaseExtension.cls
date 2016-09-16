public class OpportunityCreateLoopQuoteCaseExtension {

    private final Opportunity o;
    private Standard_Text__c st;
    public Case nCase;
    public string stDesc;
    private Contact[] cList;
    public Id cId;
    public String productName;
    private String caseType;
    public Boolean renderLoopQuote{get;set;}
    public Boolean renderConDesign{get;set;}
    public Boolean renderICBPricing{get;set;}
    public Boolean renderSave{get;set;}
    public String customerType{get;set;}
    private string serviceRequestRecordTypeId;
    

    public OpportunityCreateLoopQuoteCaseExtension(ApexPages.StandardController controller) 
    {
        o = (Opportunity)controller.getRecord();
        serviceRequestRecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Service Request', 'Case');   
        
        cList = [SELECT Name, Id FROM Contact WHERE AccountId = :o.AccountId ORDER BY Name];
        
        nCase = new Case();
        nCase.AccountId = o.AccountId;
        nCase.Opportunity__c = o.Id;
        
        
        
        renderLoopQuote = false;
        renderConDesign = false;
        renderICBPricing = false;
        renderSave = false;
    }
    
    public void CaseTypeUpdated()
    {
        if(caseType == 'Loop Quote')
        {
            renderLoopQuote = true;
            nCase.Request_Type__c = 'Loop Quote';
            nCase.RecordTypeId = '01270000000LuEq';
            st = [SELECT StandardText__c FROM Standard_Text__c WHERE Name = 'Loop Quote Request'];
            stDesc = st.StandardText__c;
        }
        else
        {
            renderLoopQuote = false;
        }
        
        if(caseType == 'Connectivity Design')
        {
            renderConDesign = true;
            
            nCase.RecordTypeId = '01270000000LuEr';
            if(st != null){st.clear();}
            stDesc = '';
        }
        else
        {
            renderConDesign = false;
        }
        
        if(caseType == 'ICB Pricing')
        {
            renderICBPricing = true;
            
            nCase.RecordTypeId = serviceRequestRecordTypeId;
            nCase.Request_Type__c = 'ICB Pricing';
            st = [SELECT StandardText__c FROM Standard_Text__c WHERE Name = 'ICB Pricing'];
            stDesc = st.StandardText__c;
        }
        else
        {
            renderICBPricing = false;
        }
        
        if(caseType == null)
        {
            renderSave = false;
        }
        else
        {
            renderSave = true;
        }
    }
    
    public void CustomerTypeUpdate()
    {
        if(customerType == 'New')
        {
            st = [SELECT StandardText__c FROM Standard_Text__c WHERE Name = 'Connectivity Design - New Sale Assistance'];
            stDesc = st.StandardText__c;
        }
        else if(customerType == 'Existing')
        {
            
            st = [SELECT StandardText__c FROM Standard_Text__c WHERE Name = 'Connectivity Design - Existing Customers'];
            stDesc = st.StandardText__c;
        }
    }
    
    public pageReference Save()
    {
    
        if(cId == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact is required. Please select a contact before submitting.'));
            return null;
        }
        
        if(caseType == 'Loop Quote')
        {
            nCase.Subject = o.Name + ' - Loop Quote Request';
            nCase.Request_Type__c = 'Loop Quote';
            nCase.RecordTypeId = '01270000000LuEq';
        
            if(nCase.Product_or_Service__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Loop Quote product is required. Please select a product before submitting.'));
                return null;
            }
        }
        
        if(caseType == 'ICB Pricing')
        {
            nCase.Subject = o.Name + ' - ICB Pricing';
        
            if(nCase.Product_or_Service__c == null || nCase.SubProductorService__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'ICB Pricing product and sub-product are required. Please select a product and sub-product before submitting.'));
                return null;
            }
        }
        
        if(caseType == 'Connectivity Design')
        {
            nCase.Subject = o.Name + ' - Connectivity Design Request';
            nCase.Request_Type__c = 'Add Product/Service';
            nCase.RecordTypeId = '01270000000LuEr';
        
            if(customerType == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select whether it is a new or existing customer.'));
                return null;
            }
                       
            if(customerType == 'New')
            {
                nCase.Product_or_Service__c = 'Connectivity Design-New Prospect';
            }
            else if(customerType == 'Existing')
            {
                nCase.Product_or_Service__c = 'Connectivity Design-Exist Cust New';
            }
        }
        
    
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        dmo.EmailHeader.triggerUserEmail = true;
        
        nCase.Origin = 'Rep';
        nCase.ContactId = cId;
        nCase.Description = stDesc;
        
        nCase.setOptions(dmo);
        
        insert nCase;
        
        PageReference casePage = new ApexPages.StandardController(nCase).view();
        casePage.setRedirect(true);

        return casePage;
    }
    
    public Case fullCase
    {
        get
        {
            return nCase;
        }
    }
    
    public string TextDescription
    {
        get
        {
            return stDesc;
        }
        set
        {
            stDesc = value;
        }
    }
    
    public Id contactId
    {
        get
        {
            return cId;
        }
        set
        {
            cId = value;
        }
    }
    
    public String product
    {
        get
        {
            return productName;
        }
        set
        {
            productName = value;
        }
    }
    
    public String CaseTypeValue
    {
        get
        {
            return caseType;
        }
        set
        {
            caseType = value;
        }
     }
    
    //builds a picklist of Contact Names based on selected Account
    public List<selectOption> Contacts 
    {
        get
        {
            //new list for holding all of the picklist options
            List<SelectOption> options = new List<SelectOption>(); 
            //Add the first option of '- Select Contact -' in case no values are returned from query below
            options.add(new selectOption('', '- Select Contact -')); 
            //Get the Contacts for this Account from the Database 
            for (Contact contact : cList)  
            { 
                //for all records found - add them to the picklist options
                options.add(new selectOption(contact.Id, contact.Name)); 
            }
            //return the picklist options
            return options; 
        }
    }
    
    //builds a picklist of Case types available
    public List<selectOption> CaseTypes
    {
        get
        {
            //new list for holding all of the picklist options
            List<SelectOption> options = new List<SelectOption>(); 
            //Add the first option of '- Select Case Type -' in case no values are returned from query below
            options.add(new selectOption('', '- Select Case Type -')); 
            options.add(new selectOption('Loop Quote','Loop Quote')); 
            options.add(new selectOption('Connectivity Design','Connectivity Design'));
            options.add(new selectOption('ICB Pricing','ICB Pricing')); 
            
            //return the picklist options
            return options; 
        }
    }
    
        
    static testMethod void TestOpportunityCreateLoopQuoteCaseExtension()
    {
        Account a = new Account();
        a.Name = 'Test Account';
        insert a;
        
        Contact c = new Contact();
        c.LastName = 'Test';
        c.AccountId = a.Id;
        insert c;
        
        Opportunity o = new Opportunity();
        o.Name = 'Test';
        o.AccountId = a.Id;
        o.StageName = 'Prospecting';
        o.CloseDate = Date.today();
        o.Probability = 25;
        o.Partner_Deal__c = 'NO';
        o.Project__c = true;
        o.Project_Budget__c = true;
        o.Project_Owner__c = true;
        o.Project_Timeline__c = true;
        o.Project_Detail__c = 'blah blah';
        o.Project_Owner_Detail__c = 'me';
        o.Project_Budget_Detail__c = 1000;
        o.Project_Timeline_Detail__c = date.today();
        o.Contract_Type__c = 'New Customer';
        o.inContact__c = 'YES';
        o.inContact_Setup_Fee__c = 1000;
        o.inContact_Seats__c = 1;
        o.inContact_MRC_Min__c = 1000;
        o.inContact_Ports__c = 1;
        o.inContact_MRC_Exp__c = 1000;
        o.ECHO__c = 'NO';
        o.eLearning__c = 'NO';
        o.Hiring__c = 'NO';
        o.WFM__c = 'NO';
        insert o;
        
        //Test StandardTextExtension
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(o);
        OpportunityCreateLoopQuoteCaseExtension oppExt = new OpportunityCreateLoopQuoteCaseExtension(stdCtrl);
        
        oppExt.nCase.Product_or_Service__c = 'T1';
        oppExt.contactId = c.id;
        oppExt.TextDescription = 'Test Description';
        oppExt.Save();
        
        string n = oppExt.TextDescription;
        Id i = oppExt.contactId;
        
        List<SelectOption> cts = oppExt.Contacts;
        
    }

}