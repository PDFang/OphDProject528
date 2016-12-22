/**
 * Created by arnab.karsarkar on 12/22/2016.
 */

@IsTest
public with sharing class GanttChartTFSProjectControllerTest {

    private static void setupData() {
        Id ITProjectRTId = [SELECT id from RecordType where Name = 'IT Project Request'].Id;
        List<Project__c> projectList = new List<Project__c>();
        Project__c parentProject1 = new Project__c(
                RecordTypeId = ITProjectRTId,
                Summary__c = 'This is the Avengers Project 1',
                ProblemStatement__c = 'A test project1',
                Development_Team__c = 'Avengers',
                BattingOrder__c = 1,
                T_Shirt__c = 'Small',
                Primary_Product__c = 'Customer Portal',
                ProjectStatus__c = 'In Queue'
        );
        projectList.add(parentProject1);
        Project__c parentProject2 = new Project__c(
                RecordTypeId = ITProjectRTId,
                Summary__c = 'This is the Justice League Project 1',
                ProblemStatement__c = 'A test project2',
                Development_Team__c = 'Justice League',
                BattingOrder__c = 1,
                T_Shirt__c = 'Small',
                Primary_Product__c = 'Employee Community',
                ProjectStatus__c = 'In Queue'
        );
        projectList.add(parentProject2);
        Project__c parentProject3 = new Project__c(
                RecordTypeId = ITProjectRTId,
                Summary__c = 'This is the X-Men Project 1',
                ProblemStatement__c = 'A test project2',
                Development_Team__c = 'Justice League',
                BattingOrder__c = 1,
                T_Shirt__c = 'Medium',
                Primary_Product__c = 'Service Delivery',
                ProjectStatus__c = 'In Queue'
        );
        projectList.add(parentProject3);

        insert projectList;



        createProjectSizeMap();
        createProjectColorMap();
        createTeamColorMap();
        createTeamSizeMap();
        sprintsDateMap();
   }

    private static void createProjectSizeMap()
    {

        list<ProjectSizeMap__c> listProjSize = new list<ProjectSizeMap__c>();
        ProjectSizeMap__c projSize = new ProjectSizeMap__c(
                Name = 'Small',
                ProjectSize__c = 'Small',
                Estimate__c = 0.33333333
            );
        listProjSize.add(projSize);
        ProjectSizeMap__c projSize2 = new ProjectSizeMap__c(
            Name = 'Medium',
            ProjectSize__c = 'Medium',
            Estimate__c = 1.000000
        );

        listProjSize.add(projSize2);
        insert listProjSize;
    }

    private static void createProjectColorMap()
    {

        list<ProgramColorMapping__c> listProgramColorMappings = new list<ProgramColorMapping__c>();
        ProgramColorMapping__c colormap1 = new ProgramColorMapping__c(
                Name = 'Customer Portal',
                Program__c = 'Customer Portal',
                FontColor__c = 'xxxxx',
                Color__c = 'xxxxx'
        );
        listProgramColorMappings.add(colormap1);
        ProgramColorMapping__c colormap2 = new ProgramColorMapping__c(
                Name = 'Employee Community',
                Program__c = 'Employee Community',
                FontColor__c = 'xxxxx',
                Color__c = 'xxxxx'
        );
        listProgramColorMappings.add(colormap2);
        ProgramColorMapping__c colormap3 = new ProgramColorMapping__c(
                Name = 'Service Delivery',
                Program__c = 'Service Delivery',
                FontColor__c = 'xxxxx',
                Color__c = 'xxxxx'
        );

        listProgramColorMappings.add(colormap3);
        insert listProgramColorMappings;
    }

    private static void createTeamColorMap()
    {

        list<TeamColorMapping__c> listTeamColorMappings = new list<TeamColorMapping__c>();
        TeamColorMapping__c colormap1 = new TeamColorMapping__c(
                Name = 'Avengers',
                Team__c = 'Avengers',
                FontColor__c = 'xxxxx',
                Color__c = 'xxxxx'
        );
        listTeamColorMappings.add(colormap1);
        TeamColorMapping__c colormap2 = new TeamColorMapping__c(
                Name = 'Justice League',
                Team__c = 'Justice League',
                FontColor__c = 'xxxxx',
                Color__c = 'xxxxx'
        );
        listTeamColorMappings.add(colormap2);
        TeamColorMapping__c colormap3 = new TeamColorMapping__c(
                Name = 'X-Men',
                Team__c = 'X-Men',
                FontColor__c = 'xxxxx',
                Color__c = 'xxxxx'
        );

        listTeamColorMappings.add(colormap3);
        insert listTeamColorMappings;
    }


    private static void createTeamSizeMap()
    {

        list<TeamSizeMap__c> listTeamSizeMappings = new list<TeamSizeMap__c>();
        TeamSizeMap__c teamSizeMap1 = new TeamSizeMap__c(
                Name = 'Avengers',
                IdealTeamSize__c =2
        );
        listTeamSizeMappings.add(teamSizeMap1);
        TeamSizeMap__c teamSizeMap2 = new TeamSizeMap__c(
                Name = 'Justice League',
                IdealTeamSize__c =2
        );
        listTeamSizeMappings.add(teamSizeMap2);
        TeamSizeMap__c teamSizeMap3 = new TeamSizeMap__c(
                Name = 'X-Men',
                IdealTeamSize__c =1
        );

        listTeamSizeMappings.add(teamSizeMap3);
        insert listTeamSizeMappings;
    }

    private static void sprintsDateMap()
    {

        list<SprintDateMap__c> sprintDateMaps = new list<SprintDateMap__c>();
        SprintDateMap__c sprint1 = new SprintDateMap__c(
                Name = '17.01',
                Sprint__c ='17.01',
                StartDate__c = Date.newInstance(2017,1,1),
                EndDate__c = Date.NewInstance(2017,1,27)
        );
        sprintDateMaps.add(sprint1);
        SprintDateMap__c sprint2 = new SprintDateMap__c(
                Name = '17.02',
                Sprint__c ='17.02',
                StartDate__c = Date.newInstance(2017,1,27),
                EndDate__c = Date.NewInstance(2017,2,17)
        );
        sprintDateMaps.add(sprint2);
        insert sprintDateMaps;
    }


    static testMethod void GantChartControllerTest()
    {
        setupData();
        List<Project__c> projectList = new List<Project__c>();
        for(Project__c proj : [select Name, ProjectStatus__c from Project__c]){
            projectList.add(new Project__c(Id = proj.Id, ProjectStatus__c = 'In Queue'));
        }
        update projectList;

        Test.startTest();
        GanttChartTFSProjectController gc = new GanttChartTFSProjectController();
        list<string> programName = new list<string>();
        list<string> TeamName = new list<string>();
        TimeLineData dataList = new TimeLineData();
        dataList = GanttChartTFSProjectController.getChartData(programName,TeamName);
        system.assertEquals(3, dataList.lstChartData.size());
        string projName = [select Name from Project__c where Development_Team__c = 'Avengers' limit 1].Name;
        GanttChartTFSProjectController.RedirectToProject(projName);
        Test.stopTest();
    }


}