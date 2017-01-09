public class ISIntegrationHandlerClass
{
	 public static string SerializeObject(string sObjectId, string sObjectType)
     {
         string serializedString = '';
         if(sObjectType == 'Project__c')
            serializedString =  SerializeProjects(sObjectId);
         if(sObjectType == 'ISTFSWorkItem__c')
            serializedString =  SerializeWorkItems(sObjectId);
         if(sObjectType == 'ISTFSWorkItemComment__c')
            serializedString =  SerializeComments(sObjectId);
         if(sObjectType == 'ProjectComment__c')
             serializedString =  SerializeProjectComments(sObjectId);
         else if(sObjectType == 'Topic')
            serializedString = SerializeTopics(sObjectId);
         
         
		return serializedString;
     }
    
    
	public static void updateSObjects(map<id, string> idsToUpdate, boolean isError)
    {
        if(!isError)
            sObjectupdate(idsToUpdate);
        else
            UpdateError(idsToUpdate);
    }
    
    
   // Returns a JSON for Features
    private static string SerializeProjects(string sObjectId)
    {
      
        string JSONParams;	
		// loop through all projects
        for(Project__c proj : [select ProjectType__c, Priority__c, TargetCompletionDate__c,ProjectStatus__c,Product__c,Area__c,ProjectTFSStatus__c,
                      		   ProjectSubType__c, Name,Status__c, Description__c,Summary__c, /**Iteration__c,**/ Team__c, ProblemStatement__c,TFSId__c
		              		   FROM  Project__c 
                               Where Id = : sObjectId])
        {
           integer priority = getPriorityForTFS(proj.Priority__c);
           string salesforceURL =  proj.Id;
           Integer tfsId = proj.TFSId__c == null ? 0 : integer.valueOf(proj.TFSId__c);
           FeatureWrapperParams wrapper = new FeatureWrapperParams
                                         (
                                          salesforceURL,
                                          priority,
                                          string.valueOf(proj.TargetCompletionDate__c),
                                          proj.ProjectType__c,
                                          proj.ProjectSubType__c,
                                          tfsId,
                                          proj.Name + ' - ' + proj.Summary__c, // added project number prefix
                                          proj.ProjectTFSStatus__c,
                                          8,                                                
                                          proj.ProblemStatement__c,
                                          null,                                                 
                                          proj.Team__c,
                                          proj.Area__c                                                     
                                         );
               
          	JSONParams = JSON.serialize(wrapper);    
            system.debug('JSONParams =>' + JSONParams);
           // FeatureLists.add(JSONParams);  
           }    
           
           
          
           return JSONParams;
       } 
    
    // Returns a JSON for Work Items
    private static string SerializeWorkItems(string sObjectId)
    {
		//list<WorkItemsWrapperParams> WorkItemLists = new list<WorkItemsWrapperParams>();
        string JSONParams;
        for(ISTFSWorkItem__c workItem : [Select AssignedTo__c, Details__c, Product__c, Priority__c,Risk__c, RecordType.Name,Area__c,
                             	 	 PrivacyImpact__c, Project__c, StackRank__c, WorkItemTFSState__c, StoryPoints__c, Team__c,Project__r.TFSId__c,
                              		 TFSId__c, Title__c From ISTFSWorkItem__c 
                                     Where Id = :sObjectId])
        {
            WorkItemsWrapperParams wrapper = new WorkItemsWrapperParams();
            //wrapper.Id =  workItem.TFSId__c == null ? null : Integer.valueOf(workItem.TFSId__c);
            wrapper.SalesforceRecordId = workItem.Id; 
            wrapper.TfsCreatedDate = NUll;
            wrapper.AssignedTo = Null;                       
            wrapper.Priority = getPriorityForTFS(workItem.Priority__c);
            wrapper.Risk  = NUll; 
            wrapper.StackRank =  0.0;
            wrapper.State = workItem.WorkItemTFSState__c; 
            wrapper.Description  = WorkItem.Details__c; 
            wrapper.Title = workItem.Title__c;
            wrapper.WorkItemType = workItem.RecordType.Name; 
            wrapper.Team = workItem.Team__c;  
          	wrapper.PrivacyImpact = getPrivacyImpactInt(workItem.PrivacyImpact__c);
            wrapper.ParentId = workItem.Project__r.TFSId__c;
            wrapper.TfsId =  workItem.TFSId__c == null ? null : Integer.valueOf(workItem.TFSId__c);
            wrapper.Area = workItem.Area__c;
            JSONParams = JSON.serialize(wrapper);
            system.debug('JSONParams =>' + JSONParams); 
            
        }          
           
           return JSONParams;
    }
    
    
    // Returns a JSON for Work Item comments
    private static string SerializeComments(string sObjectId)
    {
        //list<CommentsWrapper> comments = new list<CommentsWrapper>();
        string JSONParams;
     	for(ISTFSWorkItemComment__c comment : [Select Comment__c, ParentId__r.TFSId__c, SyncToTFS__c, CreatedBy.Name
                       							From ISTFSWorkItemComment__c 
                                                Where Id = :sObjectId])
        {
            CommentsWrapper wrapper = new CommentsWrapper
                						(
                                            Integer.valueOf(comment.ParentId__r.TFSId__c),
                                            comment.CreatedBy.Name,
                                            comment.Comment__c
                                        );
            
            
           JSONParams = JSON.serialize(wrapper);
           system.debug('JSONParams =>' + JSONParams); 
        }
        
        
        return JSONParams;
    }
    
    // Returns a JSON for Project comments
    private static string SerializeProjectComments(string sObjectId)
    {
        //list<CommentsWrapper> comments = new list<CommentsWrapper>();
        string JSONParams;
     	for(ProjectComment__c comment : [Select Comment__c, Project__r.TFSId__c, SyncToTFS__c, CreatedBy.Name
                       							From ProjectComment__c 
                                                Where Id = :sObjectId])
        {
            CommentsWrapper wrapper = new CommentsWrapper
                						(
                                            Integer.valueOf(comment.Project__r.TFSId__c),
                                            comment.CreatedBy.Name,
                                            comment.Comment__c
                                        );
            
            
           JSONParams = JSON.serialize(wrapper);
           system.debug('JSONParams Project Comment=>' + JSONParams); 
        }
        
        
        return JSONParams;
    }
    
    
     // Returns a JSON for Tags
    private static string SerializeTopics(string sObjectId)
    {
        //list<CommentsWrapper> comments = new list<CommentsWrapper>();
        string JSONParams;
        map<Id, Integer> mpTagsWithObjects = new map<Id, Integer>();
        
        Id objId = (Id)sObjectId; 
        Schema.SObjectType sobjectType = objId.getSObjectType();
		String sobjectName = sobjectType.getDescribe().getName();
        list<string> taglist = new list<string>();
        
        string queryStr = 'select TFSId__c from ' + sobjectName + ' where Id = :sObjectId Limit 1';  
        sObject record =  Database.query(queryStr);
        
        
        
     	for(TopicAssignment ta : [select Topic.Name, EntityId From TopicAssignment where EntityId = :sObjectId])
        {
            taglist.add(ta.Topic.Name);
        }
        
        TagsWrapper wrapper = new TagsWrapper
                						(
                                            Integer.valueOf(record.get('TFSId__c')),
                                            taglist
                                        );
        
        JSONParams = JSON.serialize(wrapper);
        system.debug('JSONParams tags=>' + JSONParams); 
        return JSONParams;
    }
    
    
    
    
    // convert priority to integer	
    private static integer getPriorityForTFS(string priority)
	{
  		integer intPriority = priority == 'High' ? 1 : priority == 'Normal' ? 2 : 3;
        return intPriority;
	}
    
    private static integer getPrivacyImpactInt(string privacyImpact)
    {
        integer intPI = privacyImpact == '3-Storage' ? 2 : privacyImpact == '2-Transport'? 1 : 0;
        return intPI;
       
    }
    
    
    //Update sObject    
    private static void sObjectupdate(map<id, string> mapTFSIdsToUpdate)
    {
        List<SObject> sObjectsToUpdate = new List<SObject>();
        for(Id sObjId : mapTFSIdsToUpdate.keySet())
        {
            SObject obj1 = sObjId.getSObjectType().newSObject(sObjId);
            
            obj1.put('TFSId__c', mapTFSIdsToUpdate.get(sObjId));
            obj1.put('LastSyncDate__c', system.now());
            obj1.put('TFSError__c', '');            
            obj1.put('SyncToTFS__c', false);
            sObjectsToUpdate.add(obj1);
        }
        
        update sObjectsToUpdate;
    }
    
    // error update
    private static void UpdateError(map<id, string> errorIds)
    {
        List<SObject> sObjectsToUpdate = new List<SObject>();
        for(Id sObjId : errorIds.keySet())
        {
            SObject obj1 = sObjId.getSObjectType().newSObject(sObjId);
            
            obj1.put('TFSError__c', errorIds.get(sObjId));
            obj1.put('SyncToTFS__c', false);
            sObjectsToUpdate.add(obj1);
        }
        
        update sObjectsToUpdate;
    } 
    
    
    
    // for feature 
    public class FeatureWrapperParams 
    {
        	public string 	   SalesforceRecordId;
       		public integer 	   Priority;
        	public string  	   TargetDate; 
            public string      ProjectType; 
            public string      ProjectSubType;
            public integer      Id; 
        	public integer      TfsId; 
            public string      Title;
            public string      State;
            public integer     BusinessValue ;          
            public string      Details;
            public string      AssignedTo;
            public string      Team;
            public string      Area;
        	
        
           public FeatureWrapperParams(string sfdcId, integer priority, string targetDate, string thisProjectType, string thisProjectSubType, integer recId, string projtitle, string status, integer rev, string description,
                                       string assignTo, string teamProject, string areaPath)
            {
                SalesforceRecordId = sfdcId;
                Priority		 = priority;
        	    TargetDate  	 = targetDate; 
                ProjectType 	 = thisProjectType; 
                ProjectSubType   = null;
                Id = recId;
                Title = projtitle;
                State = status;
                BusinessValue  = rev;              
                Details  = description;
                AssignedTo = assignedTo;
                Team = teamProject;
                Area = areaPath;
                TfsId = integer.valueOf(recId);
                
            }
    }
    
     // for WorkItems 
    public class WorkItemsWrapperParams
    {
       // public integer	 	Id; 
        public integer	 	TfsId;
        public string 		SalesforceRecordId;
        public DateTime 	TfsCreatedDate;
        public string 		AssignedTo;
        public integer 		Priority;
        public string 		Risk; 
        public integer 		PrivacyImpact; 
        public double 		StackRank; 
        public string 		State; 
        public string 		Description; 
        public string 		Title;
        public string 		WorkItemType; 
        public string 		Team; 
        public string 		ParentId;
        public string 		Area;
    }
    
    
    // For WorkItem COmments 
    public class CommentsWrapper
    {
        public integer	 	WorkItemId;
        public string 		CreatedBy;
        public string 		Comment;
        
        public CommentsWrapper(integer tfsId, string createdByName, string body)
        {
            WorkItemId = tfsId;
            CreatedBy = createdByName;
            Comment = body;
        }
        
    }
    
    // For WorkItem COmments 
    public class TagsWrapper
    {
        public integer	 	WorkItemId;
        public list<string> tags;
        
        public TagsWrapper(integer tfsId, list<string> topics)
        {
            WorkItemId = tfsId;
            tags = topics;
        }
        
    }
    
    
  // JSON Parser == If required in future
	@TestVisible  
    private static string parseJSonstringtoId (string responseBody)
    {
        string tfsId;
        
        System.JSONParser parser = JSON.createParser(responseBody);
        while(parser.nextToken() != null)
        {
            if(parser.getCurrentToken() == JSONToken.FIELD_NAME)
            {
                string fieldName = parser.getText();
                system.debug('fieldName  ==>' + fieldName);
                parser.nextToken();
                if(fieldName == 'Id')
                {
                    tfsId = parser.getText();
                    break;
                }
                    
            }
        }
        
        return tfsId;
    } 
}