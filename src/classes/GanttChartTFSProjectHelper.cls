/**
 * Created by william.nelson on 11/21/2016.
 */

public with sharing class GanttChartTFSProjectHelper {


    public static list<ChartData2> GetProjectsInPriority(list<string>  programName, list<string> TeamName)
    {

        list<ChartData2> dataList = new list<ChartData2>();
        list<Project__c> lstProjects  = queryProject(programName, TeamName);
        map<string, list<Project__c>> mpProjectsByTeam = GetProjectsByTeam(lstProjects);
        map<integer, string> sprintMaps = mapSprints();

        //iterate through the list due date based on size of project and current status
        for(string team : mpProjectsByTeam.keySet())
        {

            TeamSizeMap__c teamSize = TeamSizeMap__c.getValues(team);
            decimal idealTeam = teamSize.IdealTeamSize__c;
            double estimate = 0.0;
            for(Project__c proj : mpProjectsByTeam.get(team)){
                ProjectSizeMap__c projSize = ProjectSizeMap__c.getValues(proj.T_Shirt__c);
                double runningEstimate = projSize.Estimate__c + estimate;
                estimate = projSize.Estimate__c;

                integer sprintOut = integer.valueOf(runningEstimate/idealTeam) + 1;
                if(proj.ProjectStatus__c == 'Active/Being Worked')
                    sprintOut = 0;
                string sprint = sprintMaps.get(sprintOut);
                SprintDateMap__c sprintdate = SprintDateMap__c.getValues(sprint);
                date projectEndDate =  sprintdate.EndDate__c;
                date sprintStartDate = sprintdate.StartDate__c;
                integer datediff = sprintStartDate.daysBetween(projectEndDate);
                decimal estimatedDuration = (datediff * estimate).round();
                date projectStartDate = projectEndDate.addDays(-integer.valueOf(estimatedDuration));

                ChartData2 childData = new ChartData2();
                childData.ProjectId = proj.Name;
                childData.ProjectName = proj.Name + ' - ' + proj.Summary__c;
                childData.StartDate = projectStartDate;
                childData.EndDate = projectEndDate;
                childData.DurationDays = integer.valueOf(estimatedDuration);
                childData.PercentComplete = proj.Story_Point_Percentage_Complete__c;
                childData.ProjectManager = proj.ProjectManager__r.Name;
                childData.Team = team;
                childData.TShirtSize = proj.T_Shirt__c;
                childData.ProductChannel = proj.Primary_Product__c;
                childData.ProjectStatus = proj.ProjectStatus__c;
                ProgramColorMapping__c colorProgram = ProgramColorMapping__c.getValues(proj.Primary_Product__c);
                childData.ProgramColor = colorProgram.Color__c;
                TeamColorMapping__c colorTeam = TeamColorMapping__c.getValues(proj.Team__c);
                childData.TeamColor = colorTeam.Color__c;
                dataList.add(childData);
            }
        }

        //begin iterating through the list by team assign based on capacity
        return dataList;
    }


    public static list<Project__c> queryProject(list<string>  programName, list<string> TeamName)
    {
        list<Project__c> lstProjects  = new list<Project__c>();

        String[] statusFilters = new String[]{'Active/Being Worked', 'In Queue'};

        string queryString = 'select Name, ProjectManager__r.Name, ProjectStatus__c,BattingOrder__c, Primary_Product__c,Team__c, Summary__c,RequestedDeliveryDate__c, Story_Point_Percentage_Complete__c, T_Shirt__c, PercentComplete__c from Project__c Where ProjectStatus__c in :statusFilters and RecordType.Name = \'IT Project Request\' ';
        if(programName.size() > 0)
            queryString +=  ' And Primary_Product__c in :programName';
        else
                queryString +=  ' And Primary_Product__c != null and T_Shirt__c !=null';

        if(TeamName.size() > 0)
            queryString += ' And Team__c in :TeamName';

        queryString += ' Order By BattingOrder__c asc';

        System.debug(queryString);

        lstProjects = Database.query(queryString);



        return lstProjects;

    }

    private static map<string, list<Project__c>> GetProjectsByTeam(list<Project__c> lstProjects)
    {
        map<string, list<Project__c>> mpProjectsByTeam = new map<string, list<Project__c>>();
        ProjectCustomSort[] sortedPrjectList = new list<ProjectCustomSort>();
        for(Project__c proj : lstProjects){
            if(proj.BattingOrder__c == null)
                proj.BattingOrder__c = 0;
            if(proj.ProjectStatus__c == 'Active/Being Worked')
                proj.BattingOrder__c = -1;
            sortedPrjectList.add(new ProjectCustomSort(proj));
        }
        sortedPrjectList.sort();

        for(ProjectCustomSort projSorted : sortedPrjectList){
            if(mpProjectsByTeam.containsKey(projSorted.project.Team__c))
            {
                mpProjectsByTeam.get(projSorted.project.Team__c).add(projSorted.project);
            }
            else
            {
                mpProjectsByTeam.put(projSorted.project.Team__c, new list<Project__c>{projSorted.project});
            }
        }

        return mpProjectsByTeam;

    }

    private static map<integer, string> mapSprints(){
        map<string, SprintDateMap__c> mpSprintMaps =   SprintDateMap__c.getall();
        map<string, SprintDateMap__c> tempMap = new map<string, SprintDateMap__c>();
        tempMap.putAll(mpSprintMaps);
        list<string> sprintNames = new list<string>();
        sprintNames.addAll(mpSprintMaps.keySet());
        sprintNames.sort();

        map<integer, string> mpSprint = new map<integer, string>();
        date currentDate = system.today();

        for(SprintDateMap__c dateMap : mpSprintMaps.values()){
            if(dateMap.EndDate__c <= currentDate){
                tempMap.remove(dateMap.Sprint__c);
            }
        }
        integer currentSprint = 0;
        for (string sprint: sprintNames){
            if(tempMap.containsKey(sprint)){
                mpSprint.put(currentSprint, sprint);
                currentSprint++;
            }
        }

        return mpSprint;

    }

    public Project__c GetProjectByName (string Name){

        Project__c project = [Select id, Name from Project__c where name = :Name ];
        return project;
    }

    public static list<SprintDateMap__c>   GetIterationList()
    {
        list<SprintDateMap__c> iterationDates = SprintDateMap__c.getall().values();
        list<SprintDateMap__c> lstSprints = new list<SprintDateMap__c>();
        for(SprintDateMap__c sp : iterationDates)
        {
            if(sp.EndDate__c >= system.today())
            {
                lstSprints.add(sp);
            }
        }
        return lstSprints;
    }



}
