public class ESConsole {

    public List<sObject> queryResult {get; set;} // use the proper type
    public List<sObject> queryTeamResult {get; set;}
    public List<sObject> queryNotesResult {get; set;}
    public List<sObject> newQueryResult {get; set;}
    public List<sObject> queryAttachmentsResult {get; set;}
    public String resultString {get; set;}
    public String resultStringNotes {get; set;}
    public String resultTeamString {get; set;}
    public String resultStringAttachments {get; set;}
    public String projId {get; set;}
    public String fieldName {get; set;}
    public String noteBody {get; set;}
    public String noteTitle {get; set;}
    public String colorHex {get; set;}
    public String estimatedGoLive {get; set;}
    public String userWallpaper {get; set;}
    public Integer i {get; set;}
    public String attachmentId {get; set;}
    public String downloadId {get; set;}
    public Decimal percentVal {get; set;}
    public string fileName {get; set;}
    public string fileBody {get; set;}


    public ESConsole() {
        Id userid = UserInfo.getUserId();
        String fName = UserInfo.getFirstName();
        String lName = UserInfo.getLastName();
        queryResult = [SELECT Name, TotalWorkLogHours__c, ES_AssetCount__c, ES_ProjectComplexity__c, Project_Score__c, ImplementationConsultant__r.name, Phase_Status__c, ES_Project_Color__c, ProjectStatus__c, EstimatedProjectGoLiveDate__c, Account__r.Name, Account__r.inContact_Cluster__c, Account__r.Id, Id, Days_to_Go_Live__c, OwnerId, Summary__c, ES_PrevQ_PercentComplete__c, PercentComplete__c, RecordType.Name FROM Project__c WHERE ((Phase_Status__c NOT IN('Closed','Complete','Completed','Cancelled','Canceled','Deployed') AND ProjectStatus__c NOT IN('Closed','Complete','Completed','Cancelled','Canceled','Deployed')) OR ((Phase_Status__c IN ('Closed','Complete','Completed','Deployed') OR ProjectStatus__c IN ('Closed','Complete','Completed','Deployed')) AND ClosedDate__c = THIS_QUARTER)) AND OwnerId = : userid Limit 100];
        queryTeamResult = [SELECT Phase_Status__c, Team__c, ES_AssetCount__c, ES_ProjectComplexity__c, Project_Score__c, ProjectStatus__c, Id, OwnerId, ES_PrevQ_PercentComplete__c, PercentComplete__c FROM Project__c WHERE Team__c = 'Expert Services' AND ((Phase_Status__c NOT IN ('Closed','Complete','Completed','Cancelled','Canceled','Suspended','On Hold') AND ProjectStatus__c NOT IN ('Closed','Complete','Completed','Cancelled','Canceled','Suspended','On Hold')) OR ClosedDate__c = THIS_QUARTER) Limit 500];

        resultString = JSON.serialize(queryResult);
        resultTeamString = JSON.serialize(queryTeamResult);
        resultString = resultString.replace('\'','singleQuoteStringReplace');
        resultTeamString = resultTeamString.replace('\'','singleQuoteStringReplace');

        userWallpaper = 'esDashboard' + fName + lName;
    }

    public PageReference phaseStatusMethod(){
        Project__c phaseStatusUpdate = [SELECT Id FROM Project__c WHERE Id= : projId Limit 1];
        phaseStatusUpdate.phase_status__c = fieldName;
        phaseStatusUpdate.ProjectStatus__c = fieldName;
        phaseStatusUpdate.Team__c = 'Expert Services';
        update phaseStatusUpdate;
        return null;
    }

    public PageReference insertNotesMethod(){
        note n = new note();
        n.parentId = projId; //Id of the opportunity for which you want to add this note
        n.body = noteBody; // body of the note. this should be populated from the notes field that you have shown in the screenshot
        n.title= noteTitle; // the title of the note
        n.isPrivate=false;  // if private it will be visible only for the owner and any user with modify all permission
        insert n; //insert the record
        return null;
    }

    public PageReference getNotesMethod() {
        queryNotesResult = [Select Id, Title, Body, CreatedDate From Note Where ParentId = : projId Order By CreatedDate DESC Limit 100];

        resultStringNotes = JSON.serialize(queryNotesResult);
        resultStringNotes = resultStringNotes.replace('\'','singleQuoteStringReplace');
        return null;
    }

    public PageReference percentCompleteMethod(){
        Project__c percentCompleteUpdate = [SELECT Id FROM Project__c WHERE Id= : projId Limit 1];
        percentCompleteUpdate.PercentComplete__c = percentVal;
        update percentCompleteUpdate;
        return null;
    }

    public PageReference projectColorMethod(){
        Project__c projectColorUpdate = [SELECT Id FROM Project__c WHERE Id= : projId Limit 1];
        projectColorUpdate.ES_Project_Color__c = colorHex;
        update projectColorUpdate;
        return null;
    }

    public PageReference projectCompleteMethod(){
        Project__c projectComplete = [SELECT Id FROM Project__c WHERE Id= : projId Limit 1];
        projectComplete.Phase_Status__c = 'Closed';
        projectComplete.ProjectStatus__c = 'Completed';
        projectComplete.PercentComplete__C = 100;
        projectComplete.ActualProjectGoLiveDate__c = Date.today();
        update projectComplete;
        return null;
    }

    public PageReference projectScoreMethod() {
        Project__c projectScoreUpdate = [SELECT Id FROM Project__c WHERE Id= : projId Limit 1];
        projectScoreUpdate.ES_Project_Scored__c = False;
        update projectScoreUpdate;
        return null;
    }

    public PageReference estimatedGoLiveMethod() {
        Project__c projectEstGoLiveUpdate = [SELECT Id FROM Project__c WHERE Id= : projId Limit 1];
        date estGoLive = date.valueOf(estimatedGoLive);
        projectEstGoLiveUpdate.EstimatedProjectGoLiveDate__c = estGoLive;
        update projectEstGoLiveUpdate;
        return null;
    }

    public pageReference getAttachmentsMethod(){
        queryAttachmentsResult = [SELECT Id, BodyLength, Name, ParentId From Attachment Where ParentId = : projId Limit 100];
        resultStringAttachments = JSON.serialize(queryAttachmentsResult);
        return null;
    }

    public PageReference uploadFileMethod(){
        Attachment myAttachment  = new Attachment();
        myAttachment.Body = Blob.valueOf(fileBody);
        myAttachment.Name = fileName;
        myAttachment.ParentId = projId;
        insert myAttachment;
        fileBody = '';
        return null;
    }
}