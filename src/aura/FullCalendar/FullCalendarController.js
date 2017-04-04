/**
 * Created by arnab.karsarkar on 3/9/2017.
 */
({
  preview : function(component, event, helper) {
      var contentId = '0693C000000H19mQAC';
           $A.get('e.lightning:openFiles').fire({
        recordIds: [contentId]
       });
      }
})