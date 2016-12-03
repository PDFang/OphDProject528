/**
 * Created by william.nelson on 11/21/2016.
 */

public with sharing class GanttChartTFSProjectHelper {

    public  List<TFSSprintDate__c>   GetIterationList(date startDate, date endDate)
    {
        List<TFSSprintDate__c> lstSprints = [Select Name, Start_Date__c, End_Date__c from TFSSprintDate__c where Start_Date__c <= NEXT_N_MONTHS:6  and  End_Date__c  >=  TODAY order by Start_Date__c];
        return lstSprints;
    }

    public Project__c GetProjectByName (string Name){

        Project__c project = [Select id, Name from Project__c where name = :Name ];
        return project;
    }

    public List<Project_Ideal_Team__c> GetIdealTeamList (){
        List<Project_Ideal_Team__c> lst  = [Select Name, Ideal_Teams__c from Project_Ideal_Team__c];
        return lst;
    }

    public Map<String, Project_Sprint_Size__c> GetSprintSizeList() {
        Map<String, Project_Sprint_Size__c> sprintSize = new Map<String, Project_Sprint_Size__c>();
        for (Project_Sprint_Size__c sprint :[SELECT Name, Estimate__c FROM Project_Sprint_Size__c])
        {
            sprintSize.put(sprint.Name, sprint);
        }
        return sprintSize;
    }

    public list<ChartData> GetProjectsInPriority(map<string, list<Project__c>> parentProjects)
    {
        list<ChartData> dataList = new list<ChartData>();
        //get ideal team list
        Map<String, Project_Sprint_Size__c> sprintMap = GetSprintSizeList();
        //get t-shirt iteration size
        List<Project_Ideal_Team__c> idealTeamLst = GetIdealTeamList();

        //start calculating delivery date
        //iterate through the list due date based on size of project and current status

        for(String program : parentProjects.keySet())
        {
            Date projectStartDate;
            Date projectEndDate;
            long sprintLength;

            for (Project__c proj : parentProjects.get(program)) {
                ChartData childData = new ChartData();
                childData.ProjectId = proj.Name;
                childData.ProjectName = proj.Name + ' - ' + proj.Summary__c;

                if(proj.ProjectStatus__c == 'In Queue'){
                    projectStartDate = getNextIterationStart(Date.today());
                }
                else{
                    projectStartDate = Date.today();  // need to pass this in for existing projects
                }
                //get number of sprints
                System.debug(sprintMap);
                System.debug(proj.T_Shirt__c);
                Project_Sprint_Size__c sprint =  sprintMap.get(proj.T_Shirt__c);
                sprintLength = sprint.Estimate__c.round(System.RoundingMode.CEILING);

                projectEndDate = getIterationEndDate(sprintLength,projectStartDate);

                childData.StartDateDay = projectStartDate.day();
                childData.StartDateMonth = projectStartDate.month();
                childData.StartDateYear = projectStartDate.year();
                childData.EndDateDay = projectEndDate.day();
                childData.EndDateMonth = projectEndDate.month();
                childData.EndDateYear = projectEndDate.year();
                childData.DurationDays = null;
                childData.PercentComplete = proj.Story_Point_Percentage_Complete__c;
                childData.Dependency = program;
                childData.Type = proj.Team__c;
                dataList.add(childData);
            }
        }
        //begin iterating through the list by team assign based on capacity
        return dataList;
    }

    public date getIterationEndDate(long iterations, date startDate){

        Date projectEndDate;
        //calculate the project end date
        projectEndDate = startDate.addDays(iterations.intValue() * 21);  // jump ahead to the estimated completion date
        //go get the actual sprint end date
        TFSSprintDate__c actualSprintEnd =   [Select Name, Start_Date__c, End_Date__c from TFSSprintDate__c where Start_Date__c >=  :projectEndDate order by Start_Date__c LIMIT 1];
        if (actualSprintEnd != null)
        {
            projectEndDate = actualSprintEnd.End_Date__c;
        }
        return projectEndDate;
    }

    public date getNextIterationStart(date startDate)
    {
        //need to update this with logic for team capacity

        List<TFSSprintDate__c> lstIterations =   [Select Name, Start_Date__c, End_Date__c from TFSSprintDate__c where Start_Date__c <=  :startDate  and  End_Date__c  >  :startDate];
        if (lstIterations.size() == 1)
        {
            TFSSprintDate__c iteration =  lstIterations.get(0);
            return iteration.Start_Date__c;
        }
        else {
            return Date.today();  //need to pick a better default
        }
    }

}
