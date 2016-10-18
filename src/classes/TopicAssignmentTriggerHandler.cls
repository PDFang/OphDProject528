public class TopicAssignmentTriggerHandler extends TriggerHandler {
  
    public override void afterInsert()
    {
        
       CallTFSService(Trigger.New);
    }
    
    public override void afterDelete()
    {
       		CallTFSService(Trigger.Old);
    }
    
    // call the service
   private static void CallTFSService(list<TopicAssignment> lstTags)
    {
      set<string> sObjectIds = new set<string>();
       for(TopicAssignment wi : lstTags)
       {
       		sObjectIds.add(wi.EntityId);                                                                                                                 
       }
        
       if(sObjectIds.size() > 0)
       {
         if (!ISTFSINTEGRATIONCLASS.isWebServiceCall)
           	ISTFSINTEGRATIONCLASS.CallTFSFutureMethod(sObjectIds, 'Topic');
       }
    }	 
    

}