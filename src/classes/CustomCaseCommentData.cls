/**
 * Created by william.nelson on 9/19/2017.
 */

public with sharing class CustomCaseCommentData implements Comparable {
    public  Id ParentId {get;set;}
    public Id caseCommentsId {get;set;}
    public string CaseComment {get;set;}
    public DateTime CreateDate {get;set;}
    public string CreatedBy {get;set;}
    public boolean isDeleted {get;set;}
    public boolean isPublic {get;set;}

    public Integer compareTo(Object compareTo) {
        // needs bus logic to decide if null date is < non null date or vice-versa
        CustomCaseCommentData ctA = (CustomCaseCommentData) compareTo;
        if (ctA.CreateDate < this.CreateDate) return -1;
        if (ctA.CreateDate > this.CreateDate) return +1;
        return 0;
    }

}