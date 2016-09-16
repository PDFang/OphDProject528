public class CaseCloseChildCasesExtension 
{
    private final Case c;
    private List<Case> childCases;
    private String commentBody;
    private Boolean commentCase;
    private Boolean render = true;
    public Boolean ispublic{get;set;}
    public Boolean parentClosed{get;set;}
    private String errorText;
    
    public CaseCloseChildCasesExtension(ApexPages.StandardController controller) 
    {
        this.c = (Case)controller.getRecord();
        
        childCases = [SELECT Id, Reason, CaseNumber, Account.Name, Account.CostGuard_Acct__c, Status, Disposition__c FROM Case WHERE ParentId = :c.Id];
    
        if(childCases.isEmpty())
        {
            render = false;
            errorText = 'There are no child cases to sync.';
        }
        
        if(c.IsClosed)
        {
            parentClosed = true;
        }
        else
        {
            parentClosed = false;
        }
        
        ispublic = true;
    }
    
    public PageReference Save()
    {
        List<CaseComment> caseComments = new List<CaseComment>();
    
        for(Case ch:childCases)
        {
            ch.Status = c.Status;
            ch.Reason = c.Reason;
            ch.Disposition__c = c.Disposition__c;
            
            if(commentCase)
            {
                CaseComment cc = new CaseComment();
                cc.ParentId = ch.Id;
                cc.CommentBody = commentBody;
                cc.IsPublished = ispublic;
                
                caseComments.add(cc);
            }
        }
        
        update childCases;
        
        if(!caseComments.isEmpty() && commentCase)
        {
            insert caseComments;
        }
        
        //return to case page
        PageReference casePage = new PageReference('/' + c.Id);
        casePage.setRedirect(true);
        
        return casePage;
    }

    
    public List<Case> ChildCaseList
    {
        get{return childCases;}
    }
    
    public String CommentBodyText
    {
        get{return commentBody;}
        set{commentBody = value;}
    }
    
    public Boolean CommentCaseCheck
    {
        get{return commentCase;}
        set{commentCase = value;}
    }
    
    public Boolean RenderPage
    {
        get{return render;}
    }
    
    public String ErrorDisplay
    {
        get{return errorText;}
    }
    
    
    public static testMethod void CaseCloseChildCasesExtension()
    {
        //create test account
        Account a = new Account();
        a.Name = 'testName';
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
                
        insert a;
        System.debug('Insert accounts.');
        
        //get record type IDs
        Id rtIncident = '01270000000LuEpAAK';
        Id rtInfo = '01270000000LuEqAAK';
        Id rtWO = '01270000000LuErAAK';
        Id rtCustOther = '01270000000Lrn4AAC';
        
        //create contact
        Contact ct = new Contact();
        ct.LastName = 'LastName';
        ct.Email = 'test@test.com';
        ct.RecordTypeId = rtCustOther;
        ct.AccountId = a.Id;
                    
        insert ct;
        
        //set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
                
        //create test case      
        Case c = new Case();
        c.AccountId = a.Id;
        c.Subject = a.Name;
        c.ContactId = ct.Id;
        c.RecordTypeId = rtIncident;
        c.Request_Type__c = 'Dedicated Facilities Issues';
        c.Product_or_Service__c = 'TF - inContact';
        c.Freqeuncy__c = 'Occasional';
        c.Number_of_Customers_Affected__c = '1';
        c.Severity__c = 'S4';
        
        c.setOptions(dmo);
        
        insert c;
        
        
        //task page
        ApexPages.StandardController caseCont = new ApexPages.StandardController(c);
        CaseCloseChildCasesExtension caseExt = new CaseCloseChildCasesExtension(caseCont);
        
        //create test child case        
        Case cc = new Case();
        cc.AccountId = a.Id;
        cc.ParentId = c.Id;
        cc.Subject = a.Name;
        cc.ContactId = ct.Id;
        cc.RecordTypeId = rtIncident;
        cc.Request_Type__c = 'Dedicated Facilities Issues';
        cc.Product_or_Service__c = 'TF - inContact';
        cc.Freqeuncy__c = 'Occasional';
        cc.Number_of_Customers_Affected__c = '1';
        cc.Severity__c = 'S4';
        
        cc.setOptions(dmo);
        
        insert cc;
        
        ApexPages.StandardController caseCont2 = new ApexPages.StandardController(c);
        CaseCloseChildCasesExtension caseExt2 = new CaseCloseChildCasesExtension(caseCont2);
        
        caseExt2.CommentCaseCheck = true;
        boolean comCheck = caseExt2.CommentCaseCheck;
        
        caseExt2.CommentBodyText = 'Test Comment';
        String commText = caseExt2.CommentBodyText;
        
        boolean rendPage = caseExt2.RenderPage;
        
        String errorText = caseExt2.ErrorDisplay;
        
        List<Case> caseList = caseExt2.ChildCaseList;
        
        PageReference savePage = caseExt2.Save();

    }

}