public class CorporateItTfsAccess
{
    public static void SyncTfsFeature(string featureId, integer tfsId)
    {
        CorporateItTfsService.CorpFeature tfsFeature = new CorporateItTfsService.CorpFeature();
        CorporateItTfsService.CorpServiceSoap featureService = TfsAuthentication();
        Feature__c feature = new Feature__c();
        List<FeatureComment__c> comments = new List<FeatureComment__c>();
        FeatureComment__c[] oldComments = new FeatureComment__c[]{};
        
        feature.TFSID__c = string.valueOf(tfsId);
        feature.Id = featureId;
        oldComments = [SELECT Id FROM FeatureComment__c WHERE Feature__c  = :featureId];
        
        try
        {
            tfsFeature = featureService.GetFeature(tfsId);
            
            feature.AssignedTo__c = tfsFeature.AssignedTo;
            feature.BusinessValue__c = tfsFeature.BusinessValue;
            feature.CreatedDateTFS__c = tfsFeature.TfsCreatedDate;
            feature.Details__c = tfsFeature.Details;
            feature.Priority__c = tfsFeature.Priority;
            feature.Risk__c = tfsFeature.Risk;
            feature.State__c = tfsFeature.State;
            feature.TargetDate__c = tfsFeature.TargetDate;
            feature.Title__c = tfsFeature.Title;
            
            if(string.isBlank(tfsFeature.SalesforceRecordId))
            {
            	
        		CorporateItTfsService.CorpFeature updateTfsFeature = new CorporateItTfsService.CorpFeature();
            	updateTfsFeature.SalesforceRecordId = featureId;
            	updateTfsFeature.TfsId = tfsId;
            	//updateTfsFeature = featureService.UpsertFeature(updateTfsFeature, UserInfo.getUserName() );
            }
            
            if(tfsFeature.Comments != null && tfsFeature.Comments.TfsWorkItemComment != null)
            {
	            for(CorporateItTfsService.TfsWorkItemComment tfsComment:tfsFeature.Comments.TfsWorkItemComment)
	            {
	                FeatureComment__c comment = new FeatureComment__c();
	                comment.Comment__c = tfsComment.Comment;
	                comment.CreatedByTfs__c = tfsComment.CreatedBy;
	                comment.CreatedDateTfs__c = tfsComment.CreatedDate;
	                comment.Feature__c = feature.Id;
	                
	                comments.add(comment);
	            }
            }
            
            update feature;
            
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
            inContactBaseClass.SendErrorEmail(ex,featureId);
        } 
    }
    
    @future(callout=true)
    public static void SyncTfsFeatureAsync(string featureId, integer tfsId)
    {
        SyncTfsFeature(featureId, tfsId);
    }
    
    
    
    public static void AddTfsComment(integer tfsId, string comment, string featureId)
    {
        CorporateItTfsService.CorpServiceSoap featureService = TfsAuthentication();
        boolean success;
        
        success = featureService.AddFeatureComment(tfsId,comment, UserInfo.getUserName());
        if(success)
        {
            SyncTfsFeature(featureId, tfsId);
        }
    }
    
    public static void CreateTfsFeature(string featureId)
    {
        
        List<FeatureComment__c> comments = new List<FeatureComment__c>();
        Feature__c feature = [SELECT Id,Title__c, Details__c, TFSID__C FROM Feature__c WHERE Id = :featureId];
        
        CorporateItTfsService.CorpFeature tfsFeature = new CorporateItTfsService.CorpFeature();
        tfsFeature.SalesforceRecordId = feature.Id;
        tfsFeature.Details = feature.Details__c;
		tfsFeature.Title = feature.Title__c;
        tfsFeature.State = 'New';
        tfsFeature.Priority = 2;
        
        
        CorporateItTfsService.CorpServiceSoap featureService = TfsAuthentication();
        
        try
        {
            tfsFeature = featureService.UpsertFeature(tfsFeature, UserInfo.getUserName() );
            
            feature.TFSID__c = string.valueOf(tfsFeature.TfsId);
            feature.AssignedTo__c = tfsFeature.AssignedTo;
            feature.State__c = tfsFeature.State;
            feature.Priority__c = tfsFeature.Priority;
            feature.CreatedDateTFS__c = tfsFeature.TfsCreatedDate;
            feature.Risk__c = tfsFeature.Risk;
            feature.TargetDate__c = tfsFeature.TargetDate;
            feature.BusinessValue__c = tfsFeature.BusinessValue;
            update feature;
            
            
            if(tfsFeature.Comments.TfsWorkItemComment != null)
            {
	            for(CorporateItTfsService.TfsWorkItemComment tfsComment:tfsFeature.Comments.TfsWorkItemComment)
	            {
	                FeatureComment__c comment = new FeatureComment__c();
	                comment.Comment__c = tfsComment.Comment;
	                comment.CreatedByTfs__c = tfsComment.CreatedBy;
	                comment.CreatedDateTfs__c = tfsComment.CreatedDate;
	                comment.Feature__c = feature.Id;
	                
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
            inContactBaseClass.SendErrorEmail(ex,featureId);
        }   
    }
    
    private static CorporateItTfsService.CorpServiceSoap TfsAuthentication()
    {
        CorporateItTfsService.AuthenticationHeader authHeader = new CorporateItTfsService.AuthenticationHeader();
        authHeader.Password = InContactConfiguration.CorpTfsPassword;
        authHeader.Username = InContactConfiguration.CorpTfsUserName;
        
        CorporateItTfsService.CorpServiceSoap bugs = new CorporateItTfsService.CorpServiceSoap();
        bugs.AuthenticationHeader = authHeader;
        bugs.timeout_x = 50000;
         
        return bugs;
    } 

}