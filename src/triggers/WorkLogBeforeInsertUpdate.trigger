trigger WorkLogBeforeInsertUpdate on WorkLog__c (after insert, after update, after delete) 
{

    Set<Id> tsDayIds = new Set<Id>();
    Set<Id> projectIds = new Set<Id>();
    Set<Id> assetIds = new set<Id>();
    List<TimesheetDay__c> tsDays = new List<TimesheetDay__c>();
    List<WorkLog__c> wLogs = new List<WorkLog__c>();
    List<WorkLog__c> triggerWL = new List<WorkLog__c>();
    
    
    Map<Id,Decimal> unavail = new Map<Id,Decimal>();
    Map<Id,Decimal> ramp = new Map<Id,Decimal>();
    Map<Id,Decimal> travel = new Map<Id,Decimal>();
    Map<Id,Decimal> project = new Map<Id,Decimal>();
    Map<Id,Decimal> general = new Map<Id,Decimal>();
    Map<Id,Decimal> revenue = new Map<Id,Decimal>();
    
    
    Set<String> unavailType = new Set<String>{'ATO','Holiday'};
    Set<String> rampType = new Set<String>{'New Hire Ramp Up'};
    Set<String> travelType = new Set<String>{'Travel Time'};
    Set<String> generalType = new Set<String>{'General Overhead'};
    //Set<String> projectType = new Set<String>{'Align','Build','Connect','Deploy'};

    if(trigger.isDelete)
    {
        triggerWL = trigger.old;
        
    }
    else
    {
        triggerWL = trigger.new;
    }
        
    for(WorkLog__c wl:triggerWL)
    {
    	if(wl.Project__c != null)
    	{
    		projectIds.add(wl.Project__c);
    	}
    	
        if(wl.TimesheetDay__c != null)
        {
            tsDayIds.add(wl.TimesheetDay__c);
        }
        if(wl.Asset__c != null)
        {
            assetIds.add(wl.Asset__c);
        }
    }
    
    if(!projectIds.isEmpty())
    {
    	
    	Map<Id,Project__c> projects = new Map<Id,Project__c>([SELECT Id, ParentProject__c, TotalWorkLogHours__c FROM Project__c WHERE Id IN:projectIds]);
    	Set<Id> parentProjectIds = new Set<Id>();
    	for(Project__c p:projects.values())
    	{
    		//clear out totals
    		p.TotalWorkLogHours__c = 0;
    		p.TotalBillableWorkLogHours__c = 0;
            if(p.ParentProject__c != null)
            {
            	parentProjectIds.add(p.ParentProject__c);
            }
    	}
    	
    	AggregateResult[] projectTime = [SELECT Project__c, SUM(Hours_Worked__c) FROM WorkLog__c WHERE Project__c IN:projectIds GROUP BY Project__c];
    	AggregateResult[] billableTime = [SELECT Project__c, SUM(Hours_Worked__c) FROM WorkLog__c WHERE Project__c IN:projectIds AND WorkPerformed__c = 'Billable' GROUP BY Project__c];
    	
        if(!parentProjectIds.isEmpty())
        {
    		AggregateResult[] parentProjectTime = [SELECT Project__r.ParentProject__c Parent, SUM(Hours_Worked__c) FROM WorkLog__c WHERE Project__r.ParentProject__c IN:parentProjectIds GROUP BY Project__r.ParentProject__c];
                    
            if(!parentProjectTime.isEmpty())
            {
                
    			Map<Id,Project__c> parentProjects = new Map<Id,Project__c>([SELECT Id, TotalPhaseWorkLogHours__c FROM Project__c WHERE Id IN:parentProjectIds]);
                for(AggregateResult ar:parentProjectTime)
                {
                    Id projId = Id.valueOf(string.valueOf(ar.get('Parent')));
                    decimal hours = decimal.valueOf(string.valueOf(ar.get('expr0')));
                    
                    parentProjects.get(projId).TotalPhaseWorkLogHours__c =  hours;
                }
                
                update parentProjects.values();
            }
        }
                
    	if(!projectTime.isEmpty())
    	{
	    	for(AggregateResult ar:projectTime)
	    	{
	    		Id projId = Id.valueOf(string.valueOf(ar.get('Project__c')));
	    		decimal hours = decimal.valueOf(string.valueOf(ar.get('expr0')));
	    		
	    		projects.get(projId).TotalWorkLogHours__c =  hours;
	    	}
	    	
	    	update projects.values();
    	}
        
    	if(!billableTime.isEmpty())
    	{
	    	for(AggregateResult ar:billableTime)
	    	{
	    		Id projId = Id.valueOf(string.valueOf(ar.get('Project__c')));
	    		decimal hours = decimal.valueOf(string.valueOf(ar.get('expr0')));
	    		
	    		projects.get(projId).TotalBillableWorkLogHours__c =  hours;
	    	}
	    	
	    	update projects.values();
    	}
    	
    }

    //Added to update the assets
    if(!assetIds.isEmpty())
    {
      Map<Id,Asset> assets = new Map<Id,Asset>([SELECT Id, TotalWorkLogHours__c FROM Asset WHERE Id IN:assetIds]);  
      AggregateResult[] totalHours = [SELECT Asset__c, SUM(Hours_Worked__c) FROM WorkLog__c WHERE Asset__c IN:assetIds GROUP BY Asset__c];
      if(!totalHours.isEmpty())
    	{
	    	for(AggregateResult ar:totalHours)
	    	{
	    		Id assetId = Id.valueOf(string.valueOf(ar.get('Asset__c')));
	    		decimal hours = decimal.valueOf(string.valueOf(ar.get('expr0')));
	    		
	    		assets.get(assetId).TotalWorkLogHours__c =  hours;
	    	}
	    	
	    	update assets.values();
    	}    
    }
    
    if(!tsDayIds.isEmpty())
    {
        tsDays = [SELECT Id FROM TimesheetDay__c WHERE Id IN :tsDayIds];
        wLogs = [SELECT Id, Hours_Worked__c, LogType__c, TimesheetDay__c, Project__r.RecordType.Name, Project__r.TotalRevenue__c, Project__r.ListPriceSetupFee__c, Project__r.DiscountPercent__c FROM WorkLog__c WHERE TimesheetDay__c IN :tsDayIds];
        
        for(Id tsd:tsDayIds)
        {
            unavail.put(tsd,0);
            ramp.put(tsd,0);
            travel.put(tsd,0);
            project.put(tsd,0);
            general.put(tsd,0);
            revenue.put(tsd,0);
        }
        
        for(WorkLog__c wl:wLogs)
        {
            if(unavailType.contains(wl.LogType__c))
            {
                unavail.put(wl.TimesheetDay__c,unavail.get(wl.TimesheetDay__c)+wl.Hours_Worked__c);
            }
            else if(rampType.contains(wl.LogType__c))
            {
                ramp.put(wl.TimesheetDay__c,ramp.get(wl.TimesheetDay__c)+wl.Hours_Worked__c);
            }
            else if(travelType.contains(wl.LogType__c))
            {
                travel.put(wl.TimesheetDay__c,travel.get(wl.TimesheetDay__c)+wl.Hours_Worked__c);
            }
            else if(generalType.contains(wl.LogType__c))
            {
                general.put(wl.TimesheetDay__c,general.get(wl.TimesheetDay__c)+wl.Hours_Worked__c);
            }
            else
            {
                project.put(wl.TimesheetDay__c,project.get(wl.TimesheetDay__c)+wl.Hours_Worked__c);
            }
            
            system.debug(wl.Project__r.RecordType.Name);
            system.debug(string.valueOf(wl.Project__r.ListPriceSetupFee__c));
            system.debug(string.valueOf(wl.Project__r.DiscountPercent__c));
            
            if(wl.Project__c != NULL)
            {
            
                if(wl.Project__r.RecordType.Name.contains('PS'))
                {
                        if(wl.Project__r.TotalRevenue__c > 0)
                        {
                            revenue.put(wl.TimesheetDay__c,revenue.get(wl.TimesheetDay__c)+wl.Hours_Worked__c);
                        }
                    
                }
            }
        }
        
        for(TimesheetDay__c tsd:tsDays)
        {
            tsd.UnavailableTime__c = unavail.get(tsd.Id);
            tsd.TravelTime__c = travel.get(tsd.Id);
            tsd.RampUpTime__c = ramp.get(tsd.Id);
            tsd.ProjectTime__c = project.get(tsd.Id);
            tsd.GeneralOverheadTime__c = general.get(tsd.Id);
            tsd.RevenueTime__c = revenue.get(tsd.Id);
            
            /*
            if(tsd.UnavailableTime__c + tsd.TravelTime__c + tsd.RampUpTime__c + tsd.ProjectTime__c + tsd.GeneralOverheadTime__c + tsd.RevenueTime__c > 24)
            {
                triggerWL[0].AddError('Cannot have over 24 work hours in a day.');
                break;
            }
            */
        }
        
        try
        {
            update tsDays;
        }
        catch(DmlException ex)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, ex.getDmlMessage(0));
        }
    }

}