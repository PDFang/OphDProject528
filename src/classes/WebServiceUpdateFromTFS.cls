@RestResource(urlmapping='/UpdateTFSItems/*')
global class WebServiceUpdateFromTFS
{
	@HTTPPOST
   global static void UpdateTFSItems(list<WorkItemsWrapperParams> WorkItemLists)
    {
        list<SObject> lstSObjects = new list<SObject>();
        list<SObject> insertCommentLists = new list<SObject>();
        map<string, list<string>> mpTagAssigned = new  map<string, list<string>>();
        // Make sure the trigger dont fire off the sync to TFS again.
        ISTFSINTEGRATIONCLASS.isWebserviceCall = true;    
        map<string, string> mapAssignToId = new map<string, string>();
        map<string, list<string>> mapAssignToName = new map<string, list<string>>();
        try
        {
            for(WorkItemsWrapperParams workItems : WorkItemLists)
            {
                
                if(workItems.AssignedTo != null && workItems.AssignedTo != '')
                {
                    if(mapAssignToName.containsKey(workItems.AssignedTo))
                        mapAssignToName.get(workItems.AssignedTo).add(workItems.SalesforceRecordId);
                    else
                        mapAssignToName.put(workItems.AssignedTo, new list<string>{workItems.SalesforceRecordId});
                }
            }
            
            for(User u : [select Id, Name from User where Name in : mapAssignToName.keySet()])
            {
                for(string salesforceId : mapAssignToName.get(u.Name))
                {
                    mapAssignToId.put(salesforceId, u.Id);
                }
            }
            
			for(WorkItemsWrapperParams workItems : WorkItemLists)
            {
                system.debug('workItems == > ' + workItems.SalesforceRecordId);
                if(workItems.SalesforceRecordId != null && workItems.SalesforceRecordId != '')
                {
                    Id sObjId =(Id)workItems.SalesforceRecordId;
                    SObject obj = sObjId.getSObjectType().newSObject(workItems.SalesforceRecordId);
                    if(mapAssignToId.size() > 0)
                      obj.put('AssignedTo__c', mapAssignToId.get(workItems.SalesforceRecordId));
                    
                   
                    if (obj.getSObjectType() == Schema.Project__c.getSObjectType())
                    {
                        obj.put('ProjectTFSStatus__c', workItems.State);
                        obj.put('ProblemStatement__c', workItems.Description);
                        obj.put('Summary__c', workItems.Title);
                    }
                    else
                    {
                        obj.put('WorkItemTFSState__c', workItems.State);
                        obj.put('Details__c', workItems.Description);
                        obj.put('Title__c', workItems.Title);
                        obj.put('StackRank__c', workItems.StackRank);                        
                        obj.put('StoryPoints__c', workItems.StoryPoints == ''? '0' : workItems.StoryPoints);
                        
                     }
                    
                    obj.put('Team__c', workItems.Team);
					obj.put('Priority__c', workItems.Priority);                    
                    obj.put('Iteration__c', workItems.Iteration);
                    
                    if(workItems.Comment != '')
                    {
                        SObject comment;
                        Schema.SObjectType objType = sObjId.getSobjectType();
                        if(objType == Schema.Project__c.getSObjectType())
                        {
                            comment =  Schema.getGlobalDescribe().get('ProjectComment__c').newSObject() ;
                     		comment.put('Project__c', workItems.SalesforceRecordId);                            
                        }
                        else 
                        {
                            comment =  Schema.getGlobalDescribe().get('ISTFSWorkItemComment__c').newSObject() ;
                            comment.put('ParentId__c', workItems.SalesforceRecordId);  
                            
                        }
                        
                        comment.put('Comment__c', workItems.Comment);
                        
                        insertCommentLists.add(comment);
                        
                    }
                    
                    if(workItems.Tags != null)
                    {
                     	   
                           mpTagAssigned.put(workItems.SalesforceRecordId, workItems.Tags);
                    }
                    
                    
                    lstSObjects.add(obj);
                }   
                
                
            }
        
        
       	 if(lstSObjects.size() > 0)
            update lstSObjects;
         
         if(insertCommentLists.size() > 0)
             insert insertCommentLists;
            
            if(mpTagAssigned.size() > 0)
                	assignTags(mpTagAssigned);
			             
        }  
        catch(Exception e)
        {
            string error ='Other error: at line '+ e.getLineNumber() + ' with ' + e.getMessage(); 
            System.debug(error); 
            doSendEmail(error);
            
        }
        
    }
    
    
 	private static void doSendEmail(string emailBody)
    {   
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'arnab.karsarkar@incontact.com', 'william.nelson@incontact.com', 'swetha.sankaramanchi@incontact.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('There is an unexpected error occured');
        mail.setHtmlBody(emailBody);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	
 	}
    
    
    private static void assignTags(map<string, list<string>> mpTagAssignments)
    {
     	if(mpTagAssignments == null)
            return;
        
        set<string> entityIds = new set<string>();
        list<TopicAssignment> deleteTopics = new list<TopicAssignment>();
        list<Topic> insertTopics = new list<topic>();
        set<id> newTopics = new set<id>();
        list<TopicAssignment> lstTopicAssignments = new list<TopicAssignment>();
        set<string> topicNames = new set<string>();
        
        
        for(String entityId : mpTagAssignments.keySet())
        {
            entityIds.add(entityId);
            for(string topicName : mpTagAssignments.get(entityId))
            {
                topicNames.add(topicName.toUpperCase());
                Topic t = new Topic();
                t.Name = topicName;
                t.Description = topicName;
                insertTopics.add(t);
            }
        }
        
        system.debug('topicNames ==>' + topicNames);
        
        for(TopicAssignment tA :[select TopicId, Topic.Name From TopicAssignment where EntityId in :entityIds] )
        {
              string topicNameIgnoreCase = tA.Topic.Name.toUpperCase();
              if(!topicNames.contains(topicNameIgnoreCase))
                {
                    deleteTopics.add(tA);
                }
        }
        
        list<Topic> tempTopic = insertTopics;
        for(Topic deleteTopic : [Select Id, Name from Topic where Name in :topicNames])
        { 
            integer i = 0;
           for(Topic t : tempTopic)
           {
               if(t.Name == deleteTopic.Name)
               {
                   newTopics.add(deleteTopic.Id);
                   insertTopics.remove(i);
                   break;
               }
               i++;
                   
           }
        }
        
        system.debug('insertTopics ==>' + insertTopics);
        system.debug('deleteTopics ==>' + deleteTopics);
        
        
    
    	if(deleteTopics.size() > 0)
     		delete deleteTopics;
        
        Database.SaveResult[] srList = Database.insert(insertTopics, false);
        for(Database.SaveResult sr : srList)
        {
            if(sr.isSuccess())
            {
                newTopics.add(sr.getId());   
            }
        }
        
     
           for(Topic newTopic : [Select Id, Name from Topic where Id in :newTopics])
           {
             for(String entityId : mpTagAssignments.keySet())
             {
           		for(string topicName : mpTagAssignments.get(entityId))
                {
                  if(topicName == newTopic.Name)
                  {
                      TopicAssignment ta = new TopicAssignment();
                      ta.TopicId = newTopic.Id;
                      ta.EntityId = entityId;
                      lstTopicAssignments.add(ta);
                  }
                }
              }
            }
       
        
        system.debug('lstTopicAssignments ==> ' + lstTopicAssignments);
        
        if(lstTopicAssignments.size() > 0)
            insert lstTopicAssignments;
        
   
        
        
    }
    
    
    
    
    global class WorkItemsWrapperParams
    {
        public string 		SalesforceRecordId;
        public string 		AssignedTo;
        public double 		StackRank; 
        public string 		State; 
        public string 		Description; 
        public string 		Title;      
        public string 		Team; 
        public string 		Priority;
 		public string 		Iteration;
        public string 		StoryPoints;
        public string 		Comment;
        public list<string>	Tags; 		
    }
    
}