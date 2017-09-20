/**
 * Created by william.nelson on 9/19/2017.
 */

public with sharing class CasCommentWrapper {
    Id ParentId {get;set;}
    Id caseCommentsId {get;set;}
    string CaseComment {get;set;}
    DateTime CreateDate {get;set;}
    string CreatedBy {get;set;}
    boolean isDeleted {get;set;}
    boolean isPublic {get;set;}


}