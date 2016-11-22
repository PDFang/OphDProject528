/**
 * Created by mohandaas.rangaswamy on 11/21/2016.
 */
({
    doInit : function(component, event, helper){
        var opportunityId = component.get('v.opportunityId');
//        if(!$A.util.isEmpty(opportunityId)){
            helper.selectUsers(component);
//        }
    },

    clickShare : function(component, event, helper){
        helper.shareOpportunity(component);

    }
})