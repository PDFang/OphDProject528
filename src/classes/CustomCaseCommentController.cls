/**
 * Created by william.nelson on 9/20/2017.
 */

public with sharing class CustomCaseCommentController {
    public Id caseId {get; set;}
    public List<CustomCaseCommentData> commentList {get;set;}

    public CustomCaseCommentController( ApexPages.StandardController controller){
        string id = (string)controller.getId();
        Case newCase = new Case();
        newCase.id = Id;
        caseId = Id;
        system.debug('caseId ->' + caseId);
        this.commentList = getCommentList(newCase);
    }
    //get view
    //save/update method
    public List<CustomCaseCommentData> getCommentList (Case newCase ){
        CustomCaseCommentHelper helper = new CustomCaseCommentHelper();
        return helper.GetAggregateData(newCase);
    }
    public PageReference NewComment()
    {
        PageReference pr = new PageReference('/00a/e?parent_id='+ caseId + '&retURL=%2F' + caseId);
        pr.setRedirect(true);
        return pr;
    }
}