/**
 * Created by william.nelson on 8/29/2017.
 */
({
      doInit : function(component, event, helper) {
        //retrieve case comments during component initialization
        helper.loadComments(component);
      }
})