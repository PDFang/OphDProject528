public class TimesheetGeneratorController 
{
    
    public Timesheet__c ts{get;set;}
    
    public TimesheetGeneratorController ()
    {
        ts = new Timesheet__c();
    }
    
    
    public PageReference Save()
    {
        if(ts.StartDate__c == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Start Date cannot be blank.'));
            return null;
        }
        
        if(ts.StartDate__c > system.today())
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Start Date must be in the past.'));
            return null;
        }
        
        if(ts.OwnerId == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'User is required.'));
            return null;
        }
        
        ts.StartDate__c = ts.StartDate__c.toStartOfWeek();
        
        if([SELECT COUNT() FROM Timesheet__c WHERE OwnerId = :ts.OwnerId AND StartDate__c = :ts.StartDate__c] > 0)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This user already has a timesheet for the request date.'));
            return null;
        }
        
        date endDate = ts.StartDate__c + 6;
        List<TimesheetDay__c> tsDays = new List<TimesheetDay__c>();
        
        
        //ts.OwnerId = userId;
        //ts.StartDate__c = startDate;
        ts.EndDate__c = endDate;
        ts.Status__c = 'Open';
        
        insert ts;
        
        for(integer i=0;i<7;i++)
        {
            TimesheetDay__c td = new TimesheetDay__c();
            td.Timesheet__c = ts.Id;
            td.Date__c = ts.StartDate__c + i;
            tsDays.add(td);
        }
        
        insert tsDays;
        
        ts = new Timesheet__c();
        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The timesheet has been created.'));
        
        return Page.TimesheetGenerator;
    }
    
    static testMethod void TestTimesheetGenerator() 
    {
    	TimesheetGeneratorController tg = new TimesheetGeneratorController();
    	//List<SelectOption> au = tg.ActiveUsers;
    	
    	//test saving with no date
    	tg.Save();
    	tg.ts.StartDate__c = system.today()+10;
    	
    	//save with date in the future
    	tg.Save();
    	tg.ts.StartDate__c = system.today()-1;
    	
    	//save without owner
    	tg.Save();
    	tg.ts.OwnerId = UserInfo.getUserId();
    	
    	//save 
    	tg.Save();
    	
    	//set up duplicate
    	tg.ts.StartDate__c = system.today()-1;
    	tg.ts.OwnerId = UserInfo.getUserId();
    	tg.Save();
    }

}