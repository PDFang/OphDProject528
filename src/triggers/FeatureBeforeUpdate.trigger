trigger FeatureBeforeUpdate on Feature__c (before update, before insert) 
{
    /*
    Set<Id> projIds = new Set<Id>();
    
    //get all project ids
    for(Feature__c f:trigger.new)
    {
        if(!projIds.contains(f.Project__c))
        {
            projIds.add(f.Project__c);
        }
    }
    
    //get map of projects
    Map<Id, Project__c> projects = new Map<Id, Project__c>([SELECT Id, ProjectStatus__c FROM Project__c WHERE Id IN :projIds]);
    
    //features cannot be edited after done
    for(Feature__c f:trigger.new)
    {
        if(projects.get(f.Project__c).ProjectStatus__c == 'Done')
        {
            f.addError('Cannot add or update features once a project is done.');
        }
    }
    */
    
}