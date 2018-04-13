public class ESManageConsole {

    public List<sObject> queryTeamResult {get; set;} // use the proper type
    public List<sObject> queryProjectsResult {get; set;}
    public List<sObject> queryPrevQProjectsResult {get; set;}
    public List<sObject> queryScoreProjectsResult {get; set;}
    public List<sObject> queryOppNotesResult {get; set;}
    public List<sObject> queryProjNotesResult {get; set;}
    public List<sObject> queryParentProjNotesResult {get; set;}
    public String resultProjectString {get; set;}
    public String resultTeamString {get; set;}
    public String resultScoreProjectsString {get; set;}
    public String resultStringOppNotes {get; set;}
    public String resultStringProjNotes {get; set;}
    public String resultStringParentProjNotes {get; set;}
    public String oppId {get; set;}
    public String projId {get; set;}
    public String teamId {get; set;}
    public String pProjId {get; set;}
    public String userId {get; set;}
    public String colorHex {get; set;}
    public String projectHistory {get; set;}
    public String userProjectHistory {get; set;}
    public decimal percentComplete {get; set;}
    public decimal assetCount {get; set;}
    public decimal projComplexity {get; set;}


    public ESManageConsole() {
        Id userid = UserInfo.getUserId();
        String fName = UserInfo.getFirstName();
        String lName = UserInfo.getLastName();
        queryTeamResult = [SELECT FirstName, LastName, Name, Id, Title, ES_Project_Quarter_Goal__c, ES_User_Color__c, ES_Project_History__c FROM User WHERE Team__c = 'Expert Services' AND (NOT Title like '%Supervisor%') AND (NOT  Title like '%Team Lead%') AND (NOT Title like '%Manager Professional Services%') AND (NOT Title like '%Director%') AND IsActive = true ORDER BY NAME Limit 50];
        queryProjectsResult = [SELECT Phase_Status__c, ES_Project_Completion_History__c, Account__r.Name, Name, Opportunity__r.Id, Opportunity__r.Name, Days_to_Go_Live__c, PercentComplete__c, Team__c, ES_AssetCount__c, ES_ProjectComplexity__c, Project_Score__c, ProjectStatus__c, Id, OwnerId, Summary__c, Owner.Name FROM Project__c WHERE Team__c = 'Expert Services' AND ((Phase_Status__c NOT IN('Closed','Complete','Completed','Cancelled','Canceled','Deployed') AND ProjectStatus__c NOT IN('Closed','Complete','Completed','Cancelled','Canceled','Deployed')) OR ActualProjectGoLiveDate__c = THIS_QUARTER) Limit 500];
        queryPrevQProjectsResult = [SELECT Phase_Status__c, ES_Project_Completion_History__c, Account__r.Name, Name, Opportunity__r.Id, Opportunity__r.Name, Days_to_Go_Live__c, PercentComplete__c, Team__c, ES_AssetCount__c, ES_ProjectComplexity__c, Project_Score__c, ProjectStatus__c, Id, OwnerId, Summary__c FROM Project__c WHERE Team__c = 'Expert Services' AND ClosedDate__c = LAST_QUARTER];
        resultTeamString = JSON.serialize(queryTeamResult);
        resultProjectString = JSON.serialize(queryProjectsResult);
        resultTeamString = resultTeamString.replace('\'','singleQuoteStringReplace');
        resultProjectString = resultProjectString.replace('\'','singleQuoteStringReplace');
    }

    public PageReference getScorableProjectsMethod() {
        queryScoreProjectsResult = [SELECT ES_AssetCount__c, Account__r.Name, ES_ProjectComplexity__c, Project_Score__c, Id, Name, Owner.Id, Owner.Name, ES_Project_Scored__c, Summary__c, Opportunity__r.Id, Opportunity__r.Name, ParentProject__r.Opportunity__c, ParentProject__c FROM Project__c WHERE Team__c = 'Expert Services' AND ES_Project_Scored__c = False AND Phase_Status__c NOT IN('Closed','Complete','Completed','Cancelled','Canceled','Deployed') AND ProjectStatus__c NOT IN('Closed','Complete','Completed','Cancelled','Canceled','Deployed') Limit 250];
        resultScoreProjectsString = JSON.serialize(queryScoreProjectsResult);
        resultScoreProjectsString = resultScoreProjectsString.replace('\'','singleQuoteStringReplace');
        return null;
    }

    public PageReference projectScoreMethod() {
        Project__c projectScoreUpdate = [SELECT Id FROM Project__c WHERE Id= : projId Limit 1];
        projectScoreUpdate.ES_AssetCount__c = assetCount;
        projectScoreUpdate.ES_ProjectComplexity__c = projComplexity;
        projectScoreUpdate.ES_Project_Scored__c = True;
        update projectScoreUpdate;
        return null;
    }

    public PageReference getProjNotesMethod() {
        queryProjNotesResult = [Select Id, Title, Body, CreatedDate, Parent.Name From Note Where ParentId = : projId Order By CreatedDate DESC Limit 100];
        resultStringProjNotes = JSON.serialize(queryProjNotesResult);
        resultStringProjNotes = resultStringProjNotes.replace('\'','singleQuoteStringReplace');
        return null;
    }

    public PageReference getOppNotesMethod() {
        queryOppNotesResult = [Select Id, Title, Body, CreatedDate, Parent.Name From Note Where ParentId = : oppId Order By CreatedDate DESC Limit 100];
        resultStringOppNotes = JSON.serialize(queryOppNotesResult);
        resultStringOppNotes = resultStringOppNotes.replace('\'','singleQuoteStringReplace');
        return null;
    }

    public PageReference getParentProjNotesMethod() {
        queryParentProjNotesResult = [Select Id, Title, Body, CreatedDate, Parent.Name From Note Where ParentId = : pProjId Order By CreatedDate DESC Limit 100];
        resultStringParentProjNotes = JSON.serialize(queryParentProjNotesResult);
        resultStringParentProjNotes = resultStringParentProjNotes.replace('\'','singleQuoteStringReplace');
        return null;
    }

    public PageReference userColorMethod(){
        User userColorUpdate = [SELECT Id FROM User WHERE Id= : userId Limit 1];
        userColorUpdate.ES_User_Color__c = colorHex;
        update userColorUpdate;
        return null;
    }

    public PageReference projectHistoryMethod(){
        Project__c projectHistoryUpdate = [SELECT Id FROM Project__c WHERE Id= : projId Limit 1];
        projectHistoryUpdate.ES_Project_Completion_History__c = projectHistory;
        projectHistoryUpdate.ES_PrevQ_PercentComplete__c = percentComplete;
        update projectHistoryUpdate;
        return null;
    }

    public PageReference userProjectHistoryMethod(){
        User userProjectHistoryUpdate = [SELECT Id FROM User WHERE Id= : teamId Limit 1];
        userProjectHistoryUpdate.ES_Project_History__c = userProjectHistory;
        update userProjectHistoryUpdate;
        return null;
    }
}