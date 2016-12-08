/**
 * Created by arnab.karsarkar on 10/21/2016.
 */

public with sharing class WorkItemCreateController {


    // create a FieldSet wrapper class
    public class FieldSetMember
    {
        public FieldSetMember(Schema.FieldSetMember f)
        {
            this.DBRequired = f.DBRequired;
            this.fieldPath = f.fieldPath;
            this.label = f.label;
            this.required = f.required;
            this.type = '' + f.getType();
            picklistOptions = new list<string>();
            system.debug('type =>' + type);
            if(type.containsIgnoreCase('picklist')) {

                string fieldName = f.fieldpath;
                Schema.DescribeSObjectResult describeResult = SObjectType.ISTFSWorkItem__c;
                Map<String,Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
                system.debug('fieldsMap =>' + fieldsMap);
                Schema.SObjectField field = fieldsMap.get(fieldName);
                system.debug('field =>' + field);
                Schema.DescribeFieldResult describeField = field.getDescribe();
                List<Schema.PicklistEntry> fieldResult = describeField.getPicklistValues();
                system.debug('fieldResult =>' + fieldResult);
                system.debug('fieldResult =>' + fieldResult);
                this.picklistOptions.add('--None--');
                for (Schema.PicklistEntry pickList : fieldResult) {
                    this.picklistOptions.add(pickList.getLabel());
                }
            }

        }

        public FieldSetMember(Boolean DBRequired)
        {
            this.DBRequired = DBRequired;
        }

        @AuraEnabled
        public Boolean DBRequired { get;set; }

        @AuraEnabled
        public String fieldPath { get;set; }

        @AuraEnabled
        public String label { get;set; }

        @AuraEnabled
        public Boolean required { get;set; }

        @AuraEnabled
        public String type { get; set; }

        @AuraEnabled
        public list<string> picklistOptions{get;set;}

    }

    @AuraEnabled
    public static List<FieldSetMember> getFields()
    {
        List<Schema.FieldSetMember> fieldSet = SObjectType.ISTFSWorkItem__c.FieldSets.WorkItemCreateFields.getFields();
        List<FieldSetMember> fset = new List<FieldSetMember>();
        for (Schema.FieldSetMember f: fieldSet) {
            fset.add(new FieldSetMember(f));

        }
        system.debug('fset +>' + fset);
        return fset;
    }

}