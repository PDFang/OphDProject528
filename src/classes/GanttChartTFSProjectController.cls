/**
 * Created by arnab.karsarkar on 11/15/2016.
 */

public without sharing class GanttChartTFSProjectController {

    public string selectedOwner{get; set;}
    public list<SelectOption> owmersList{get;set;}
    public list<SelectOption> programs{get;set;}
    public boolean isVisibleProgramList{get;set;}


    public list<string> selectedTeams{get; set;}
    public list<SelectOption> TeamLists{get;set;}
    public list<string> selectedPrograms{get; set;}

    //Comments

    public GanttChartTFSProjectController(){
        loadCheckBoxes();
    }

    public void loadCheckBoxes()
    {
        programs = new list<SelectOption>();
        TeamLists  = new list<SelectOption>();
        selectedTeams = new list<string>();
        selectedPrograms = new list<string>();

        set<string> stPrograms = new set<string>();
        set<string> stTeams = new set<string>();
        String[] statusFilters = new String[]{'In Queue'}; // 'Active/Being Worked',  - Future implementation
        for(Project__c project : [select Development_Team__c, Primary_Product__c From Project__c where Primary_Product__c != null and Development_Team__c !=null and T_Shirt__c !=null and RecordType.Name = 'IT Project Request' and ProjectStatus__c in :statusFilters]){
            stPrograms.add(project.Primary_Product__c);
            stTeams.add(project.Development_Team__c);
        }

        for(string program : stPrograms){
            programs.add(new SelectOption(program, program));
            selectedPrograms.add(program);
        }

        for(string team : stTeams){
            TeamLists.add(new SelectOption(team, team));
            selectedTeams.add(team);
        }

    }


    @RemoteAction
    public static TimeLineData getChartData(list<string> programName, list<string> TeamName)
    {

        TimeLineData timeline = new  TimeLineData();
        list<ChartData2> dataList = new list<ChartData2>();
        dataList = GanttChartTFSProjectHelper.GetProjectsInPriority(programName, TeamName);
        timeline.lstChartData = dataList;
        timeline.lstSprintData = GanttChartTFSProjectHelper.GetIterationList();
        return timeline;
    }

    @RemoteAction
    public static PageReference RedirectToProject(string projName)
    {
        GanttChartTFSProjectHelper helper = new GanttChartTFSProjectHelper();
        Project__c project =  helper.GetProjectByName(projName);
        if(project != null){
            PageReference demoPage = new PageReference('/' +  project.Id);
            //PageReference demoPage = new PageReference('http://www.yahoo.com');
            demoPage.setRedirect(true);
            return demoPage;
        }
        return null;

    }


    @RemoteAction
    public static string kendoData (list<string> programName, list<string> TeamName){

        string ganttData = GanttChartTFSProjectHelper.GetProjects(programName, TeamName);
        return ganttData;


    }

}