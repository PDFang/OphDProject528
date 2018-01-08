/**
 * Created by ravish.chawla on 8/29/2017.
 */

public without sharing class CommunityCaseCommentController {

    public CommunityCaseCommentController(){

    }

    @AuraEnabled
    public static List<CaseComment> getCaseComments(String caseId){
        System.debug('caseId =>' + caseId);
        List<CaseComment> caseCommentsList = new List<CaseComment>();
        caseCommentsList = [SELECT CommentBody, CreatedDate,CreatedBy.Name, ParentId from CaseComment where ParentId =: caseId order by CreatedDate];
        System.debug('caseCommentsList =>' + caseCommentsList);
        return caseCommentsList;
    }
}