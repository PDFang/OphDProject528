/**
 * Created by mohandaas.rangaswamy on 11/21/2016.
 */
({
    selectUsers : function(component){
        var action = component.get('c.getiCEPartners');
        action.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS' && component.isValid()){
                component.set('v.partnerList', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    shareOpportunity : function(component){

        var opportunityId = component.get('v.opportunityId');
        var partnerList = component.get('v.partnerList');
        var action = component.get('c.shareOpportunity');
        action.setParams({'opportunityId': opportunityId, 'jsonString': JSON.stringify(partnerList)});
        action.setCallback(this, function(response){
            if(response.getState() == 'SUCCESS' && component.isValid()){
                component.set('v.result', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})