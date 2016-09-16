public with sharing class ProjectCommentViewerExtension 
{
    private final Project__c project;
    public List<ProjectComment__c> comments{public get;private set;}

    public ProjectCommentViewerExtension(ApexPages.StandardController controller) 
    {
        this.project = (Project__c)controller.getRecord();
        comments = [SELECT Name, Comment__c, CreatedById, CreatedDate, LastModifiedDate, LastModifiedById FROM ProjectComment__c WHERE Project__c = :project.Id ORDER BY CreatedDate DESC LIMIT 1000];
    }
    

}