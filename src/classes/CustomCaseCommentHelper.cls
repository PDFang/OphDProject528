/**
 * Created by william.nelson on 9/20/2017.
 */

public with sharing class CustomCaseCommentHelper {
    //get the aggregated view of comment data
    //get save/new action


    public list<CaseComment> GetCaseComments(Case currentCase){

        list<CaseComment> retlist = [SELECT CommentBody,CreatedDate,CreatorName,Id,IsDeleted,IsPublished,ParentId FROM CaseComment where parentId =:currentCase.id];
        return retlist;
    }

    public list<Case_Comment_Custom__c> GetCustomComments(Case currentCase){
        list<Case_Comment_Custom__c> retlist = [SELECT Case_Comments_Id__c,CommentBody__c,IsPublished__c ,CommentCreatedDate__c,ConnectionReceivedId,ConnectionSentId,CreatedById,CreatedDate,CreatorName__c,Id,IsDeleted FROM Case_Comment_Custom__c where parentId__c =:currentCase.id];
        return retlist;
    }

    public List<CustomCaseCommentData> GetAggregateData(Case currentCase){

        list<CustomCaseCommentData> finalList = new list<CustomCaseCommentData>();
        list<CaseComment> caseComments = GetCaseComments(currentCase);
        list<Case_Comment_Custom__c> privateComments;
        if (isPrivateInList(caseComments) == false){
            privateComments =    GetCustomComments(currentCase);
        }

        for (CaseComment c: casecomments)
        {
            finalList.add(GetCustomCommentData(c));
        }
        if (privateComments != null){
            for (Case_Comment_Custom__c c: privateComments)
            {
                finalList.add(GetCustomCommentData(c));
            }
        }
        return finalList;
    }

    public CustomCaseCommentData GetCustomCommentData(CaseComment comment){
        CustomCaseCommentData commentData = new CustomCaseCommentData();
        commentData.caseCommentsId = comment.id;
        commentData.CreatedBy = comment.CreatorName;
        commentData.CaseComment = comment.CommentBody;
        commentData.CreateDate = comment.CreatedDate;
        commentData.isPublic = comment.IsPublished;
        commentData.ParentId = comment.ParentId;
        return commentData;

    }
    public CustomCaseCommentData GetCustomCommentData( Case_Comment_Custom__c comment){
        CustomCaseCommentData commentData = new CustomCaseCommentData();
        commentData.caseCommentsId = comment.Case_Comments_Id__c;
        commentData.CreatedBy = comment.CreatorName__c;
        commentData.CaseComment = comment.CommentBody__c;
        commentData.CreateDate = comment.CommentCreatedDate__c;
        commentData.isPublic = comment.IsPublished__c;
        return commentData;
    }

    public boolean isPrivateInList(list<CaseComment> caseComments){
        for (CaseComment c: caseCOmments){
            if(c.IsPublished == false){
                return true;
            }
        }
        return false;
    }

}

