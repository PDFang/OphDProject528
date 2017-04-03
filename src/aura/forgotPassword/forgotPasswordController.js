({
    handleForgotPassword: function (component, event, helpler) {
        helpler.handleForgotPassword(component, event, helpler);
    },
    onKeyUp: function(component, event, helpler){
    //checks for "enter" key
        if (event.getParam('keyCode')===13) {
            helpler.handleForgotPassword(component, event, helpler);
        }
    },

      preview : function(component, event, helper) {
       $A.get('e.lightning:openFiles').fire({
        recordIds: [component.get("v.contentId")]
       });
      }

})