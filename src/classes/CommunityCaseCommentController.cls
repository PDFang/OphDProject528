/**
 * Created by ravish.chawla on 8/29/2017.
 */

public with sharing class CommunityCaseCommentController {

    public CommunityCaseCommentController(){

    }

    @AuraEnabled
    public static List<CaseComment> getCaseComments(String caseId){
        System.debug('caseId =>' + caseId);

        UserRecordAccess[] user = [SELECT RecordId, HasAllAccess, HasReadAccess, HasEditAccess from UserRecordAccess where RecordId =: caseId and UserId =: UserInfo.getUserId()];
        System.debug('user =>' + user);

        if(user.size() > 0){
            if(user[0].HasAllAccess == true || user[0].HasReadAccess == true || user[0].HasEditAccess == true){
                List<CaseComment> caseCommentsList = new List<CaseComment>();

                caseCommentsList = [SELECT CommentBody, CreatedDate, ParentId from CaseComment where ParentId =: caseId order by CreatedDate];
                System.debug('caseCommentsList =>' + caseCommentsList);

                return caseCommentsList;
            }
        }

        return null;


    }
}