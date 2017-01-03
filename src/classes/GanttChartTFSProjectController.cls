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
        PageReference demoPage = new PageReference('/' +  project.Id);
        //PageReference demoPage = new PageReference('http://www.yahoo.com');
        demoPage.setRedirect(true);
        return demoPage;
    }


    @RemoteAction
    public static string kendoData (){
        list<string> programName = new list<string>{
                'Customer Portal',
                'Partner Portal'
        };
        list<string> TeamName = new list<string>{
                'Avengers',
                'Justice League'
        };

        TimeLineData timeline = new  TimeLineData();
        list<ChartData2> dataList = new list<ChartData2>();
        dataList = GanttChartTFSProjectHelper.GetProjectsInPriority(programName, TeamName);
        timeline.lstChartData = dataList;
        timeline.lstSprintData = GanttChartTFSProjectHelper.GetIterationList();

        list<GanttData> lstGanttData = new list<GanttData>();

        for(ChartData2 cd : dataList){
            GanttData projects = new GanttData();
            projects.ProjectId = cd.ProjectId;
            projects.ProjectName = cd.ProjectName;
            projects.StartDate = cd.StartDate;
            projects.EndDate = cd.EndDate;
            projects.ParentId = cd.Sprint;
            projects.GlobalPriority = cd.GlobalPriority;
            projects.Expanded = true;
            projects.PercentComplete = 0;
            projects.Summary = false;
            projects.ProgramColor = cd.ProgramColor;

            lstGanttData.add(projects);
        }

        integer i = 0;
        for(SprintDateMap__c sp : timeline.lstSprintData)
        {
            i++;
            GanttData gd = new GanttData();
            gd.ProjectId = sp.Sprint__c;
            gd.ProjectName = sp.Sprint__c;
            gd.StartDate = sp.StartDate__c;
            gd.EndDate = sp.EndDate__c;
            gd.ParentId = null;
            gd.Expanded = true;
            gd.GlobalPriority = i;
            gd.PercentComplete = 0;
            gd.Summary = true;
            gd.ProgramColor = null;
            lstGanttData.add(gd);

        }
        return JSON.serialize(lstGanttData);
    }


    public class GanttData
    {
        public string  ProjectId {get; set;}
        public string  ProjectName {get; set;}
        public Date EndDate {get; set;}
        public Date StartDate {get; set;}
        public string ParentId {get; set;}
        public decimal GlobalPriority{get;set;}
        public decimal PercentComplete{get;set;}
        public boolean Expanded{get;set;}
        public boolean Summary{get;set;}
        public string ProgramColor{get; set;}


    }

}