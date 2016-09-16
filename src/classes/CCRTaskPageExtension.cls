global class CCRTaskPageExtension 
{
        
    private final ChangeControlRequest__c ccr;
    private boolean renderEdit = false;
    private boolean renderNewTask = false;
    private boolean renderEditTask = false;
    private final boolean isMaster;
    private final String ccrType;
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    private final Boolean usesMaintenanceWindow;
    private final String baseURL;
    public Attachment fileToUpload{get;set;}
    public string lineItemId {get;set;}
    
    public CCRTaskPageExtension(ApexPages.StandardController controller) 
    {
        integer tasks;
        baseURL = URL.getSalesforceBaseUrl().toExternalForm();
    
                //get control info    
        this.ccr = (ChangeControlRequest__c)controller.getRecord();
        ccrType = ccr.CCRType__c;
        ccrCont = new CCRControlsClass(ccrType);
        ccrValues = ccrCont.ccrControlRecords;
        isMaster = ccrCont.IsCCBMasterMember(UserInfo.getUserId()); 
        usesMaintenanceWindow = ccrValues.MaintenanceWindow__c;
        fileToUpload = new Attachment();
        
        
        //check CCR status to see if needs to render
        if(ccrCont.openStatuses.contains(ccr.Status__c))
        {
            renderEdit = true;
        }
        
    }
    
    public List<Attachment> attachments
    {
        get
        {
            return [SELECT Name, ContentType, LastModifiedBy.Name, LastModifiedDate FROM Attachment WHERE ParentId = :ccr.Id];
        }
    }
    
    public PageReference SaveAttachment()
    {
        if(fileToUpload.Body == null)
        {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Attachments have been selected.'));
                return null;
        }
        
        fileToUpload.ParentId = ccr.Id;
        insert fileToUpload;
        fileToUpload = new Attachment();
        return null;
    }
    
    
    @RemoteAction
    global static String JSONTasks(string ccrId)
    {
            CCRTask__c[] tasks = [Select ID, ChangeControlRequest__c, Order__c, AssignedTo__c, AssignedTo__r.Name, Status__c, RecordTypeId, RecordType.Name, Description__c, TaskDateTime__c, Duration__c FROM CCRTask__c WHERE ChangeControlRequest__c = :ccrId ORDER BY Order__c];
            

            
            for(CCRTask__c t:tasks)
            {
                if(t.TaskDateTime__c != null)
                {
                    t.TaskDateTime__c = datetime.newInstanceGmt(t.TaskDateTime__c.date(),t.TaskDateTime__c.time());
                }
            }
            
            return JSON.serialize(tasks);
    }
    
    @RemoteAction
    global static void JsonUpdateTask(string jsonTask )
    {
            boolean newTask = false;
            
            JSONParser parser = JSON.createParser(jsonTask);
            parser.nextToken();
            parser.nextToken();
            parser.nextToken();
            CCRTask__c task = (CCRTask__c)parser.readValueAs(CCRTask__c.class);
            
            if(string.valueOf(task.Id) == '')
            {
                task.Id = null;
                newTask = true;
            }
            if(task.TaskDateTime__c != null)
            {
                task.TaskDateTime__c = datetime.newInstance(task.TaskDateTime__c.date(),task.TaskDateTime__c.time());
            }
            
            
            ChangeControlRequest__c change = [SELECT Status__c, RecordTypeId, CCRType__c FROM ChangeControlRequest__c WHERE Id = :task.ChangeControlRequest__c];
            CCRControlsClass ccrCont = new CCRControlsClass(change.CCRType__c);
            
            ProcessUpdates(task, change, ccrCont);
            
            upsert task;
            
            if(newTask && change.Status__c == 'Ready for Deployment')
            {
                ccrCont.SendSingleTaskEmail(task.Id, 'You have been assigned a new task on');
            }
            
            if(!ValidateRecord(task, change))
            {
                task.addError('All tasks are listed as Failed or Cancelled.  Go back to the CCR and click the CCR Failed button.');
            }
    }
    
    
    @RemoteAction
    global static string JsonTaskAssignee()
    {                    
                    //new list for holding all of the picklist options
                    List<DropDown> options = new List<DropDown>(); 
                    
                    for(User u: [SELECT Id, Name FROM User WHERE UserType = 'Standard' and IsActive = true ORDER BY Name])
                    {
                        options.add(new DropDown(u.Id, u.Name)); 
                    
                    }
                                             
                    return JSON.serialize(options);
    }
    
    public string TaskRecordTypes
    {
        get
        {
             Schema.DescribeSObjectResult d = Schema.SObjectType.CCRTask__c; 
            Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
            List<DropDown> recordTypes = new List<DropDown>();
            
            for(Schema.RecordTypeInfo r:rtMapByName.values())
            {
                if(r.getName() != 'Master')
                {
                    recordTypes.add(new DropDown(r.getRecordTypeId(),r.getName()));
                }
            }
            
            return JSON.serialize(recordTypes);
        }
    }
    
    public Class DropDown
    {
        public string label;
        public string value;
        
        public DropDown(string valueString, string labelString)
        {
            label = labelString;
            value = valueString;
        }
    }
    
    //check to see number valid vs open tasks
    private static Boolean ValidateRecord(CCRTask__c task, ChangeControlRequest__c change)
    {
        Integer openTasks = 0;
        Integer validTasks = 0;
        
    
        for(CCRTask__c ccrt: [Select ID, ChangeControlRequest__c, Order__c, AssignedTo__c, AssignedTo__r.Name, Status__c, RecordTypeId, RecordType.Name, Description__c, TaskDateTime__c, Duration__c FROM CCRTask__c WHERE ChangeControlRequest__c = :task.ChangeControlRequest__c])
        {
    
            if(ccrt.Status__c == 'Open' || ccrt.Status__c == 'Approved' || ccrt.Status__c == 'On Hold')
            {
                openTasks = openTasks + 1;
            }
            
            if(ccrt.Status__c == 'Open' || ccrt.Status__c == 'Approved' || ccrt.Status__c == 'Closed' || ccrt.Status__c == 'On Hold')
            {
                validTasks = validTasks + 1;
            }
        }
        
        //must have valid task or has to be failed
        if(validTasks == 0 && change.Status__c == 'Ready for Deployment')
        {
            
            return false;
           
        }
    
        //if all valid tasks are closed then ccr is deployed   
        if(openTasks == 0 && validTasks > 0 && change.Status__c == 'Ready for Deployment')
        {
            CCRControls__c ccrControlRecords = CCRControls__c.getInstance(change.CCRType__c);
            
            change.Status__c = 'Deployed';
            change.RecordTypeId = ccrControlRecords.CCRDeployedRecordTypeID__c;
            
            update change;
        }
        
        return true;

    }
    
    private static void ProcessUpdates(CCRTask__c task, ChangeControlRequest__c change, CCRControlsClass ccrCont)
    {
        CCRTask__c oldTask = new CCRTask__c();
        
        if(task.Id != null)
        {
            oldTask = [SELECT Status__c, AssignedTo__c FROM CCRTask__c WHERE Id = :task.Id];
            
            //approved task
            if(task.Status__c == 'Approved' && oldTask.Status__c <> 'Approved')
            {
                ccrCont.SendSingleTaskEmail(task.Id, 'Your new task has been approved on');
            }
            else if(task.AssignedTo__c != oldTask.AssignedTo__c && change.Status__c == 'Ready for Deployment')
            {
                ccrCont.SendSingleTaskEmail(task.Id, 'You have been assigned an existing task on');
            }
        }
    }
    
    
    //tell vf page if edits allowed
    public Boolean AllowEdits
    {
        get{return renderEdit;}
    }
    
    //used to display additional vf components if isMaster
    public Boolean IsCCBMaster
    {
        get{return isMaster;}
    }
    
    //display network info
    public Boolean UseMaintenanceWindow
    {
        get{return usesMaintenanceWindow;}
    }
 
    
    
       

}