/**
 * Created by mohandaas.rangaswamy on 11/21/2016.
 */
({
    doInit : function(component, event, helper){
        var opportunityId = component.get('v.opportunityId');
        if(!$A.util.isEmpty(opportunityId)){
            helper.selectUsers(component);
        } else{
            $A.createComponents([
                    ["ui:message",{
                        "title" : "Error",
                        "severity" : "error",
                    }],
                    ["ui:outputText",{
                        "value" : "Opportunity ID is blank."
                    }]
                ],
                function(components, status, errorMessage){
                    if (status == "SUCCESS") {
                        var message = components[0];
                        var outputText = components[1];

                        message.set("v.body", outputText);
                        var messageBlock = component.find('messageBlock');
                        // Replace div body with the dynamic component
                        messageBlock.set("v.body", message);
                    }
                    else if (status == "INCOMPLETE") {
                        console.log("No response from server or client is offline.")
                        // Show offline error
                    }
                    else if (status == "ERROR") {
                        console.log("Error: " + errorMessage);
                        // Show error message
                    }
                }
            );
        }
    },

    clickShare : function(component, event, helper){
        helper.shareOpportunity(component);
    },

    clickCancel : function (component, event, helper) {
        var opportunityId = component.get('v.opportunityId');
        window.location.assign('/'+opportunityId);
/*
        var redirectEvent = $A.get('e.force:navigateToSObject');
        redirectEvent.setParams({
          "recordId": opportunityId
        });
        redirectEvent.fire();
*/
    }
})