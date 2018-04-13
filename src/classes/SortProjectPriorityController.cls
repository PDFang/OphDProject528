/**
 * Created by arnab.karsarkar on 3/10/2017.
 * THis is just an one time fix of Project priorities
 */

public with sharing class SortProjectPriorityController {
    public string priorityType{get; set;}
    public list<SelectOption> filterOptions {get; set;}


    public SortProjectPriorityController(){
        GetAvailablePrograms();
        priorityType = 'Global';
        getProjectLists();
    }

    public list<SelectOption> GetAvailablePrograms()
    {
        Schema.DescribeFieldResult FilterFieldDescription = Project__c.Primary_Product__c.getDescribe();

        filterOptions = new list<SelectOption>();
        filterOptions.add(new SelectOption('Global', 'Global'));

        for (Schema.Picklistentry picklistEntry : FilterFieldDescription.getPicklistValues())
        {
            filterOptions.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
        }

        return filterOptions;
    }


    public void sort(){
        list<Project__c> lstProjects = new list<Project__c>();

        List<Project__c> projectLists =  getProjectLists();
        integer i = 0;
        for(Project__c proj : projectLists){
              i++;
            Project__c updProj = new Project__c(id = proj.id);

            if(priorityType == 'Global')
                updProj.BattingOrder__c = i;
            else
                updProj.Ops_Backlog_Priority__c = i;
            
            lstProjects.add(updProj);
        }

        try{
            TriggerHandler.bypass('ProjectTriggerHandler');
             TriggerHandler.bypass('ProjectTriggerHelper');
            ProjectTriggerHandler.lockSortingFields = false;
             update lstProjects;
            sortITProjects();
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.CONFIRM, 'Succussefully updated ' + lstProjects.size() + ' records');
            ApexPages.addMessage(myMsg);
            getProjectLists();

        }catch (Exception ex){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.FATAL, 'Error Occured - ' + ex.getMessage());
            ApexPages.addMessage(myMsg);
        }



    }

    public list<Project__c> getProjectLists(){
        string priorityField;
        if(priorityType == 'Global')
            priorityField = 'BattingOrder__c';
        else
                priorityField = 'Ops_Backlog_Priority__c';

        string queryProjects = 'Select Id, Name, ProjectStatus__c, BattingOrder__c, Ops_Backlog_Priority__c, Summary__c, RequestedDeliveryDate__c, Delivery_Channel__c, Request_Channel__c, ExpectedDeliveryDate__c, ProjectOwner__r.Name, '
                + ' ProjectType__c,Complete__c, Primary_Product__c From Project__c where Primary_Product__c != null '
                + ' and  RecordType.Name = \'PMO Project\'  and ProjectStatus__c not in (\'Completed\',\'Closed\',\'Canceled\') and ProjectType__c != \'Time Keeping\' '
                + ' and (' + priorityField + ' != null AND ' +  priorityField + ' != 0)';

        if(priorityType != 'Global')
            queryProjects += ' and Primary_Product__c =: priorityType';

        queryProjects += '  order by ' + priorityField + ', CreatedDate';

        List<Project__c> projectLists =  Database.query(queryProjects);

        return projectLists;

    }


    @future
    private static void sortITProjects()
    {
        list<Project__c> ITProjects = new list<Project__c>();
        list<string> excludedStatus = new list<string>();
        List<SiteConfiguration__c> config = SiteConfiguration__c.getall().values();
        excludedStatus = config[0].ProjectSortExcludedStatus__c.split(',');
        map<Id, Project__c> SortITPrOjects = new map<Id, Project__c>();
        ITProjects = [select Id, RoadMapPriority__c, ParentProject__r.BattingOrder__c, ParentProject__r.Ops_Backlog_Priority__c,PriorityScore__c, CreatedDate
        FROM Project__c
        Where RecordType.Name = 'IT Project Request' AND ParentProject__r.RecordType.Name = 'PMO Project'
        AND ParentProject__c != null
        AND ProjectStatus__c not in :excludedStatus
        AND ProjectType__c != 'Time Keeping'
        Order By PriorityScore__c,PrioritySortDtFormula__c, CreatedDate
        ];
        integer i = 0;
        for(Project__c proj : ITProjects){
            i++;

            proj.RoadmapPriority__c = i;

        }
        system.debug('** SortITProject => ' + ITProjects.size());

        if(ITProjects.size() > 0){
            ProjectTriggerHandler.lockSortingFields = false;
            TriggerHandler.bypass('ProjectTriggerHandler');
             TriggerHandler.bypass('ProjectTriggerHelper');
            
            update ITProjects;
            
        }

    }

    public void refreshProjects(){
        getProjectLists();

    }
}