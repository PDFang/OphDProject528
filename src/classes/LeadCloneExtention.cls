public class LeadCloneExtention 
{
        
    private Lead l;
    public Lead cloneLead;

    public LeadCloneExtention(ApexPages.StandardController controller) 
    {
        this.l = (Lead)controller.getRecord();
        //clear out first and last name fields
        //l.LastName = '';
        //l.FirstName = '';
                       
    }

    public PageReference Save()
    {
        //clone lead
        cloneLead = l.clone(false);
        
        //set specific fields
        cloneLead.Cloned__c = true;
        cloneLead.ClonedFromLead__c = l.Id;
        cloneLead.Original_Lead_Source__c = l.Original_Lead_Source__c;
        cloneLead.LeadSource = 'Cloned Lead'; 
        cloneLead.Lead_Source_Detail__c = 'Cloned Lead';
        cloneLead.Marketing_Channel__c = l.Marketing_Channel__c;
        insert cloneLead;
        
        //send to new lead
        PageReference leadPage = new PageReference('/' + cloneLead.Id);
        leadPage.setRedirect(false);
    
    return leadPage;
    }
    
    public static testMethod void TestLeadCloneExtension()
    {
        //create new lead for test
        Lead l = new Lead();
        l.FirstName = 'test';
        l.LastName = 'test';
        l.Email = 'test@incontact.com';
        l.Company = 'inContact';
        
        insert l;
        
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(l);
        LeadCloneExtention lc = new LeadCloneExtention(stdCtrl);
        
        //lc.cloneLead.LastName = 'test';
        lc.Save();
        
    }
}