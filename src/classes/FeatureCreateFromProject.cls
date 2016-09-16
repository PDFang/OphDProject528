public class FeatureCreateFromProject 
{
    private final Project__c project;
    public Feature__c feature{get;set;}

    public FeatureCreateFromProject(ApexPages.StandardController controller) 
    {
        this.project = (Project__c)controller.getRecord();
        SetUpNewFeature();
    }
    
    public void SetUpNewFeature()
    {
        feature = new Feature__c();
        feature.Title__c = project.Name + ' - ' + project.Summary__c;
        feature.Details__c = project.ProblemStatement__c;
    }
    
    public boolean HasFeature
    {
        get
        {
            return project.Feature__c != null;
        }
    }
    
    @RemoteAction
    public static String InsertNewFeature(string title, string details, string projectId)
    {
        Feature__c feature = new Feature__c();
        feature.Title__c = title;
        feature.Details__c = details;
        
        insert feature;
        
        Project__c project = new Project__c(Id = projectId);
        project.Feature__c = feature.Id;
        update project;
        
        return feature.Id;
    }
    
    @RemoteAction
    public static void InsertTfsFeature(string featureId)
    {
        CorporateItTfsAccess.CreateTfsFeature(featureId);
    }
    
    
    
    

}