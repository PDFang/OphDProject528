({
	doInit : function(component, event, helper) {
        var toggle = false;
        var links = [{name: 'PartnerCommunity', label: 'Partner Community', url: 'https://www.salesforce.incontact.com', isVisible: true },
                     {name: 'CustomerCommunity', label: 'Customer Community', url: 'http://www.microsoft.com', isVisible: toggle },
                     {name: 'Support Site', label: 'Support Site', url: 'https://www.support.incontact.com', isVisible: true }];

        var action = component.get('c.getPermissionSets');
        action.setCallback(this, function(response) {
           var state = response.getState();
            if(component.isValid() && state === "SUCCESS") {
                component.set("v.CommunityLinks", response.getReturnValue())
            }
        });
        $A.enqueueAction(action);
        /*component.set("v.CommunityLinks", links);*/
	},

})