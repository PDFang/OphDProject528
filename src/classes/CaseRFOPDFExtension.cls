public class CaseRFOPDFExtension
{

    public Case c;

    public CaseRFOPDFExtension(ApexPages.StandardController controller) 
    {
        this.c = (Case)controller.getRecord();
        
        //check if parent is null 
        if(c.ParentId != null)
        {
            getParentCase(c.ParentId);
        }

    }
    
    private void GetParentCase(Id childId)
    {
        //set the current case equal to the parent case
        c = [SELECT Id, CaseNumber, LastModifiedBy.Name, LastModifiedBy.UserRole.Name, RFECreator__r.Name, RFECreator__r.UserRole.Name, DescriptionOfIssue__c, CorrectiveActions__c, NextSteps__c, RootCause__c, RFEStartDate__c, RFEEndDate__c FROM Case WHERE Id = :childId];
    }
    
    public Case CaseToUse
    {
        //send current case to visualforce page.
        get
        {
            return c;
        }
    }
    
    static testMethod void TestCaseRFOPDF()
    {
        //create test account
        Account a = new Account();
        a.Name = 'testName';
        a.Site = 'Test';
        a.CS_AM__c = UserInfo.getUserId();
        a.CSM__c = UserInfo.getUserId();
                
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
        Case nc = new Case();
        nc.AccountId = a.Id;
        nc.Subject = a.Name;
        nc.ContactId = ct.Id;
        nc.RecordTypeId = rtWO;
        nc.Request_Type__c = 'Adds/Moves/Changes';
        nc.Product_or_Service__c = 'DIA';
        nc.Status = 'New';
        nc.Freqeuncy__c = 'Occasional';
        nc.Number_of_Customers_Affected__c = '1';
        nc.Severity__c = 'S4';
        
        nc.setOptions(dmo);
        
        insert nc;
        
        //create test case      
        Case nc2 = new Case();
        nc2.AccountId = a.Id;
        nc2.ParentId = nc.Id;
        nc2.Subject = a.Name;
        nc2.ContactId = ct.Id;
        nc2.RecordTypeId = rtWO;
        nc2.Request_Type__c = 'Adds/Moves/Changes';
        nc2.Product_or_Service__c = 'DIA';
        nc2.Status = 'New';
        nc2.Freqeuncy__c = 'Occasional';
        nc2.Number_of_Customers_Affected__c = '1';
        nc2.Severity__c = 'S4';
        
        nc2.setOptions(dmo);
        
        insert nc2;
        
        //Test BackstagePassExtension constructor
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(nc2);
        CaseRFOPDFExtension crfEx = new CaseRFOPDFExtension(stdCtrl);
        
        Case tc = new Case();
        tc = crfEx.CaseToUse;       
    } 

}