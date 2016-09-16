global class ChangeRequestTaskExtension {
    
    public BMCServiceDesk__Change_Request__c ccr;
    private boolean renderEdit = false;
    private final boolean isMaster;
    private CCRControlsClass ccrCont;
    private final CCRControls__c ccrValues;
    private final Boolean usesMaintenanceWindow;
    private final String baseURL;
    public Attachment fileToUpload{get;set;}
    
    
    public ChangeRequestTaskExtension(ApexPages.StandardController controller) 
    {
        integer tasks;
        baseURL = URL.getSalesforceBaseUrl().toExternalForm();
    
                //get control info    
        this.ccr = (BMCServiceDesk__Change_Request__c)controller.getRecord();
        ccrCont = new CCRControlsClass('NetworkNew');
        ccrValues = ccrCont.ccrControlRecords;
        isMaster = ccrCont.IsCCBMasterMember(UserInfo.getUserId()); 
        usesMaintenanceWindow = ccrValues.MaintenanceWindow__c;
        fileToUpload = new Attachment();
        //check CCR status to see if needs to render
        if(CCRControlsClass.openStatuses1.contains(ccr.BMCServiceDesk__FKStatus__r.Name))
        {
            renderEdit = true;
        }
        
    }
    
    public List<Attachment> attachments
    {
        get
        {
            return [SELECT Name, ContentType, LastModifiedBy.Name, LastModifiedDate 
            		FROM Attachment 
            		WHERE ParentId = :ccr.Id];
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
            BMCServiceDesk__Task__c[] tasks = [Select ID, BMCServiceDesk__FKChange__c, BMCServiceDesk__templateOrder__c,
            										  BMCServiceDesk__FKOpenBy__c, BMCServiceDesk__FKOpenBy__r.Name, BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name,
            										  RF_Task_Type__c, BMCServiceDesk__taskDescription__c, BMCServiceDesk__dueDateTime__c, BMCServiceDesk__duration__c 
    										   FROM BMCServiceDesk__Task__c 
    										   WHERE BMCServiceDesk__FKChange__c = :ccrId ORDER BY BMCServiceDesk__templateOrder__c];
            

            
            for(BMCServiceDesk__Task__c t:tasks)
            {
                if(t.BMCServiceDesk__dueDateTime__c != null)
                {
                    t.BMCServiceDesk__dueDateTime__c = datetime.newInstanceGmt(t.BMCServiceDesk__dueDateTime__c.date(),t.BMCServiceDesk__dueDateTime__c.time());
                }
            }
            return JSON.serialize(tasks);
    }
    
    @RemoteAction
    global static void JsonUpdateTask(string jsonTask )
    {
    		system.debug('JSON Task*****'+jsonTask);
            boolean newTask = false;
            JSONParser parser = JSON.createParser(jsonTask);
            parser.nextToken();
            parser.nextToken();
            parser.nextToken();
           
            //fetching status Name value from Json TASK to assign correct ID
            Map<String, Object> allAttributes = (Map<String, Object>)JSON.deserializeUntyped(jsonTask); 
            map<string,object> lstObject = (map<string,Object>)allAttributes.get('data');
            map<string,object> lstObject2;
			
			for(string result :lstObject.keyset()) {
					if(result.equalsIgnoreCase('BMCServiceDesk__FKStatus__r')){
						 lstObject2 = (map<string,Object>)lstObject.get(result);
					}
			}
            String jsonStatusName = string.valueof(lstObject2.get('Name'));
            BMCServiceDesk__Task__c task = (BMCServiceDesk__Task__c)parser.readValueAs(BMCServiceDesk__Task__c.class);
            if(string.valueOf(task.Id) == '')
            {
                task.Id = null;
                newTask = true;
            }
            if(task.BMCServiceDesk__dueDateTime__c != null)
            {
                task.BMCServiceDesk__dueDateTime__c = datetime.newInstance(task.BMCServiceDesk__dueDateTime__c.date(),task.BMCServiceDesk__dueDateTime__c.time());
            }
            BMCServiceDesk__Change_Request__c change = retChange(task,Null);
             
            CCRControlsClass ccrCont = new CCRControlsClass('NetworkNew');
            ProcessUpdates(task, change, ccrCont);
            Map<String,Id> statusWithId = CCRControlsClass.StatusName();
            task.BMCServiceDesk__FKStatus__c = statusWithId.get(jsonStatusName.toUpperCase())!= null ?
            								   statusWithId.get(jsonStatusName.toUpperCase()):
            								   task.BMCServiceDesk__FKStatus__c; 
		    task.BMCServiceDesk__FKClient__c = change.BMCServiceDesk__FKInitiator__c != null?change.BMCServiceDesk__FKInitiator__c:null;
            upsert task;
            
            if(newTask && change.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('Ready for Deployment'))
            {
                ccrCont.SendSingleTaskEmailForRfChangeRequest(task.Id, 'You have been assigned a new task on');
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
            List<DropDown> recordTypes = new List<DropDown>();
            Schema.DescribeFieldResult fieldResult = BMCServiceDesk__Task__c.RF_Task_Type__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for(Schema.PicklistEntry r:ple){
            	recordTypes.add(new DropDown(r.getLabel(),r.getValue()));
            } 
            
            return JSON.serialize(recordTypes);
        }
    }
    public string currentStatusValue{
        get
        {
            BMCServiceDesk__Change_Request__c change = retChange(Null,ccr);
            return change.BMCServiceDesk__FKStatus__r.Name;
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
    @TestVisible private static Boolean ValidateRecord(BMCServiceDesk__Task__c task, BMCServiceDesk__Change_Request__c change)
    {
        Integer openTasks = 0; 
        Integer validTasks = 0;
        Map<String,Id> statusWithId = CCRControlsClass.StatusName();
    
        for(BMCServiceDesk__Task__c ccrt: [Select ID, BMCServiceDesk__FKChange__c, 
        										  BMCServiceDesk__templateOrder__c, BMCServiceDesk__FKOpenBy__c, BMCServiceDesk__FKOpenBy__r.Name,
        										  BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name,BMCServiceDesk__taskDescription__c, 
        										  BMCServiceDesk__dueDateTime__c, BMCServiceDesk__duration__c 
										   FROM BMCServiceDesk__Task__c WHERE BMCServiceDesk__FKChange__c = :task.BMCServiceDesk__FKChange__c])
        {
    
            if(ccrt.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('Opened') || 
            	ccrt.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('Approved') || 
            	ccrt.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('On_Hold'))
            {
                openTasks = openTasks + 1;
            }
            
            if(ccrt.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('Opened') || ccrt.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('Approved') || 
               ccrt.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('Closed') || ccrt.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('On_Hold'))
            {
                validTasks = validTasks + 1;
            }
        }
        
        //must have valid task or has to be failed
        if(validTasks == 0 && change.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('Ready for Deployment'))
        {
            
            return false;
           
        }
    
        //if all valid tasks are closed then ccr is deployed   
        if(openTasks == 0 && validTasks > 0 && change.BMCServiceDesk__FKStatus__r.Name.equalsIgnoreCase('Ready for Deployment'))
        {
            CCRControls__c ccrControlRecords = CCRControls__c.getInstance('NetworkNew');
            
            change.BMCServiceDesk__FKStatus__c = statusWithId.get('DEPLOYED')!= null ?
    								   			 statusWithId.get('DEPLOYED'):
    								             '';
            change.RecordTypeId = ccrControlRecords.CCRDeployedRecordTypeID__c;
            
            update change;
        }
        
        return true;

    }
    
    @TestVisible private static BMCServiceDesk__Change_Request__c retChange(BMCServiceDesk__Task__c task,
    														   BMCServiceDesk__Change_Request__c CCRID){
	   	BMCServiceDesk__Change_Request__c change;
    	if(CCRID == Null){
    		change = [SELECT BMCServiceDesk__FKStatus__c,RecordTypeId,BMCServiceDesk__FKStatus__r.Name,BMCServiceDesk__FKInitiator__c
        											FROM BMCServiceDesk__Change_Request__c 
        											WHERE Id = :task.BMCServiceDesk__FKChange__c];
    	}
    	else{
    		 change = [SELECT BMCServiceDesk__FKStatus__c,RecordTypeId,BMCServiceDesk__FKStatus__r.Name,BMCServiceDesk__FKInitiator__c
        												FROM BMCServiceDesk__Change_Request__c 
        												WHERE Id = :CCRID.Id];
    	}
        return change;     
    }
    
    @TestVisible private static void ProcessUpdates(BMCServiceDesk__Task__c task, BMCServiceDesk__Change_Request__c change, CCRControlsClass ccrCont)
    {
        BMCServiceDesk__Task__c oldTask = new BMCServiceDesk__Task__c();
        
        if(task.Id != null)
        {
            oldTask = [SELECT BMCServiceDesk__FKStatus__c, BMCServiceDesk__FKOpenBy__c FROM BMCServiceDesk__Task__c WHERE Id = :task.Id];
            //approved task
            if(task.BMCServiceDesk__FKStatus__r.Name.equalsignoreCase('Approved') && oldTask.BMCServiceDesk__FKStatus__r.Name <> 'APPROVED')
            {
                ccrCont.SendSingleTaskEmailForRfChangeRequest(task.Id, 'Your new task has been approved on');
            }
            else if(task.BMCServiceDesk__FKOpenBy__c != oldTask.BMCServiceDesk__FKOpenBy__c && change.BMCServiceDesk__FKStatus__r.Name.equalsignoreCase('Ready for Deployment'))
            {
                ccrCont.SendSingleTaskEmailForRfChangeRequest(task.Id, 'You have been assigned an existing task on');
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