public without sharing class Ca_Case_Incident_Sync
{
    //A transaction-scoped set of trigger names.
    //Triggers that should not repeat should call "hasTriggerName([triggerName]) to see
    //if it has already executed.  If "true," then exit the trigger.
    private static Set<String> mtriggerNames = new Set<String>();
    
    public static boolean hasTriggerName(String triggerName)
    {
        if(mtriggerNames.contains(triggerName))
        {
            return true;
        }
        else
        {
            mtriggerNames.add(triggerName);
            return false;
        }
    }
    //This is to make sure the integration is not run multiple times in a single transaction.
    //This prevents echoing between 2 linked objects (Case -> Incident -> Case -> Incident, for example)
    private static boolean run = true;
    public static boolean runOnce()
    {
        if(run)
        {
            run=false;
            return true;
        }
        else
        {
            return run;
        }
    }
    
    //Send Case Comments to Incident History.  
    //Salesforce doesn't recognize "Case Comments" as a base object, so actionHub can't use it.
    public static void CaseComment_executeTrigger(List<CaseComment> newTriggerComments)
    {
        String sMessage = '****** CaseComment_executeTrigger';
        try
        {
            List<CaseComment> newComments = [select Id, Parent.Related_Incident__c, CreatedById, CreatedBy.UserName,
                                             CommentBody from CaseComment where Id in : newTriggerComments];
            //Get the Id for the Case Comment action
            List<BMCServiceDesk__Action__c> actions = [select Id from BMCServiceDesk__Action__c where Name = 'Case Comment'];
            if(actions.size() == 0)
            {
                sMessage += '\n No "Case Comment" action Id.  Exiting.';
                return;
            }
            Id actionId = actions[0].Id;
            sMessage += '\n "Case Comment" Action Id = ' + actionId;
            List<BMCServiceDesk__IncidentHistory__c> incHists = new List<BMCServiceDesk__IncidentHistory__c>();
            for(CaseComment comm : newComments)
            {
                //if(comm.Parent.Related_Incident__c != null)
                //EOLSON 040815 INC Issue 74: Added condition to omit Case Comments containing the string '<RF>'.
                if(comm.Parent.Related_Incident__c != null && comm.CommentBody.indexOf('<RF>') == -1) {sMessage += '\n Creating a new incident history.'; 
                    BMCServiceDesk__IncidentHistory__c incHist = new BMCServiceDesk__IncidentHistory__c(); 
                    sMessage += '\n Comment body = ' + comm.CommentBody; 
                    incHist.BMCServiceDesk__note__c = comm.CommentBody;
                    sMessage += '\n  Linking to parent Incident with Id = "' + comm.Parent.Related_Incident__c + '"'; 
                    incHist.BMCServiceDesk__FKIncident__c = comm.Parent.Related_Incident__c; 
                    sMessage += '\n Setting action on incident history.'; 
                    incHist.BMCServiceDesk__FKAction__c = actionId; incHists.add(incHist);
                   
                    //---Casecomment Id appends
                     incHist.CaseComment_Id__c = comm.Id;
                    //
                    
                }else{
                    sMessage += '\n Case not linked to an incident.'; 
                }
            }
            if(incHists.size() > 0){ insert incHists;}}catch(Exception ex){ sMessage += '\n Error: ' + ex.getmessage(); }
        
            System.debug(sMessage);
    }

    //Synchronizes attachments between cases and incidents.
    public static void executeTrigger(List<Attachment> newAttachmentsArg)
    {
        
        if (Ca_Case_Incident_Sync.hasTriggerName('AlreadyHandledAttachments')) 
        {
            return ;
        }
        
        //Each method checks all attachments to see if the parent object is a Case or Incident
        handleIncidentAttachments(newAttachmentsArg);  
        handleCaseAttachments(newAttachmentsArg);
            
    }

    //
    public static void handleIncidentAttachments(List<Attachment> newAttachmentsArg)
    {
        String sMessage = '*********** Ca_Attachments_Case_Inc_Sync - Incident to Case';
    
        //Get the base list of ids for all attachments in this transaction.
        List<Id> attachIds = new List<Id>();
        for(Attachment attach : newAttachmentsArg)
        {
            attachIds.add(attach.Id);
        }
        sMessage += '\n Working with ' + attachIds.size() + ' attachments.';
        //Get the attachments that are attached to Cases that havve child Incidents.
        String sAttachIds = '';
        for(Id attachId : attachIds)
        {
            if(sAttachIds != '')
                sAttachIds += ', ';
            sAttachIds += String.valueOf(attachId);
        }
        
        //Get just the affected attachments that are linked to Incidents
        sMessage += '\n Attachment SQOL = \n select Id, Body, Name, ParentId from Attachment where id in (\'' + sAttachIds + '\') and ParentId in (select Source_Case__c from BMCServiceDesk__Incident__c)';
        List<Attachment> attaches = [select Id, Body, Name, ParentId from Attachment where id in : attachIds and ParentId in (select Id from BMCServiceDesk__Incident__c where  Source_Case__c <> null )];
        sMessage += '\n Fetched ' + attaches.size() + ' in this batch that are attached to a Case that has a child Incident.';
        
        
        //Group the attachments by Incident id.  This will only need one loop to get to the Case Ids.
        Map<Id, List<Attachment>> attachmentByIncidentId = new Map<Id, List<Attachment>>();
        
        for(Attachment attach : attaches){List<Attachment> attachGroup;if(attachmentByIncidentId.containsKey(attach.ParentId)) {attachGroup = attachmentByIncidentId.get(attach.ParentId);}else{attachGroup = new List<Attachment>();attachmentByIncidentId.put(attach.ParentId, attachGroup);}attachGroup.add(attach);}
        
        List<Attachment> newAttachments = new List<Attachment>();
        //Get the names of all attachments linked to the parent cases
        //Only create new attachments with names that aren't already attached to the cases
        
        //Get the parent Incidents
        List<BMCServiceDesk__Incident__c> incs = [select Id, Source_Case__c from BMCServiceDesk__Incident__c where Id in : attachmentByIncidentId.keySet()];
                
        List<Id> caseIds = new List<Id>();
        for(BMCServiceDesk__Incident__c inc : incs)
        {
            if(inc.Source_Case__c != null)
            {
                caseIds.add(inc.Source_Case__c);
            }
        }
        
        Map<Id, Set<String>> existingAttachmentNamesbyCaseId = new Map<Id, Set<String>>();
        List<Attachment> existingAttachments = [select Id, Name, ParentId from attachment where ParentId in : caseIds];
        
        for(Attachment attach : existingAttachments) { Set<String> attachList = existingAttachmentNamesbyCaseId.get(attach.parentid); if(attachList == null) {attachList = new Set<String>();existingAttachmentNamesbyCaseId.put(attach.parentid, attachList);} attachList.add(attach.Name);}
        
        for(BMCServiceDesk__Incident__c inc : incs) { List<Attachment> attachments = attachmentByIncidentId.get(inc.Id); for(Attachment attach : attachments) { Boolean bAddAttachment = true; if(existingAttachmentNamesbyCaseId.containsKey(inc.Source_Case__c)) { if(existingAttachmentNamesbyCaseId.get(inc.Source_Case__c).contains(attach.Name)) { bAddAttachment = false; } } if(bAddAttachment) { Attachment newAttach = new Attachment(Name = attach.Name, body = attach.Body, ParentId = inc.Source_Case__c); newAttachments.add(newAttach); } }    }
        
        sMessage += '\n Inserting attachments for Cases: ' + newAttachments.size() + ' attachments.';
        insert newAttachments;
        
        System.debug(sMessage);
    }
    
    
    public static void handleCaseAttachments(List<Attachment> newAttachmentsArg)
    {
    
        String sMessage = '*********** Ca_Attachments_Case_Inc_Sync - Case to Incident';
    
        //Get the base list of ids for all attachments in this transaction.
        List<Id> attachIds = new List<Id>();
        for(Attachment attach : newAttachmentsArg)
        {
            attachIds.add(attach.Id);
        }
        sMessage += '\n Working with ' + attachIds.size() + ' attachments.';
        //Get the attachments that are attached to Cases that havve child Incidents.
        String sAttachIds = '';
        for(Id attachId : attachIds)
        {
            if(sAttachIds != '')
                sAttachIds += ', ';
            sAttachIds += String.valueOf(attachId);
        }
        
        sMessage += '\n Attachment SQOL = \n select Id, Body, Name, ParentId from Attachment where id in (\'' + sAttachIds + '\') and ParentId in (select Source_Case__c from BMCServiceDesk__Incident__c)';
        List<Attachment> attaches = [select Id, Body, Name, ParentId from Attachment where id in : attachIds and ParentId in (select Source_Case__c from BMCServiceDesk__Incident__c)];
        sMessage += '\n Fetched ' + attaches.size() + ' in this batch that are attached to a Case that has a child Incident.';
        //Put the attachments and incidents into parallel maps, keyed by Case.Id
        Map<Id, List<Attachment>> attachmentByCaseId = new Map<Id, List<Attachment>>();
        
        Set<Id> caseIds = new Set<Id>();
        for(Attachment attach : attaches) { List<Attachment> caseAttaches; if(attachmentByCaseId.containsKey(attach.ParentId)) { caseAttaches = attachmentByCaseId.get(attach.ParentId); } else { caseAttaches = new List<Attachment>(); attachmentByCaseId.put(attach.ParentId, caseAttaches); } caseAttaches.add(attach); caseIds.add(attach.parentId); }
        
        sMessage += '\n Created ' + attachmentByCaseId.size() + ' case Attachment groups.';
        
        List<BMCServiceDesk__Incident__c> incs = [select Id, Source_Case__c from BMCServiceDesk__Incident__c where Source_Case__c in : caseIds];
        
        
        Map<Id, List<BMCServiceDesk__Incident__c>> incidentByCaseId = new Map<Id, List<BMCServiceDesk__Incident__c>>();
        for(BMCServiceDesk__Incident__c inc : incs) { List<BMCServiceDesk__Incident__c> caseIncs = incidentByCaseId.get(inc.Source_Case__c); if(caseIncs == null){caseIncs = new List<BMCServiceDesk__Incident__c>(); incidentByCaseId.put(inc.Source_Case__c, caseIncs); } caseIncs.add(inc); }
        sMessage += '\n Created ' + incidentByCaseId.size() + ' case Incident groups.';
        
        List<Attachment> newAttachments = new List<Attachment>();
        for(Attachment attach : attaches)
        {
            List<BMCServiceDesk__Incident__c> caseIncs = incidentByCaseId.get(attach.ParentId);
            for(BMCServiceDesk__Incident__c inc : caseIncs) { Attachment newAttach = new Attachment(Name = attach.Name, body = attach.Body, ParentId = inc.Id); newAttachments.add(newAttach); }
        }
        sMessage += '\n insert ' + newAttachments.size() + ' attachments.';
        sMessage += '\n Inserting attachments for Incidents: ' + newAttachments.size() + ' attachments.';
        insert newAttachments;
        
        System.debug(sMessage);
    }

}