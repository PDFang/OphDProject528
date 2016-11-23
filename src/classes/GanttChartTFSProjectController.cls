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

    //Comments

    public GanttChartTFSProjectController(){
        loadPrograms();
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



    public void loadPrograms()
    {
        programs = new list<SelectOption>();
        programs.add(new SelectOption('All', 'All'));
        TeamLists  = new list<SelectOption>();
        selectedTeams = new list<string>();

        Schema.DescribeFieldResult fieldResultPrograms = Project__c.Primary_Product__c.getDescribe();
        List<Schema.PicklistEntry> plePrograms = fieldResultPrograms.getPicklistValues();

        for( Schema.PicklistEntry f : plePrograms)
        {
            programs.add(new SelectOption(f.getLabel(), f.getValue()));
        }

        Schema.DescribeFieldResult fieldResult = ISTFSWorkItem__c.Team__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple)
        {
            TeamLists.add(new SelectOption(f.getLabel(), f.getValue()));
            selectedTeams.add(f.getLabel());
        }
    }

    @RemoteAction
    public static List<TFSSprintDate__c> GetIterationsForPeriod(Date startDate, Date endDate)
    {
        GanttChartTFSProjectHelper helper = new GanttChartTFSProjectHelper();
        return helper.GetIterationList(startDate, endDate);
    }

    @RemoteAction
    public static TimeLineData getChartData(string programName, list<string> TeamName)
    {

        TimeLineData timeline = new  TimeLineData();
        List<RelatedProject__c> rpChildList = new list<RelatedProject__c>();
        list<ChartData> dataList = new list<ChartData>();
        map<string, list<Project__c>> parentProjects = new map<string, list<Project__c>>();
        list<Project__c> lstProjects  = new list<Project__c>();
        map<string, list<date>> minStartDtList = new map<string, list<date>>();
        map<string, date> minStartDt = new map<string, date>();
        map<string, date> maxEndDt = new map<string, date>();
        map<string, date> projectStartDate = new map<string, date>();

        set<string> stProjectIds = new set<string>();


        string queryString = 'select Name, Primary_Product__c,Team__c, Summary__c,RequestedDeliveryDate__c, PercentComplete__c from Project__c Where ProjectStatus__c = \'Active/Being Worked\' and RecordType.Name = \'IT Project Request\' ';
        if(programName != '')
            queryString +=  ' And Primary_Product__c = :programName';
        else
                queryString +=  ' And Primary_Product__c != null';

        if(TeamName.size() > 0)
            queryString += ' And Team__c in :TeamName';

        queryString += ' Order By Name';

        lstProjects = Database.query(queryString);

        for(Project__c proj :lstProjects)
        {
            stProjectIds.add(proj.Id);
            if(parentProjects.containsKey(proj.Primary_Product__c))
            {
                parentProjects.get(proj.Primary_Product__c).add(proj);
            }
            else
            {
                parentProjects.put(proj.Primary_Product__c, new list<Project__c>{proj});
            }

        }

        for(AggregateResult agr : [select Primary_Product__c, MAX(RequestedDeliveryDate__c)  maxDt
        FROM Project__c where  ProjectStatus__c in ('Active/Being Worked', 'In Queue', 'Ready to Deploy')
        And RecordType.Name = 'IT Project Request'
        AND Primary_Product__c != null
        Group By Primary_Product__c])
        {
            if(programName != '' &&   string.valueOf(agr.get('Primary_Product__c')) == programName)
            {
                maxEndDt.put(programName, date.valueOf(agr.get('maxDt')));
                break;
            }
            else
            {
                string program = string.valueOf(agr.get('Primary_Product__c'));
                maxEndDt.put(string.valueOf(program), date.valueOf(agr.get('maxDt')));
            }
        }



        for(Project__history projHist : [select Parent.Primary_Product__c, NewValue, CreatedDate
        FROM Project__history where  Parent.ProjectStatus__c = 'Active/Being Worked'
        And Parent.RecordType.Name = 'IT Project Request'
        AND Parent.Primary_Product__c != null
        Order By CreatedDate desc])
        {
            date thisCreatedDate = Date.valueOf(projHist.CreatedDate);
            if(programName != '' &&   projHist.Parent.Primary_Product__c == programName && projHist.NewValue == 'Active/Being Worked')
            {
                minStartDtList.put(programName, new list<date>{thisCreatedDate});
            }
            else if(projHist.NewValue == 'Active/Being Worked' && programName == '')
            {
                if(!minStartDtList.containsKey(projHist.Parent.Primary_Product__c))
                {
                    minStartDtList.put(projHist.Parent.Primary_Product__c, new list<date>{thisCreatedDate});
                }
                else{
                    system.debug('program ==>' + projHist.Parent.Primary_Product__c);
                    minStartDtList.get(projHist.Parent.Primary_Product__c).add(thisCreatedDate);
                }

            }
        }

        for(string program : minStartDtList.keySet())
        {
            list<date> lstCreatedDates = new list<date>();
            lstCreatedDates = minStartDtList.get(program);
            lstCreatedDates.sort();
            date maxDate = lstCreatedDates[lstCreatedDates.size() - 1];
            minStartDt.put(program, maxDate);
        }

        for(Project__history hist : [select ParentId, NewValue, CreatedDate from Project__history where  Parent.ProjectStatus__c = 'Active/Being Worked'
        And Parent.RecordType.Name = 'IT Project Request'
        AND Parent.Primary_Product__c != null
        ])
        {
            if(hist.NewValue == 'Active/Being Worked')
                projectStartDate.put(hist.ParentId, Date.valueOf(hist.CreatedDate));
        }


        for(String program : parentProjects.keySet())
        {


           /** ChartData data = new ChartData();
            data.ProjectId = program;
            data.ProjectName = 'Program = ' + program;
            data.StartDateDay = minStartDt.get(program).day();
            data.StartDateMonth =minStartDt.get(program).month() - 1;
            data.StartDateYear = minStartDt.get(program).year();
            data.EndDateDay = maxEndDt.get(program).day();
            data.EndDateMonth =maxEndDt.get(program).month() - 1;
            data.EndDateYear = maxEndDt.get(program).year();
            data.DurationDays = 90;
            data.PercentComplete = 80;
            data.Dependency = program;
            data.Type = 'Program';
            dataList.add(data); **/


            for(Project__c proj : parentProjects.get(program))
            {
                ChartData childData = new ChartData();
                childData.ProjectId = proj.Name;
                childData.ProjectName = proj.Name + ' - ' +  proj.Summary__c;
                childData.StartDateDay = projectStartDate.get(proj.Id).day();
                childData.StartDateMonth = projectStartDate.get(proj.Id).month() - 1;
                childData.StartDateYear = projectStartDate.get(proj.Id).year();
                childData.EndDateDay = proj.RequestedDeliveryDate__c.day();
                childData.EndDateMonth = proj.RequestedDeliveryDate__c.month() - 1;
                childData.EndDateYear = proj.RequestedDeliveryDate__c.year();
                childData.DurationDays = null;
                childData.PercentComplete = 50;
                childData.Dependency = program;
                childData.Type = proj.Team__c;
                dataList.add(childData);

            }

        }

        timeline.lstChartData = dataList;
        date startDate = date.today();
        date endDate = date.today().addDays(180);
        timeline.lstSprintData = GetIterationsForPeriod(startDate, endDate);

        return timeline;
    }


    public class TimeLineData
    {
          List<ChartData>  lstChartData;
          List<TFSSprintDate__c>  lstSprintData;
    }



    public class ChartData
    {
        public string  ProjectId {get; set;}
        public string  ProjectName {get; set;}
        public integer  StartDateDay{get; set;}
        public integer  StartDateMonth{get; set;}
        public integer  StartDateYear{get; set;}
        public integer  EndDateDay{get; set;}
        public integer  EndDateMonth{get; set;}
        public integer  EndDateYear{get; set;}
        public integer DurationDays{get; set;}
        public decimal PercentComplete{get; set;}
        public string Dependency{get;set;}
        public string Type{get;set;}
    }




}