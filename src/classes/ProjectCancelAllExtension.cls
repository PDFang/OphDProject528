public class ProjectCancelAllExtension 
{
    private final Project__c p;
    private String errorMsg;
    public boolean renderPage{get;set;}
    
    public ProjectCancelAllExtension(ApexPages.StandardController controller) 
    {
        this.p = (Project__c)controller.getRecord();
        
        renderPage = true;
        
        if(p.ProjectStatus__c == 'Canceled')
        {
            errorMsg = 'This project is already cancelled.';
            renderPage = false;
        }
        
        if(p.ProjectStatus__c == 'Closed')
        {
            errorMsg = 'You cannot cancel a closed project.';
            renderPage = false;
        }
    }    
    
    public PageReference Save()
    {
        Task[] tasks = [SELECT Id, Status FROM Task WHERE IsClosed = false AND WhatId = :p.Id];
        
        if(!tasks.isEmpty())
        {
            for(Task t:tasks)
            {
                t.Status = 'Cancelled';
            }
            
            update tasks;
        }
        
        Case[] cases = [SELECT ID, Status, Disposition__c, Reason FROM Case WHERE IsClosed = false AND Project__c = :p.Id];
        
        if(!cases.isEmpty())
        {
            for(Case c:Cases)
            {
                c.Status = 'Closed';
                c.Disposition__c = 'Project Cancelled';
                c.Reason = 'Project';
            }
            
            update cases;
        }
        
        p.ProjectStatus__c = 'Canceled';
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
    
    public String ErrorMessageText
    {
        get
        {
            return errorMsg;
        }
    }

}