public with sharing class CaseEventLogExtension 
{
    private final Case c;
    public CaseComment[] comments{public get;private set;}
     
    public CaseEventLogExtension(ApexPages.StandardController controller) 
    {
        this.c = (Case)controller.getRecord();
        comments = [SELECT CommentBody, IsPublished, CreatedDate, CreatedBy.Name FROM CaseComment WHERE ParentId = :c.ParentId ORDER BY CreatedDate DESC];
    }

}