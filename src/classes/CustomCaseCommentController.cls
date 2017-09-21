/**
 * Created by william.nelson on 9/20/2017.
 */

public with sharing class CustomCaseCommentController {
    public List<CustomCaseCommentData> commentList {get;set;}

    public CustomCaseCommentController( ApexPages.StandardController controller){
        string caseId = (string)controller.getId();
        Case newCase = new Case();
        newCase.id = caseId;
        system.debug('caseId ->' + caseId);
        this.commentList = getCommentList(newCase);
    }
    //get view
    //save/update method
    public List<CustomCaseCommentData> getCommentList (Case newCase ){
        CustomCaseCommentHelper helper = new CustomCaseCommentHelper();
        return helper.GetAggregateData(newCase);
    }
}