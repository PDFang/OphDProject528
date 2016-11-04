/**
 * Created by arnab.karsarkar on 10/18/2016.
 */
({
    init: function(cmp, event, helper) {
        console.log('this is init');
        var action = cmp.get('c.getFields');
        action.setCallback(this,
            function(response) {
                var state = response.getState();
                console.log('state =>' + state);
                if (state === 'SUCCESS'){
                console.log('WorkItemController getFields callback');
                var fields = response.getReturnValue();
                cmp.set('v.fields', fields);
                helper.createForm(cmp);
                }
            }
        );
        $A.enqueueAction(action);
    },

    /**handleValueChange: function(cmp, event, helper) {
        console.log('change');
        var inputToField = cmp.get('v.inputToField');
        var field = inputToField[event.getSource().getGlobalId()];
        var obj = cmp.get('v.record');
        if (!obj[field]) {
            // Have to make a copy of the object to set a new property - thanks LockerService!
            obj = JSON.parse(JSON.stringify(obj));
        }
        obj[field] = event.getSource().get('v.value');
        cmp.set('v.record', obj);
    }**/
})