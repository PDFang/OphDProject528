/**
 * Created by william.nelson on 9/19/2017.
 */

public with sharing class CustomCaseCommentData {
    public  Id ParentId {get;set;}
    public Id caseCommentsId {get;set;}
    public string CaseComment {get;set;}
    public DateTime CreateDate {get;set;}
    public string CreatedBy {get;set;}
    public boolean isDeleted {get;set;}
    public boolean isPublic {get;set;}


}