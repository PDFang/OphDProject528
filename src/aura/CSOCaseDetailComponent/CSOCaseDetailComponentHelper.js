/**
 * Created by arnab.karsarkar on 1/8/2018.
 */
({
    getFieldList: function(component, helper){
         var action = component.get("c.GetFieldList");
         action.setCallback(this,function(a){
              console.log('field list >>> ' + a.getReturnValue());
                component.set("v.fieldsToShow",a.getReturnValue());
                var fields = a.getReturnValue().toString();
                var fieldList = fields.split(',');
                component.set("v.fieldList",fieldList);
                 helper.getRecord(component);
         });
         $A.enqueueAction(action);
    },

    getRecord : function(component) {
       var fields = component.get("v.fieldsToShow");
       var caseId = component.get("v.caseId");
       var action = component.get("c.GetCaseRecord");
       var fieldList =  component.get("v.fieldList");

       action.setParams({
         caseId:caseId
       });
       action.setCallback(this,function(a){
         console.log('Case record ==> ' + a.getReturnValue());
         var sobjectrecord = a.getReturnValue();
         for (var idx in fieldList) {
           console.log(fieldList[idx]);
           console.log(sobjectrecord[fieldList[idx]]);
           $A.createComponent(
             "ui:outputText",
             {
               "label": fieldList[idx],
               "value": sobjectrecord[fieldList[idx]],
               "class":"outputcls"
             },
             function(newCmp){
                //Add the field list to the body array
                if (component.isValid()) {
                   var body = component.get("v.body");
                   body.push(newCmp);
                   component.set("v.body", body);
                }
             }
           );
         }
       component.set("v.detailRecord",a.getReturnValue());
     });
     $A.enqueueAction(action);
    }
})