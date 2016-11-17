/**
 * Created by arnab.karsarkar on 11/15/2016.
 */

public without sharing class GanttChartTFSProjectController {

    public string selectedOwner{get; set;}
    public list<SelectOption> owmersList{get;set;}
    public list<SelectOption> programs{get;set;}
    public boolean isVisibleProgramList{get;set;}
    public string selectedProgram{get; set;}

    public list<string> selectedTeams{get; set;}
    public list<SelectOption> TeamLists{get;set;}



    public GanttChartTFSProjectController(){
        owmersList = new list<SelectOption>();
        owmersList = loadProjectOwners();
        system.debug('ownerList ==>' + owmersList);
        isVisibleProgramList = false;
    }

    public list<SelectOption> loadProjectOwners()
    {
        system.debug('came here');
        list<SelectOption> owners = new list<SelectOption>();
        map<Id, string> ownerMap = new  map<Id, string> ();
        owners.add(new SelectOption('None', 'None'));
        for(Project__c proj : [select Id, ProjectOwner__r.Name,  ProjectOwner__c
                                from Project__c
                                where  RecordType.Name = 'PMO Project'
                                And ProjectStatus__c Not in ('Completed','Closed', 'Canceled', 'On Hold')
                                And ProjectType__c = 'Corporate IT'])
        {

            if(proj.ProjectOwner__c != null )
            {
                ownerMap.put(proj.ProjectOwner__c, proj.ProjectOwner__r.Name);
                //owners.add(new selectOptions(proj.ProjectOwner__c,proj.ProjectOwner__r.Name));
            }
        }

        for(Id userId : ownerMap.keySet())
        {
            owners.add(new SelectOption(userId, ownerMap.get(userId)));
        }

        return owners;

    }

    public void loadPrograms()
    {
        programs = new list<SelectOption>();
        programs.add(new SelectOption('All', 'All'));
        TeamLists  = new list<SelectOption>();
        selectedTeams = new list<string>{'Avengers', 'Justice League', 'X-Men'};
        for(Project__c proj : [select Id, Summary__c
                                from Project__c
                                where  RecordType.Name = 'PMO Project'
                                And ProjectOwner__c = : selectedOwner])
        {
            programs.add(new SelectOption(proj.Summary__c, proj.Summary__c));
        }
        TeamLists.add(new SelectOption('Avengers', 'Avengers'));
        TeamLists.add(new SelectOption('Justice League', 'Justice League'));
        TeamLists.add(new SelectOption('X-Men', 'X-Men'));
        isVisibleProgramList = true;

    }

    @RemoteAction
    public static list<ChartData> getChartData(string ownerId, string programName, list<string> TeamName)
    {
        if(ownerId == '' && ownerId == null )
            return null;

        List<RelatedProject__c> rpChildList = new list<RelatedProject__c>();
        list<ChartData> dataList = new list<ChartData>();
        map<string, Project__c> parentProjects = new map<string, Project__c>();
        list<Project__c> lstProjects  = new list<Project__c>();

        string queryString = 'select Name, Summary__c,PlannedStartDate__c, Scheduled_Start_Date__c,PercentComplete__c from Project__c Where ProjectOwner__c = :ownerId and RecordType.Name = \'PMO Project\' ';
        if(programName != '')
        queryString +=  ' And Summary__c = :programName';

        lstProjects = Database.query(queryString);

        for(Project__c proj :lstProjects)
        {
            parentProjects.put(proj.Id, proj);
        }
        set<string> projectids = parentProjects.keySet();
       // set<string> stTeams = ;

        string childQueryString = 'SELECT Id, ChildProject__r.Name, ChildProject__r.RecordType.Name, ChildProject__r.PlannedStartDate__c, ' +
                              'ChildProject__r.Summary__c, ChildProject__r.ClosedDate__c, ParentProject__c, ChildProject__r.Team__c, ParentProject__r.Name '+
                              ' FROM RelatedProject__c WHERE ParentProject__c in :projectids';

        if(TeamName.size() > 0)
            childQueryString += ' And ChildProject__r.Team__c in :TeamName';

        system.debug('childQueryString =>' + childQueryString);
        list<RelatedProject__c> relatedProjects = Database.query(childQueryString);

       set<Id> parentProjectIds = new set<id>();

        for(RelatedProject__c childProject :relatedProjects)
        {

            if(parentProjects.containsKey(childProject.ParentProject__c) && !parentProjectIds.contains(childProject.ParentProject__c))
                {
                    Project__c parent = parentProjects.get(childProject.ParentProject__c);
                    ChartData data = new ChartData();
                    data.ProjectId = parent.Name;
                    data.ProjectName = parent.Summary__c;
                    data.StartDateDay = parent.PlannedStartDate__c.day();
                    data.StartDateMonth = parent.PlannedStartDate__c.month() - 1;
                    data.StartDateYear = parent.PlannedStartDate__c.year();
                    data.DurationDays = 90;
                    data.PercentComplete = parent.PercentComplete__c;
                    data.Dependency = null;
                    dataList.add(data);

                    parentProjectIds.add(childProject.ParentProject__c);
                }

                    ChartData data = new ChartData();
                    data.ProjectId = childProject.ChildProject__r.Name;
                    data.ProjectName = childProject.ChildProject__r.Summary__c + '(' + childProject.ChildProject__r.Team__c + ')';
                    data.StartDateDay = childProject.ChildProject__r.PlannedStartDate__c.day();
                    data.StartDateMonth = childProject.ChildProject__r.PlannedStartDate__c.month() - 1;
                    data.StartDateYear = childProject.ChildProject__r.PlannedStartDate__c.year();
                    data.DurationDays = 30;
                    data.PercentComplete = 55;
                    data.Dependency = childProject.ParentProject__r.Name;
                    dataList.add(data);

        }


        return dataList;
    }


    public class ChartData
    {
        public string  ProjectId {get; set;}
        public string  ProjectName {get; set;}
        public integer  StartDateDay{get; set;}
        public integer  StartDateMonth{get; set;}
        public integer  StartDateYear{get; set;}
      //  public string  EndDate{get; set;}
        public integer DurationDays{get; set;}
        public decimal PercentComplete{get; set;}
        public string Dependency{get;set;}
    }


}