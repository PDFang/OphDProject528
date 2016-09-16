public with sharing class ProjectCommentsExtension {

    private ProjectComment__c pc;
    private Project__c p;
    public WorkLog__c wl{get;set;}
    public boolean renderWorkLog{public get;private set;}
    public string workPerformed {get;set;}

    public ProjectCommentsExtension(ApexPages.StandardController controller) 
    {
        pc = (ProjectComment__c)controller.getRecord();
        string pId = ApexPages.currentPage().getParameters().get('CF00N70000002hBuN_lkid');
        if(pId==null)
        {
            pId = pc.Project__c;
        }
        p = [SELECT Name, Summary__c, RecordType.Name FROM Project__c WHERE Id = :pId];
        
        renderWorkLog = false;
        
        if(p.RecordType.Name == 'Connectivity Design')
        {
            renderWorkLog = true;
            wl = new WorkLog__c();
            wl.Date_of_Service__c = system.today();
            wl.OwnerId = UserInfo.getUserId();
            wl.Project__c = p.Id;
        }
        
        
        
    }
    
    public string Summary
    {
        get{return p.Summary__c;}
    }
    
    public string ProjectNumber
    {
        get{return p.Name;}
    }
    
    public PageReference Save()
    {
        try
        {
            upsert pc;
        }
        catch(DmlException ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
            return null;
        }
        
        if(p.RecordType.Name == 'Connectivity Design')
        {
            if(workPerformed==null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Work is required'));
                return null;
            }
            
            wl.ProjectComment__c = pc.Id;
            wl.WorkPerformed__c = workPerformed;
            
            try
            {
                insert wl;            
            }
            catch(DmlException ex)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
                return null;
            }
        }
        
        //send to new lead
        PageReference proj = new PageReference('/' + p.Id);
        proj.setRedirect(false);
    
        return proj;
    }

}