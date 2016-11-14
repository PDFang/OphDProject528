({
	doInit : function(component, event, helper) {
        var action = component.get('c.getCommunityLinks');
        action.setCallback(this, function(response) {
           var state = response.getState();
            if(component.isValid() && state === "SUCCESS") {
                component.set("v.CommunityLinks", response.getReturnValue())
            }
        });
        $A.enqueueAction(action);
	},

})