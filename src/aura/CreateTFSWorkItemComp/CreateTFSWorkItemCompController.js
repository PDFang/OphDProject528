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

    doSubmit: function(cmp, event, helper){
         var record = [];
        record = cmp.get('v.record');
        var inputToField = cmp.get('v.inputToField');
       // var field = inputToField[event.getSource().getGlobalId()];
        //var obj = cmp.get('v.record');

       record = JSON.parse(JSON.stringify(record));
       console.log(JSON.stringify(record));
        cmp.set('v.result', JSON.stringify(record));
       var errorMessages = [];
       var fields = cmp.get('v.changedFields');
       var requiredFields = [];
        for(field in inputToField)
        {
          for(i = 0; i < fields.length; i++){
               if(inputToField[field] == fields[i]){
                   delete inputToField[field];
               }

          }

        }
        for(field in inputToField){
            var comp = $A.getComponent(field);
            comp.set("v.errors", [{message:"Value cannot be blank" }]);
            $A.util.addClass(comp, 'errorMessage');
        }
    },
    
    handleValueChange: function(cmp, event, helper) {
        console.log('change');
        var inputToField = cmp.get('v.inputToField');
		var records =  cmp.get('v.record');
        var field = inputToField[event.getSource().getGlobalId()];
        var comp = $A.getComponent(event.getSource().getGlobalId());
        comp.set("v.errors", []);
         $A.util.removeClass(comp, 'errorMessage');
        var obj = {};
        if (!obj[field]) {
            // Have to make a copy of the object to set a new property - thanks LockerService!
            obj = JSON.parse(JSON.stringify(obj));
        }
        obj[field] = event.getSource().get('v.value');
        records.push(obj);
        var fields =  cmp.get('v.changedFields');
        fields.push(field);
        cmp.set('v.changedFields', fields);
        cmp.set('v.record', records);
    }
})