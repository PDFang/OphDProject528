/**
 * Created by william.nelson on 9/25/2017.
 */

public with sharing class CustomCaseCommentAddController {
    public string caseId {get;set;}
    public string commentId{get;set;}
    public string commentBody {get;set;}
    public boolean isPublic {get;set;}
    public string redirectUrl {get;set;}

    public CustomCaseCommentAddController(){
        caseId = ApexPages.currentPage().getParameters().get('parent_id');
        redirectUrl =  ApexPages.currentPage().getParameters().get('retURL');
        system.debug('caseId ->' + caseId);

    }
    public CustomCaseCommentAddController( ApexPages.StandardController controller){
        string id = (string)controller.getId();
        if (id != null) {
            id = ApexPages.currentPage().getParameters().get('parent_id');
        }
        if (id != null){
            Case newCase = new Case();
            newCase.id = Id;
            caseId = Id;
            system.debug('caseId ->' + caseId);
        }
        system.debug('Case ->' + id);
    }

    public PageReference CreateComment(){
        CustomCaseCommentHelper helper = new CustomCaseCommentHelper();
        //system.debug ('comment.isPublic =>' + comment.isPublic);
        //system.debug ('CaseId = >' + caseId);
        system.debug ('commentBody1 = >' + commentBody);
        system.debug ('isPublic = >' + isPublic);
        system.debug ('caseId = >' + caseId);
        if (commentBody != null){
            system.debug ('Upserting');
            CustomCaseCommentData UpsertComment = new CustomCaseCommentData();
            UpsertComment.CaseComment = commentBody;
            UpsertComment.isPublic = isPublic;
            UpsertComment.ParentId = caseId;
            helper.SaveComment(UpsertComment);
        }

        PageReference pr = new PageReference(redirectUrl);
        pr.setRedirect(true);
        return pr;
    }
    public PageReference CancelCreate(){
        PageReference pr = new PageReference(redirectUrl);
        pr.setRedirect(true);
        return pr;
    }

}