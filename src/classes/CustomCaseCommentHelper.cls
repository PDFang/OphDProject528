/**
 * Created by william.nelson on 9/20/2017.
 */

public with sharing class CustomCaseCommentHelper {
    //This class provides aggregated views of the comment data
    //Get public comments
    public list<CaseComment> GetCaseComments(Case currentCase){
        system.debug( 'currentCase.ClosedDate ==>' +  currentCase.ClosedDate);

        list<CaseComment> retlist = new list<CaseComment>();
        if (DisplayComments(currentCase.ClosedDate) == true){
            retlist = [SELECT CommentBody,CreatedDate,CreatedBy.UserName,CreatorName,Id,IsDeleted,IsPublished,ParentId FROM CaseComment where parentId =:currentCase.id and IsPublished = true order by CreatedDate desc];
        }
        return retlist;
    }

    //Get private comments
    public list<Case_Comment_Custom__c> GetCustomComments(Case currentCase){
        system.debug( 'currentCase.ClosedDate ==>' +  currentCase.ClosedDate);
        list<Case_Comment_Custom__c> retlist = new List<Case_Comment_Custom__c>();
        if (DisplayComments(currentCase.ClosedDate) == true){
            retlist = [SELECT Case_Comments_Id__c,CommentBody__c,IsPublished__c ,CommentCreatedDate__c,ConnectionReceivedId,ConnectionSentId,CreatedById,CreatedDate,CreatorName__c,Id,IsDeleted FROM Case_Comment_Custom__c where IsPublished__c = false and parentId__c =:currentCase.id order by commentCreatedDate__c desc];
        }
        return retlist;
    }

    public List<CustomCaseCommentData> GetAggregateData(Case currentCase){

        //get list of private and public comments and convert to shared model
        list<CustomCaseCommentData> finalList = new list<CustomCaseCommentData>();
        list<CaseComment> caseComments = GetCaseComments(currentCase);
        list<Case_Comment_Custom__c> privateComments;
        //if (isPrivateInList(caseComments) == false){
        privateComments =    GetCustomComments(currentCase);
        //}

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
        finalList.Sort();
        return finalList;
    }

    public boolean isPrivateInList(list<CaseComment> caseComments){
        for (CaseComment c: caseCOmments){
            if(c.IsPublished == false){
                return true;
            }
        }
        return false;
    }

    //persist new comment
    public void SaveComment(CustomCaseCommentData Upsertcomment){
        Case_Comment_Custom__c comment = GetDbCustomData(Upsertcomment);
        insert(comment);
    }

    //converters
    private CustomCaseCommentData GetCustomCommentData(CaseComment comment){
        CustomCaseCommentData commentData = new CustomCaseCommentData();
        commentData.caseCommentsId = comment.id;
        commentData.CreatedBy = comment.CreatorName;  // this is alway null
        commentData.CreatedBy = comment.CreatedBy.Username;  // this is alway null
        commentData.CaseComment = comment.CommentBody;
        commentData.CreateDate = comment.CreatedDate;
        commentData.isPublic = comment.IsPublished;
        commentData.ParentId = comment.ParentId;
        return commentData;

    }
    private CustomCaseCommentData GetCustomCommentData(Case_Comment_Custom__c comment){
        CustomCaseCommentData commentData = new CustomCaseCommentData();
        commentData.caseCommentsId = comment.Case_Comments_Id__c;
        commentData.CreatedBy = comment.CreatorName__c;
        commentData.CaseComment = comment.CommentBody__c;
        commentData.CreateDate = comment.CommentCreatedDate__c;
        commentData.isPublic = comment.IsPublished__c;
        return commentData;
    }
    private Case_Comment_Custom__c GetDbCustomData( CustomCaseCommentData comment){
        Case_Comment_Custom__c commentData = new Case_Comment_Custom__c();
        case newCase = new Case();
        commentData.Case_Comments_Id__c = comment.caseCommentsId;
        commentData.CommentBody__c = comment.CaseComment;
        commentData.IsPublished__c = comment.isPublic;
        commentData.ParentId__c = comment.ParentId;
        commentData.CommentCreatedDate__c = DateTime.Now();
        CommentData.CreatorName__c =  UserInfo.getUserName();
        return commentData;
    }

    //business logic
    private boolean DisplayComments(DateTime closedDate){
        boolean retVal = false;
        Profile pfile = [Select Name from Profile where Id =: userinfo.getProfileid()];
        String pname = pfile.name;
        system.debug('pname =>' + pname);
        if (pname == 'Partner Community Profile') {
            DateTime currentDate = DateTime.now().addDays(-30);
            if (closedDate == null || currentDate < closedDate) {
                retVal = true;
            }
        }
        else {
            retVal = true;
        }
        return retVal;
    }


}