public class TfsAccess 
{
    public static String[] TfsReleaseValues()
    {
        String[] releaseValues = new String[]{}; 
        tfsIntegration.RndServiceSoap listClass = new tfsIntegration.RndServiceSoap();
        tfsIntegration.ArrayOfString returnValue = new tfsIntegration.ArrayOfString();
        
        tfsIntegration.AuthenticationHeader authHeader = new tfsIntegration.AuthenticationHeader();
        authHeader.Password = InContactConfiguration.BugPassword;
        authHeader.Username = InContactConfiguration.BugUserName; 
        
        listClass.AuthenticationHeader = authHeader;
        listClass.timeout_x = 50000;
        returnValue = listClass.GetInContactReleases();
        //system.debug(returnValue);
        
        releaseValues = returnValue.string_x;
        
        return releaseValues;
    }
    
    public static void SyncTfsWorkItem(string workItemId, integer tfsId)
    {
        tfsIntegration.TfsWorkItem tfsWorkItem = new tfsIntegration.TfsWorkItem();
        tfsIntegration.RndServiceSoap bugs = TfsAuthentication();
        TfsWorkItem__c workItem = new TfsWorkItem__c();
        List<TfsWorkItemComment__c> comments = new List<TfsWorkItemComment__c>();
        TfsWorkItemComment__c[] oldComments = new TfsWorkItemComment__c[]{};
        
        workItem.TFSExternalID__c = tfsId;
        workItem.Id = workItemId;
        oldComments = [SELECT Id FROM TfsWorkItemComment__c WHERE TfsWorkItemId__c = :workItemId];
        
        try
        {
            tfsWorkItem = bugs.GetInContactBug(tfsId );
            
            workItem.AssignedTo__c = tfsWorkItem.AssignedTo;
            workItem.CreatedDateTFS__c = tfsWorkItem.TfsCreatedDate;
            workItem.ExistsIn__c = tfsWorkItem.ExistsIn;
            workItem.FoundBy__c = tfsWorkItem.FoundBy;
            workItem.Priority__c = tfsWorkItem.Priority;
            workItem.Release__c = tfsWorkItem.Release;
            workItem.ResolvedReason__c = tfsWorkItem.ResolvedReason;
            workItem.StackRank__c = tfsWorkItem.StackRank;
            workItem.State__c = tfsWorkItem.State;
            workItem.StepsToRecreate__c = tfsWorkItem.StepsToReproduce;
            workItem.Title__c = tfsWorkItem.Title;
            workItem.WorkItemType__c = tfsWorkItem.WorkItemType;
            workItem.NeedMoreInfo__c = tfsWorkItem.NeedMoreInfo;
            workItem.DeveloperNeeded__c = tfsWorkItem.DeveloperNeeded;
            workItem.UptivityState__c = tfsWorkItem.UptivityState;
            workItem.CompletedWork__c = tfsWorkItem.CompletedWork;
            workItem.Team__c = tfsWorkItem.Team;
            
            if(string.isBlank(tfsWorkItem.SalesforceRecordId))
            {
            	
        		tfsIntegration.TfsWorkItem updateTfsWorkItem = new tfsIntegration.TfsWorkItem();
            	updateTfsWorkItem.SalesforceRecordId = workItemId;
            	updateTfsWorkItem.TfsId = tfsId;
            	updateTfsWorkItem = bugs.UpsertInContactBug(updateTfsWorkItem, UserInfo.getUserName() );
            }
            
            if(tfsWorkItem.Comments.TfsWorkItemComment != null)
            {
	            for(tfsIntegration.TfsWorkItemComment tfsComment:tfsWorkItem.Comments.TfsWorkItemComment)
	            {
	                TfsWorkItemComment__c comment = new TfsWorkItemComment__c();
	                comment.CommentRichText__c = tfsComment.Comment;
	                comment.CreatedByTfs__c = tfsComment.CreatedBy;
	                comment.CreatedDateTfs__c = tfsComment.CreatedDate;
	                comment.TfsWorkItemId__c = workItem.Id;
	                
	                comments.add(comment);
	            }
            }
            
            update workItem;
            
            //delete old comments
            if(!oldComments.isEmpty())
            {
                delete oldComments;   
            }
            
            if(!comments.isEmpty())
            {
                insert comments;   
            }
        }
        catch(Exception ex)
        {
            inContactBaseClass.SendErrorEmail(ex,workItemId);
        } 
    }
    
    @future(callout=true)
    public static void SyncTfsWorkItemAsync(string workItemId, integer tfsId)
    {
        SyncTfsWorkItem(workItemId, tfsId);
    }
    
    @future(callout=true)
    public static void CreateTfsItem(string workItemId, string description, string internalNotes, string stepsToRecreate, string team)
    {
        string stepsToReproduce =  '<p><b>Summary</b></p>------------------<br/>' + description + '<br/><br/><p><b>Steps to Recreate</b></p>------------------<br/>' + stepsToRecreate + '<br/><br/><p><b>Internal Notes</b></p>------------------<br/>' + internalNotes;
       	CreateTfsItem(workItemId, stepsToReproduce, team);
    }
    
    public static void CreateTfsItem(string workItemId, string stepsToRecreate, string team)
    {
        List<TfsWorkItemComment__c> comments = new List<TfsWorkItemComment__c>();
        TfsWorkItem__c workItem = [SELECT Id, Description__c, ExistsIn__c, FoundBy__c, StepsToRecreate__c, Title__c, Name, TfsExternalId__c, Team__c FROM TFSWorkItem__c WHERE Id = :workItemId];
        
        tfsIntegration.TfsWorkItem tfsWorkItem = new tfsIntegration.TfsWorkItem();
        tfsWorkItem.SalesforceRecordId = workItem.Id;
        tfsWorkItem.ExistsIn = workItem.ExistsIn__c;
        tfsWorkItem.FoundBy = workItem.FoundBy__c;
        tfsWorkItem.StepsToReproduce =  stepsToRecreate;
        tfsWorkItem.Title = workItem.Title__c;
        tfsWorkItem.Team = team;
        
        
        tfsIntegration.RndServiceSoap bugs = TfsAuthentication();
        
        try
        {
            tfsWorkItem = bugs.UpsertInContactBug(tfsWorkItem, UserInfo.getUserName() );
            
            workItem.Name = string.valueOf(tfsWorkItem.TfsId);
            workItem.TFSExternalID__c = tfsWorkItem.TfsId;
            workItem.AssignedTo__c = tfsWorkItem.AssignedTo;
            workItem.State__c = tfsWorkItem.State;
            workItem.Priority__c = tfsWorkItem.Priority;
            workItem.CreatedDateTFS__c = tfsWorkItem.TfsCreatedDate;
            workItem.WorkItemType__c = tfsWorkItem.WorkItemType;
            workItem.StepsToRecreate__c = tfsWorkItem.StepsToReproduce;
            update workItem;
            
            
            if(tfsWorkItem.Comments.TfsWorkItemComment != null)
            {
                for(tfsIntegration.TfsWorkItemComment tfsComment:tfsWorkItem.Comments.TfsWorkItemComment)
                {
                    TfsWorkItemComment__c comment = new TfsWorkItemComment__c();
                    comment.CommentRichText__c = tfsComment.Comment;
                    comment.CreatedByTfs__c = tfsComment.CreatedBy;
                    comment.CreatedDateTfs__c = tfsComment.CreatedDate;
                    comment.TfsWorkItemId__c = workItem.Id;
                    
                    comments.add(comment);
                }
            }
            
            
            if(!comments.isEmpty())
            {
                insert comments;   
            }
        }   
        catch(Exception ex)
        {
            
        }
    }
    
    @future(callout=true)
    public static void TfsUpdateBugAsync(string workItemId)
    {
        TfsWorkItem__c workItem = [SELECT StackRank__c, Title__c, TfsExternalId__c, StepsToRecreate__c, ExistsIn__c, FoundBy__c FROM TfsWorkItem__c WHERE Id = :workItemId];
        
        tfsIntegration.TfsWorkItem tfsWorkItem = new tfsIntegration.TfsWorkItem();
        tfsWorkItem.TfsId = integer.valueOf(workItem.TfsExternalId__c);
        tfsWorkItem.StackRank = workItem.StackRank__c;
        tfsWorkItem.SalesforceRecordId = workItemId;
        tfsWorkItem.StepsToReproduce = workItem.StepsToRecreate__c;
        tfsWorkItem.Title = workItem.Title__c;
        tfsWorkItem.ExistsIn = workItem.ExistsIn__c;
        tfsWorkItem.FoundBy = workItem.FoundBy__c;
        
        tfsIntegration.RndServiceSoap bugs = TfsAuthentication();
        
        try
        {
            tfsWorkItem = bugs.UpsertInContactBug(tfsWorkItem, UserInfo.getUserName() );
        }
        catch(Exception ex)
        {
            inContactBaseClass.SendErrorEmail(ex, workItemId );
        }
    }
    
    public static void AddTfsComment(integer tfsId, string comment, string workItemId)
    {
        tfsIntegration.RndServiceSoap bugs = TfsAuthentication();
        boolean success;
        
        success = bugs.AddInContactBugComment(tfsId, comment, UserInfo.getUserName() );
        if(success)
        {
            SyncTfsWorkItem(workItemId, tfsId);
        }
    }
    
    private static tfsIntegration.RndServiceSoap TfsAuthentication()
    {
        tfsIntegration.AuthenticationHeader authHeader = new tfsIntegration.AuthenticationHeader();
        authHeader.Password = InContactConfiguration.BugPassword;
        authHeader.Username = InContactConfiguration.BugUserName;
        
        tfsIntegration.RndServiceSoap bugs = new tfsIntegration.RndServiceSoap();
        bugs.AuthenticationHeader = authHeader;
        bugs.timeout_x = 50000;
        
        return bugs;
    }
}