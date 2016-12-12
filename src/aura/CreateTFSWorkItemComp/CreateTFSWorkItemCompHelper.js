/**
 * Created by arnab.karsarkar on 10/21/2016.
 */
({
     /*
         *  Map the Schema.FieldSetMember to the desired component config, including specific attribute values
         *  Source: https://www.salesforce.com/us/developer/docs/apexcode/index_Left.htm#CSHID=apex_class_Schema_FieldSetMember.htm|StartTopic=Content%2Fapex_class_Schema_FieldSetMember.htm|SkinName=webhelp
         *
         *  Change the componentDef and attributes as needed for other components
         */
        configMap: {
            'anytype': { componentDef: 'ui:inputText', attributes: {} },
            'base64': { componentDef: 'ui:inputText', attributes: {} },
            'boolean': {componentDef: 'ui:inputCheckbox', attributes: {} },
            'combobox': { componentDef: 'ui:inputText', attributes: {} },
            'currency': { componentDef: 'ui:inputText', attributes: {} },
            'datacategorygroupreference': { componentDef: 'ui:inputText', attributes: {} },
            'date': {
                componentDef: 'ui:inputDate',
                attributes: {
                    displayDatePicker: true
                }
            },
            'datetime': { componentDef: 'ui:inputDateTime', attributes: {} },
            'double': { componentDef: 'ui:inputNumber', attributes: {} },
            'email': { componentDef: 'ui:inputEmail', attributes: {} },
            'encryptedstring': { componentDef: 'ui:inputText', attributes: {} },
            'id': { componentDef: 'ui:inputText', attributes: {} },
            'integer': { componentDef: 'ui:inputNumber', attributes: {} },
            'multipicklist': { componentDef: 'ui:inputSelect', attributes: {multiple: true} },
            'percent': { componentDef: 'ui:inputNumber', attributes: {} },
            'phone': { componentDef: 'ui:inputPhone', attributes: {} },
            'picklist': { componentDef: 'ui:inputSelect', attributes: {} },
            'reference': { componentDef: 'ui:inputText', attributes: {} },
            'string': { componentDef: 'ui:inputText', attributes: {} },
            'textarea': { componentDef: 'ui:inputRichText', attributes: {} },
            'time': { componentDef: 'ui:inputDateTime', attributes: {} },
            'url': { componentDef: 'ui:inputText', attributes: {} }
        },

        createForm: function(cmp) {
            console.log('FieldSetFormHelper.createForm');
            var fields = cmp.get('v.fields');
            var obj = cmp.get('v.record');
            var self = this;
            var inputDesc = [];
            var fieldPaths = [];
            for (var i = 0; i < fields.length; i++) {
                var field = fields[i];
                var config = {};
				console.log('field path ==>' + field.fieldPath);
                var opts = [];
                if(field.type.toLowerCase() == 'picklist'){
                    for(var j = 0; j<field.picklistOptions.length; j++)
                    {
                        var picklistVal = field.picklistOptions[j];

                        var isSelect = j == 0 ? true : false;
                        opts.push({
                            "class": "optionClass",
                             "label": picklistVal,
                             "value" : picklistVal,
                            "aura:id" : field.fieldPath,
                             "selected" : isSelect,
                            
                        });
                    }
                }
                config = self.configMap[field.type.toLowerCase()];
                if (config) {
                    inputDesc.push([
                        config.componentDef,
                       {
                           "required" : field.required,
                           "label" :  field.label,
                           "aura:id" : field.fieldPath,
                           "options" : opts,
                           "class" : "slds-input",
                        
                       }
                    ]);

                    fieldPaths.push(field.fieldPath);
                } else {
                    console.log('type ' + field.type.toLowerCase() + ' not supported');
                }

            }

            $A.createComponents(inputDesc, function(cmps) {


                var inputToField = {};
                for (var i = 0; i < fieldPaths.length; i++) {
                      //console.log('cmps ' + cmps[i]);
                   cmps[i].addHandler('change', cmp, 'c.handleValueChange');
                    inputToField[cmps[i].getGlobalId()] = fieldPaths[i];
                }
                cmp.set('v.form', cmps);
                cmp.set('v.inputToField', inputToField);
            });
        }
})