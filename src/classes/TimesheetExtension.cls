public class TimesheetExtension {
    
    private Timesheet__c ts;
    private List<TimesheetDay__c> td;
    private List<WorkLog__c> wl;
    public List<SelectOption> projectAssets;
    private WorkLog__c newLog;
    private Map<String,Date> wlDates;
    private Map<ID,Decimal> dayTotals;
    private final UserRecordAccess ua;
    public Project__c[] myProjects;
    private List<ExpandedWorkLog> dayWorkLogs;
    public final Boolean renderEdit{get;set;}
    public final Boolean renderPage{get;set;}
    public Decimal totalTime{get;set;}
    public boolean renderNewWl{get;set;}
    public boolean renderLogEdit{get;set;}
    public ID currentId{get;set;}
    private TimesheetDay__c timesheetDay;
    public String rights{get;set;}
    public Date editDate{get;set;}
    public Double hoursDate{get;set;}
    public string product{get;set;}
    public string projectNum{get; set;}
    public string posNum{get; set;}
    public boolean hideAddProjectButton{get; set;}
    private map<id, id> mapProjectRecordTypes = new map<id,id>();
    private final Set<String> GeneralTypes = new Set<String>{'General Overhead','New Hire Ramp Up','ATO','Holiday','Travel Time'};
        
        
        public TimesheetExtension(ApexPages.StandardController controller) 
    {
	
        this.ts = (Timesheet__c)controller.getRecord();
        //get access level for the timesheet
        ua = [Select u.RecordId, u.MaxAccessLevel  From UserRecordAccess u WHERE RecordId = :ts.Id AND UserId = :UserInfo.getUserId()];
        
        rights = ua.MaxAccessLevel;
        product = '';
        //set permission booleans
        if(ua.MaxAccessLevel=='None')
        {
            renderPage = false;
            renderEdit = false;
        }
        else if(ua.MaxAccessLevel=='Read')
        {
            renderPage = true;
            renderEdit = false;
        }
        else if(ts.Status__c != 'Open' && ts.Status__c != 'Rejected')
        {
            renderPage = true;
            renderEdit = false;
        }
        else
        {
            renderPage = true;
            renderEdit = true;
        }
        
        
        renderNewWl = false;
        
        
        //get projects
        myProjects = [SELECT Id, Name, Summary__c, recordTypeId  FROM Project__c WHERE (OwnerId=:ts.OwnerId OR ProjectOwner__r.Id =:ts.OwnerId) AND ClosedDate__c = NULL AND RecordType.Name <> 'Database Administration Request' AND RecordType.Name != 'PS Parent Project - Premise' AND RecordType.Name != 'PS Parent Project - SaaS' ORDER BY Summary__c DESC LIMIT 100];
        if(myProjects.isEmpty())
        {
            myProjects = [SELECT Id, Name, Summary__c, recordTypeId  FROM Project__c WHERE Id IN(SELECT ParentId FROM EntitySubscription WHERE Parent.Type = 'Project__c' AND SubscriberId = :ts.OwnerId) AND RecordType.Name != 'PS Parent Project - Premise' AND RecordType.Name != 'PS Parent Project - SaaS' AND ClosedDate__c = NULL ORDER BY Summary__c DESC LIMIT 100];
        }
        else
        {
            myProjects.addAll([SELECT Id, Name, Summary__c, recordTypeId FROM Project__c WHERE OwnerId!=:ts.OwnerId AND ID IN(SELECT ParentId FROM EntitySubscription WHERE Parent.Type = 'Project__c' AND SubscriberId = :ts.OwnerId) AND RecordType.Name != 'PS Parent Project - Premise' AND RecordType.Name != 'PS Parent Project - SaaS' AND ClosedDate__c = NULL ORDER BY Summary__c DESC LIMIT 100]);
        }
        
        myProjects.sort();
        wlDates = new Map<String,Date>();
        dayTotals = new Map<ID,Decimal>();
        
        RefreshWorkLogs();
        
        dayWorkLogs = new List<ExpandedWorkLog>();
        hideAddProjectButton = false;
        
    }
    
    //adds record with the same project number
    public void AddRecord()
    {
        
        integer refNum;
        string projSum;
        //get line info
        refNum = integer.valueOf(ApexPages.currentPage().getParameters().get('ref'));
        projSum = ApexPages.currentPage().getParameters().get('summ');     
        Id projectId = ApexPages.currentPage().getParameters().get('recId');
        system.debug('projectId ==>' + projectId);
        list<WorkLog__c> lstwl = new list<WorkLog__c>();
        list<selectoption> lstProds = new list<selectoption>();
        list<asset> lstAssets = new list<asset>();
        //create new worklog
        WorkLog__c wl = new WorkLog__c();
        wl.Project__c = projectId;
        //w1.Asset__c = ApexPages.currentPage().getParameters().get('asset');
        wl.OwnerId = ts.OwnerId;
        wl.TimesheetDay__c = timesheetDay.Id;
        
        lstAssets = [select Id, Name, Project_Phase__c from Asset where Project_Phase__c =: projectId and Type__c ='NRC' order by Name];
        system.debug('lstAssets ==> + ' + lstAssets);
        lstProds = getAllProducts(wl, lstAssets);
        ExpandedWorkLog ew = new ExpandedWorkLog(wl, projSum, false, lstProds);
        dayWorkLogs.add(refNum+1,ew);
        
        
    }
    public void changePicklist()
    {
      if(projectNum != '' && projectNum != null)
      {
        hideAddProjectButton = false;
        integer refNum;
        refNum = dayWorkLogs.size();
        list<asset> lstAssets = new list<asset>();
        list<selectoption> lstProds = new list<selectoption>();
        list<Project__c> lstProjects = new list<Project__c>();
        
        
        lstProjects = [select Id, Summary__c from Project__c where Name = :projectNum limit 1];
        
        
        WorkLog__c wl = new WorkLog__c();
        wl.Project__c = lstProjects[0].Id;
        
        lstAssets = [select Id, Name, Project_Phase__c from Asset where Project_Phase__c =: lstProjects[0].Id and Type__c ='NRC' order by Name];
        lstProds = getAllProducts(wl, lstAssets);
        
       // system.debug('dayWorkLogs ==> ' + dayWorkLogs.get(refNum - 1));
        dayWorkLogs.get(refNum - 1).listProducts = lstProds;
        dayWorkLogs.get(refNum - 1).ProjectSummary = lstProjects[0].Summary__c;  
        }
        
    }
   
    //add a project that isn't owned by the timesheet owner
    public void AddNewProject()
    {
        
        //create worklog
        list<selectoption> lstProds = new list<selectoption>();
        list<Asset> lstAssets = new list<Asset>();
        WorkLog__c wl = new WorkLog__c();
        wl.OwnerId = ts.OwnerId;
        wl.TimesheetDay__c = timesheetDay.Id;
        wl.Date_of_Service__c = timesheetDay.Date__c;
       
       
         lstProds = getAllProducts(wl, lstAssets);
        
        ExpandedWorkLog ew = new ExpandedWorkLog(wl, '', false, lstProds);
        dayWorkLogs.add(ew);
        hideAddProjectButton = true;
    }
    
    //refreshes current list of work logs for the timesheet
    public void RefreshWorkLogs()
    {
        td = [Select t.Id, t.Date__c, (Select Id, Hours_Worked__c, WorkNotes__c, LogType__c, Asset__c, Project__r.Summary__c, Project__c From Work_Logs__r) From TimesheetDay__c t WHERE t.Timesheet__c = :ts.Id ORDER BY t.Date__c];
        
        Decimal tTime = 0;
        Decimal dTime = 0;
        
        //get time totals
        for(TimesheetDay__c tsd:td)
        {
            dTime = 0;
            
            wlDates.put(tsd.Id,tsd.Date__c);
            WorkLog__c[] eWl = tsd.Work_Logs__r;
            for(WorkLog__c w:eWl)
            {
                dTime = dTime + w.Hours_Worked__c;
                tTime = tTime + w.Hours_Worked__c;
            }
            
            dayTotals.put(tsd.Id,dTime);
        }
        
        totalTime = tTime;
    }
    
    public void CancelLogEdit()
    {
        renderLogEdit = false;
    }
    
    public void SaveLogEdit()
    {
        hideAddProjectButton = false;
        List<WorkLog__c> wls = new List<WorkLog__c>();
        List<WorkLog__c> wlDelete = new List<WorkLog__c>();
        
        //validations
        if(hoursDate > 24)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot have over 24 work hours in a day.'));
            return;
        }
        
        for(ExpandedWorkLog ew:dayWorkLogs)
        {
            /**if(ew.WorkLog.Hours_Worked__c > 0 && ew.WorkLog.LogType__c == NULL)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'All projects with time are required to have a log type.'));
                return;
            }**/
            if(ew.WorkLog.Project__c == NULL && !GeneralTypes.contains(ew.selectedProduct) && ew.WorkLog.Hours_Worked__c > 0)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select a project for all non-General Overhead projects.'));
                return;
            }
            else if(ew.WorkLog.Hours_Worked__c > 0 )
            {
                if(ew.selectedProduct.startsWithIgnoreCase('02i'))
                    ew.WorkLog.Asset__c = ew.selectedProduct;
                else if(ew.selectedProduct != 'NONE')
                    ew.WorkLog.LogType__c = ew.selectedProduct;
                    
                wls.Add(ew.WorkLog);
            }
            else if(ew.WorkLog.Id != NULL && (ew.WorkLog.Hours_Worked__c == 0 || ew.WorkLog.Hours_Worked__c == NULL))
            {
                wlDelete.add(ew.WorkLog);
            }
        }
        
        system.debug('wls ==>' + wls);
        
        if(!wls.isEmpty())
        {
            upsert wls;
        }
        
        if(!wlDelete.isEmpty())
        {
            delete wlDelete;
        }
        
        renderLogEdit = false;
        RefreshWorkLogs();
    }
    
    //get current hours total for the date
    public void UpdateHoursDate()
    {
        hoursDate = 0;
         
        for(ExpandedWorkLog dw:dayWorkLogs)
        {
            if(dw.WorkLog.Hours_Worked__c != NULL)
            {
                hoursDate = hoursDate + dw.WorkLog.Hours_Worked__c;
            }
        }
    }
    
    
    public void EditDate()
    {
        
        Date workDate;  
        String wlId;
        map<Id, list<asset>> mapAssets = new map<Id, list<asset>>();
        list<selectoption> lstProds = new list<selectoption>();
         hideAddProjectButton = false;
        wlId = ApexPages.currentPage().getParameters().get('wlDate');
        workDate = wlDates.get(wlId);
        editDate = workDate;
        renderLogEdit = true;
        hoursDate = 0;
        
        
        Set<Id> incProj = new Set<Id>();
        WorkLog__c[] dl = new WorkLog__c[]{};
            Map<String,WorkLog__c> genWl = new Map<String,WorkLog__c>();
        Boolean lock = false;
        dayWorkLogs.clear();
        
        //get info for the current day
        timesheetDay = [SELECT Id, Date__c FROM TimesheetDay__c WHERE Date__c = :workDate AND Timesheet__c = :ts.Id];
        
        dl = [SELECT Id, LogType__c, Asset__c, 
		        Hours_Worked__c, WorkNotes__c, Project__c,Project__r.RecordTypeId,
    		Project__r.Summary__c FROM WorkLog__c WHERE TimesheetDay__c = :timesheetDay.id ORDER BY Project__r.Name];
        system.debug('dl =>> ' + dl);
        
        for(WorkLog__c wl : dl)
        {
            incProj.add(wl.Project__c);
        }
        
        for( Asset ast : [select Id, Name, Project_Phase__c from Asset where (Project_Phase__c in :incProj or Project_Phase__c in : myProjects) and Type__c ='NRC' order by CreatedDate Desc])
        {
           
           if(!mapAssets.containsKey(ast.Project_Phase__c))
               mapAssets.put(ast.Project_Phase__c, new list<Asset>{ast});
            else
               mapAssets.get(ast.Project_Phase__c).add(ast);
        }
        
        //get all current worklogs
        for(WorkLog__c wl:dl)
        {
           lock = false;
           lstProds = new list<selectoption>();
           mapProjectRecordTypes.put(wl.Project__c, wl.Project__r.RecordTypeId);
           lstProds =  getAllproducts(wl, mapAssets.get(wl.Project__c));
               
            hoursDate = hoursDate + wl.Hours_Worked__c;
            
            if(GeneralTypes.contains(wl.LogType__c))
            {
                genWl.put(wl.LogType__c, wl);
            }
            else
            {
                ExpandedWorkLog ew = new ExpandedWorkLog(wl, wl.Project__r.Summary__c, lock, lstProds);
                ew.selectedProduct = wl.Asset__c == null ? wl.LogType__c : wl.Asset__c;
                dayWorkLogs.add(ew);
            }
        }
        
        //create record for owned projects without worklogs
        for(Project__c p:myProjects)
        {
            if(!incProj.contains(p.Id))
            {
                mapProjectRecordTypes.put(p.Id, p.RecordTypeId);
                WorkLog__c wl = new WorkLog__c();
                wl.Project__c = p.Id;
                wl.TimesheetDay__c = timesheetDay.Id;
                wl.Date_of_Service__c = timesheetDay.Date__c;
                wl.OwnerId = ts.OwnerId;
                lstProds = new list<selectoption>();
                lstProds =  getAllproducts(wl, mapAssets.get(p.Id));
                //wl.Project__r.Summary__c = p.Summary__c;
                
                ExpandedWorkLog ew = new ExpandedWorkLog(wl, p.Summary__c, false, lstProds);
                dayWorkLogs.add(ew);
                
            }
        }
        
        //add all the general worklog types
        dayWorkLogs.addAll(NewGeneralWorkLog(genWl));
        system.debug('dayworklogs ==>' + dayWorkLogs);
    }
    
    //greate worklogs for general types
    public List<ExpandedWorkLog> NewGeneralWorkLog(Map<String,WorkLog__c> existing)
    {
        
        List<ExpandedWorkLog> ew = new List<ExpandedWorkLog>();
        list<selectoption> lstProds = new list<selectoption>();
        string projectSummary ='';
        if(existing.isEmpty())
        {
            for(String s:GeneralTypes)
            {
                lstProds = new list<selectoption>();
                WorkLog__c wl = new WorkLog__c();
                lstProds.add(new selectoption(s,s));
                wl.OwnerId = ts.OwnerId;
                wl.TimesheetDay__c = timesheetDay.Id ;
                wl.Date_of_Service__c = timesheetDay.Date__c;
                projectSummary = 'General Types - ( ' + s +' )';  
                ExpandedWorkLog e = new ExpandedWorkLog(wl,projectSummary,true, lstProds);
                e.selectedProduct = s;
                ew.add(e);
            }
        }
        else
        {
           
            for(String s:GeneralTypes)
            {
                WorkLog__c wl = new WorkLog__c();
            
                if(existing.containsKey(s))
                {
                    wl = existing.get(s);
                    lstProds.add(new selectoption(wl.LogType__c,wl.LogType__c));
                }
                else
                {
                    wl.LogType__c = s;
                    lstProds.add(new selectoption(s,s));
                    wl.OwnerId = ts.OwnerId;
                    wl.TimesheetDay__c = timesheetDay.id ;
                    wl.Date_of_Service__c = timesheetDay.Date__c;
                }
                
                ExpandedWorkLog e = new ExpandedWorkLog(wl,'',true, lstProds);
                e.selectedProduct = s;
                ew.add(e);
            }
        }
        
        return ew;
    }
    
    public List<TimesheetDay__c> Days
    {
        get
        {
            
            return td;
        }
    }
    
    public List<ExpandedWorkLog> DayWorkLogList
    {
        get{return dayWorkLogs;}
    }
    
    
    public Decimal StartValue
    {
        get{return 0.00;}
    }
    /*
        public List<SelectOption> ProjectAssetList
    {
     //   get{return projectAssets;}
    }
    */
	public List<SelectOption> getAllProducts(WorkLog__c wL, list<Asset> lstAssets )
	{
	    List<SelectOption> products = new List<SelectOption>();
	    boolean isPhase = isPhaseProject(wl.Project__c);
        if(lstAssets != null && lstAssets.size() > 0)
        { 
    	   for(Asset ast : lstAssets)
    		{
    		    if(wl.Project__c == ast.Project_Phase__c)
    		         products.add(new selectoption(ast.Id, ast.Name));
    		}    
        }
        
        if(isPhase && products.size() == 0)
                products.add(new selectoption('NONE', '--No assets found--'));
        if(products.size() == 0)
            products =   getWorklogproducts();
        
        return products;		
	}

    private list<selectOption> getWorklogproducts()
    {
        List<SelectOption> products = new List<SelectOption>();   
        Schema.DescribeFieldResult fieldResult =  WorkLog__c.LogType__c.getDescribe();
        List<Schema.PicklistEntry> allProducts = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : allProducts)
        {
            products.add(new selectoption(f.getLabel(), f.getValue()));
        }
        return products;
    }

    public boolean isPhaseProject(Id ProjectId)
    {
        Id recordTypeId;
        
        if(mapProjectRecordTypes.containsKey(ProjectId))
            recordTypeId = mapProjectRecordTypes.get(ProjectId);
        else if(ProjectId != null)       
            recordTypeId = [select RecordTypeId from Project__c where Id =: ProjectId limit 1].RecordTypeId;
            
        if(recordTypeId == '01270000000MzfQAAS' || recordTypeId == '01270000000MzfRAAS'
            || recordTypeId == '01270000000N0oBAAS' || recordTypeId == '01270000000N0oCAAS')
            { 	
                return true;
            }
         return false;   
            
    }

    //wrapper class
    public Class ExpandedWorkLog
    {
        public string ProjectSummary{get;set;}
        public WorkLog__c WorkLog{get;set;}
		public List<SelectOption> listProducts{get; Set;}
        public Boolean locked{get;set;}
        public string selectedProduct{get;set;}
        
        public ExpandedWorkLog(WorkLog__c wl, String ProjectSum, Boolean lock, List<SelectOption> prods)
        {
            //ExpandedWorkLog ew = new ExpandedWorkLog();
            ProjectSummary = ProjectSum;
            WorkLog = wl;
            locked = lock;            
			listProducts = prods;
            selectedProduct = '';
        }
    }
}