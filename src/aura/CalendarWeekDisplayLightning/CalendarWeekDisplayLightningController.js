/**
 * Created by arnab.karsarkar on 3/3/2017.
 */
({
     doInit:function(component, event, helper) {
           console.log('ininit');
            var myAction = component.get('c.getdayHours');
                     // Handle returned results...
                     // myAction.setParams({lastDate : component.get("v.lastDate")});
                     myAction.setCallback(component, function(response) {
                         var state = response.getState();

                         if(component.isValid() && state === "SUCCESS") {
                             var result = response.getReturnValue();
                             console.log(JSON.stringify(result));
                             component.set('v.hourStrings', result);
                         }
                     });
                     $A.enqueueAction(myAction);
        }
})