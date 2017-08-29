/**
 * Created by william.nelson on 8/29/2017.
 */
({
    loadComments: function (comp ){
        CommunityCaseCommentController.
        var action = cmp.get("c.getCaseComments");
        action.setParams({caseId : cmp.get("v.caseId")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                cmp.set("v.CaseCommentList", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})