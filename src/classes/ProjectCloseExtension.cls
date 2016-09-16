public class ProjectCloseExtension 
{
    private final Project__c p;
    private integer numTasks;
    private integer numCases;
    public string errorMsg{get;set;}
    public boolean renderPage{get;set;}

    public ProjectCloseExtension(ApexPages.StandardController controller) 
    {
        this.p = (Project__c)controller.getRecord();
        
        renderPage = true;
        
        numTasks = [SELECT COUNT() FROM Task WHERE IsClosed = false AND WhatId = :p.Id];
        numCases = [SELECT COUNT() FROM Case WHERE IsClosed = false AND Project__c = :p.Id];
        
        if(numTasks + numCases > 0)
        {
            errorMsg = 'All Tasks and Cases must be closed prior to closing the Project.';
            renderPage = false;
        }
        
        if(p.ProjectStatus__c == 'Closed')
        {
            errorMsg = 'This project is already closed.';
            renderPage = false;
        }
        
        if(p.ProjectStatus__c == 'Canceled')
        {
            errorMsg = 'Canceled projects cannot be closed.';
            renderPage = false;
        }
    }
    
    public PageReference Save()
    {
    
        p.ProjectStatus__c = 'Closed';
        update p;
    
         //go back to project
        PageReference pr = new ApexPages.StandardController(p).view();
        pr.setRedirect(true);
        
        return pr;
    }
    
    public PageReference Cancel()
    {
         //go back to project
        PageReference pr = new ApexPages.StandardController(p).view();
        pr.setRedirect(true);
        
        return pr;
    }

}