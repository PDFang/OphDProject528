/**
 * Created by arnab.karsarkar on 2/6/2017.
 */

public with sharing class GanttProjectPriotizationListController {

    public boolean hasEditAccess {get; set;}
    public list<SelectOption> filterOptions {get; set;}
    public string selectValue { get;set; }
    public string defaultTeam { get;set; }
    public  boolean showUnlock{get; set;}
    public integer sessionTimeoutTime{get;set;}
    public string projectType{get;set;}

    static final Map<String, String> recordTypeMap = new Map<String, String>{
            'PMO' => 'PMO Project',
            'IT' => 'IT Project Request'
    };

    public GanttProjectPriotizationListController(){

        sessionTimeoutTime = integer.valueOf(Label.SessionTimeOutTime) / (1000* 60);
        projectType = 'PMO';
        //projectType = 'IT';
        Schema.DescribeFieldResult developmentTeam = Project__c.Development_Team__c.getDescribe();
        if(developmentTeam.getDefaultValue() != null){
            defaultTeam = (String)developmentTeam.getDefaultValue();
        } else{
            defaultTeam = Project__c.Development_Team__c.getDescribe().getPicklistValues()[0].getValue();
        }

        initFilter();

    }

    public void initFilter(){

        if(projectType == 'PMO'){
            GetAvailablePrograms();
            selectValue = 'Global';
        } else{
            GetAvailableTeams();
            selectValue = defaultTeam;
        }
        checkAccess(selectValue);
        checkUnlockEdit(selectValue);

    }


    public void editAccessCheck()
    {
        String programName = Apexpages.currentPage().getParameters().get('programName');
        system.debug('programName =>' + programName);
        checkAccess(programName);
        checkUnlockEdit(programName);
    }

    private void checkUnlockEdit(string programName){
        showUnlock = false;
        system.debug('sessionTimeoutTime =>' + sessionTimeoutTime);
        string query = 'select count() from Project_Prioritization_History__c ' +
                ' where CreatedById = \'' + UserInfo.getUserId() + '\' and Channel__c = :programName and TimeElapsed__c < :sessionTimeoutTime Limit 1';

        integer count = Database.countQuery(query);
        if(count > 0)
            showUnlock = true;
    }

    private void checkAccess(string priorityType){
        hasEditAccess = false;

        Set<String> channels = new Set<String>();
        if(projectType == 'IT'){
            channels.add('All');
        }
        channels.add(priorityType);

        Set<String> CustomPermissionNames = new Set<String>();

        for(ProgramChannelPermissionMap__mdt mapping : [SELECT CustomPermissions__c, ProgramChannel__c
                    FROM ProgramChannelPermissionMap__mdt
                    WHERE ProgramChannel__c IN :channels
        ]){
            CustomPermissionNames.add(mapping.CustomPermissions__c);
        }

        Set<String> customPermissionsForCurrentUser = new Set<String>();

        // Query the full set of Custom Permissions for the given namespace
        Map<Id, String> customPermissionNamesById = new Map<Id, String>();
        List<CustomPermission> customPermissions = [select Id, DeveloperName from CustomPermission where DeveloperName IN :CustomPermissionNames];
        for(CustomPermission customPermission : customPermissions) {
            customPermissionNamesById.put(customPermission.Id, customPermission.DeveloperName);
        }

        // Query to determine which of these custome settings are assigned to this user
        List<SetupEntityAccess> setupEntities =
        [SELECT SetupEntityId
        FROM SetupEntityAccess
        WHERE SetupEntityId in :customPermissionNamesById.keySet() AND
        ParentId IN (SELECT PermissionSetId
        FROM PermissionSetAssignment
        WHERE AssigneeId = :UserInfo.getUserId())];
        for(SetupEntityAccess setupEntity : setupEntities){
            system.debug('expected custom permission name =>' + customPermissionNamesById.get(setupEntity.SetupEntityId));
            customPermissionsForCurrentUser.add(customPermissionNamesById.get(setupEntity.SetupEntityId));
        }

        system.debug('original custom permission name =>' + CustomPermissionNames);
        for(String permissionName : CustomPermissionNames){
            if(customPermissionsForCurrentUser.contains(permissionName))
                hasEditAccess = true;
        }

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

    private list<SelectOption> GetAvailableTeams()
    {
        Schema.DescribeFieldResult FilterFieldDescription = Project__c.Development_Team__c.getDescribe();

        filterOptions = new list<SelectOption>();

        for (Schema.Picklistentry picklistEntry : FilterFieldDescription.getPicklistValues())
        {
            filterOptions.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
        }

        return filterOptions;
    }

    @RemoteAction
    public static string GetUnpriortizedProjects(string filterByValue, string projectType){

        String projectRecordType = recordTypeMap.containsKey(projectType) ? recordTypeMap.get(projectType) : 'NULL';
        list<ProjectListDataFields> dataList = new list<ProjectListDataFields>();

        string priorityField = (projectType == 'PMO' && filterByValue == 'Global') ? 'BattingOrder__c' : 'Ops_Backlog_Priority__c';

        string filterByField = (projectType == 'PMO') ? 'Primary_Product__c' : 'Development_Team__c';

        string queryProjects = 'Select Id, Name, ProjectStatus__c,CreatedDate, Ops_Backlog_Priority__c,BattingOrder__c , Summary__c, RequestedDeliveryDate__c, ExpectedDeliveryDate__c, ProjectOwner__r.Name, '
                + ' ProjectType__c,Complete__c,  Primary_Product__c, Delivery_Channel__c, Request_Channel__c, RecordType.Name, ParentGlobalPriority__c From Project__c where Primary_Product__c != null '
                + ' and  RecordType.Name = \'' + projectRecordType + '\'  and ProjectStatus__c not in (\'Completed\',\'Closed\',\'Canceled\') and ProjectType__c != \'Time Keeping\' '
                + ' and (' + priorityField + ' = null OR ' +  priorityField + ' = 0)';

        if(filterByValue != 'Global' && filterByValue != 'All')
            queryProjects += ' and ' + filterByField + ' =: filterByValue';

        queryProjects += '  order by CreatedDate desc';

        List<Project__c> projectLists =  Database.query(queryProjects);

        for(Project__c proj : projectLists){
            ProjectListDataFields childData = new ProjectListDataFields();
            childData.ProjectId = proj.Id;
            childData.ProjectName = proj.Name + ' - ' + proj.Summary__c;
            childData.RecordTypeName = proj.RecordType.Name;
            childData.ProjectSummary =  proj.Summary__c;
            childData.ProjectStatus = proj.ProjectStatus__c;

            childData.CreatedDate = Date.valueOf(proj.CreatedDate);
            if(projectType == 'PMO') {
                if (filterByValue == 'Global') {
                    childData.Priority = proj.BattingOrder__c;
                    childData.ProductChannel = proj.Primary_Product__c;
                    childData.OtherPriority = proj.Ops_Backlog_Priority__c;
                } else {
                    childData.Priority = proj.Ops_Backlog_Priority__c;
                    childData.OtherPriority = proj.BattingOrder__c;
                }
            } else{
                childData.Priority = proj.Ops_Backlog_Priority__c;
                childData.OtherPriority = proj.ParentGlobalPriority__c;
            }
            childData.isPriorityMismatch = false;
            childData.ExpectedDeliveryDate = GetformattedDate(proj.ExpectedDeliveryDate__c);
            childData.RequestedDeliveryDate = GetformattedDate(proj.RequestedDeliveryDate__c);
            childData.ProjectOwner = proj.ProjectOwner__r.Name;
            childData.ProjectType = proj.ProjectType__c;
            childData.DeliveryChannel = proj.Delivery_Channel__c;
            childData.RequestChannel = proj.Request_Channel__c;
            dataList.add(childData);
        }

        return JSON.serialize(dataList);

    }

    @RemoteAction
    public static string GetPriortizedProjects(string filterByValue, string projectType){

        String projectRecordType = recordTypeMap.containsKey(projectType) ? recordTypeMap.get(projectType) : 'NULL';
        list<ProjectListDataFields> dataList = new list<ProjectListDataFields>();

        string priorityField = (projectType == 'PMO' && filterByValue == 'Global') ? 'BattingOrder__c' : 'Ops_Backlog_Priority__c';

        string filterByField = (projectType == 'PMO') ? 'Primary_Product__c' : 'Development_Team__c';

        string queryProjects = 'Select Id, Name, ProjectStatus__c, BattingOrder__c, Ops_Backlog_Priority__c, Summary__c, RequestedDeliveryDate__c, ExpectedDeliveryDate__c, ProjectOwner__r.Name, '
                + ' ProjectType__c,Complete__c, Primary_Product__c,Delivery_Channel__c, Request_Channel__c, RecordType.Name, ParentGlobalPriority__c  From Project__c where Primary_Product__c != null '
                + ' and  RecordType.Name = \'' + projectRecordType + '\'  and ProjectStatus__c not in (\'Completed\',\'Closed\',\'Canceled\') and ProjectType__c != \'Time Keeping\' '
                + ' and (' + priorityField + ' != null AND ' +  priorityField + ' != 0)';

        if(filterByValue != 'Global' && filterByValue != 'All')
            queryProjects += ' and ' + filterByField + ' = :filterByValue';

        queryProjects += '  order by ' + priorityField;

        List<Project__c> projectLists =  Database.query(queryProjects);
        integer i = 0;
        for(Project__c proj : projectLists){
            i++;
            ProjectListDataFields childData = new ProjectListDataFields();
            childData.ProjectId = proj.Id;
            childData.ProjectName = proj.Name + ' - ' + proj.Summary__c;
            childData.RecordTypeName = proj.RecordType.Name;
            childData.ProjectSummary =  proj.Summary__c;
            childData.ProjectStatus = proj.ProjectStatus__c;

            if(projectType == 'PMO' && filterByValue == 'Global'){
                if(i != proj.BattingOrder__c){
                    childData.Priority =  i;
                    childData.isPriorityMismatch = true;
                }else{
                    childData.Priority =  proj.BattingOrder__c;
                    childData.isPriorityMismatch = false;
                }

                childData.ProductChannel = proj.Primary_Product__c;
                childData.OtherPriority =  proj.Ops_Backlog_Priority__c;
            }
            else{
                if(i != proj.Ops_Backlog_Priority__c){
                    childData.Priority =  i;
                    childData.isPriorityMismatch = true;
                }else{
                    childData.Priority =  proj.Ops_Backlog_Priority__c;
                    childData.isPriorityMismatch = false;
                }
                childData.OtherPriority =  (projectType == 'PMO') ? proj.BattingOrder__c : proj.ParentGlobalPriority__c;
            }

            childData.ExpectedDeliveryDate = GetformattedDate(proj.ExpectedDeliveryDate__c);
            childData.RequestedDeliveryDate = GetformattedDate(proj.RequestedDeliveryDate__c);
            childData.ProjectOwner = proj.ProjectOwner__r.Name;
            childData.PercentComplete = proj.Complete__c;
            childData.ProjectType = proj.ProjectType__c;
            childData.DeliveryChannel = proj.Delivery_Channel__c;
            childData.RequestChannel = proj.Request_Channel__c;

            dataList.add(childData);
        }

        return JSON.serialize(dataList);

    }

    @RemoteAction
    public static string ValidateEdit(string priorityType){

        string response = '';
        integer sessiontime = integer.valueOf(Label.SessionTimeOutTime)  / (1000* 60);
        Project_Prioritization_History__c[] history  = [select CreatedById, CreatedBy.Name
        from Project_Prioritization_History__c
        where Channel__c = :priorityType
        and TimeElapsed__c < :sessiontime order by CreatedDate desc];

        if(history.size() > 0 && history[0].CreatedById == UserInfo.getUserId()){
            response = history[0].Id;
        }
        else if(history.size() > 0){
            response = 'You cannot edit the grid now for this Program; ' + history[0].CreatedBy.Name + ' is editting the same Program.';
        }
        else{
            Project_Prioritization_History__c newHistory = new Project_Prioritization_History__c(
                    Channel__c = priorityType
            );
            insert newHistory;
            response = newHistory.Id;

        }

        return response;
    }

    @RemoteAction
    public static void CancelEdit(string historyId){
        deleteHistory(historyId);

    }

    @RemoteAction
    public static void ContinueSession(string historyId){
        Project_Prioritization_History__c newHistory = new Project_Prioritization_History__c(
                Id = historyId
        );
        update newHistory;

    }

    private static void deleteHistory(string historyId){
        if(historyId != null){
            Project_Prioritization_History__c newHistory = new Project_Prioritization_History__c(
                    Id = historyId
            );
            delete newHistory;
        }

    }

    @RemoteAction
    public static void UnlockEdit(string priorityType){
        Project_Prioritization_History__c[] history  = [select Id
        from Project_Prioritization_History__c
        where Channel__c = :priorityType
        and CreatedById = :UserInfo.getUserId()
        order by CreatedDate desc];
        delete history;
    }


    @RemoteAction
    public static string Save(string changedProjects, string priorityType, string historyId ){
        system.debug('projects JSON => ' + changedProjects);
        integer sessiontime = integer.valueOf(Label.SessionTimeOutTime) / (1000* 60);
        if([select count()
        from Project_Prioritization_History__c
        where Channel__c = :priorityType
        and CreatedById = :UserInfo.getUserId()
        and  TimeElapsed__c < :sessiontime] > 0)
        {
            map<string, decimal> projectlists = new map<string, decimal>();
            list<Project__c> updateProjectLists = new list<Project__c>();
            Id jobId;
            JSONParser parser = JSON.createParser(changedProjects);
            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    ChangedProject cp = (ChangedProject)parser.readValueAs(ChangedProject.class);

                    Project__c proj = new Project__c(Id = cp.ProjectId);
                    if(cp.RecordTypeName == 'PMO Project' && priorityType == 'Global'){
                        proj.BattingOrder__c = cp.Priority;
                    }
                    else{
                        proj.Ops_Backlog_Priority__c = cp.Priority;
                    }

                    updateProjectLists.add(proj);
                }
            }

            try{

                datetime qryStart = datetime.now();

                TriggerHandler.bypass('ProjectTriggerHandler');

                system.debug('**** updateProjectLists - ' + updateProjectLists);

                if(updateProjectLists.size() > 0)
                    update updateProjectLists;
                // enqueue the sort Job
                sortITProjects();

                deleteHistory(historyId);

                TriggerHandler.clearBypass('ProjectTriggerHandler');
                datetime qryEnd = datetime.now();

                system.debug(logginglevel.WARN, (qryEnd.getTime() - qryStart.getTime()) /1000);
                return null;

            }
            catch(Exception ex){
                string errString = 'Unexpected Error Occured : ' + ex.getMessage() + ' at line ' + ex.getLineNumber();
                return errString;
            }
        }
        else{
            string errString = 'Your Session has expired, no changes were saved. Please hit cancel or reload the page';
            return errString;
        }

        return null;
    }


    private static string GetformattedDate(date dt){
        if(dt != null)
        {
            integer month = dt.month();
            integer day = dt.day();
            integer year = dt.year();

            string formattedDate = month + '/' + day + '/' + year;

            return formattedDate;
        }

        return null;

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
            proj.SyncToTFS__c = false;
        }
        system.debug('** SortITProject => ' + ITProjects.size());

        if(ITProjects.size() > 0){
            ProjectTriggerHandler.lockSortingFields = false;
            update ITProjects;
        }

    }

    public class ChangedProject{
        public String ProjectId ;
        public decimal Priority ;
        public String RecordTypeName;
    }


}