/**
 * Created by william.nelson on 8/29/2017.
 */
({
    loadComments: function (cmp ){
        console.log('Calling SF');
        var action = cmp.get("c.getCaseComments");
        action.setParams({caseId : cmp.get("v.caseId")});
        console.log('Calling SF 1');
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                cmp.set("v.CaseCommentList", response.getReturnValue());

            }
        });
        $A.enqueueAction(action);
    }
})