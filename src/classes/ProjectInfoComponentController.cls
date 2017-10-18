/**
 * Created by ravish.chawla on 10/10/2017.
 */

public class ProjectInfoComponentController {

    public String projectId;
    public Project__c project {get; private set;}
    Static Set<String> projectFields = new Set<String>();
    List<Project__c> projects = new List<Project__c>();
    public boolean isEditEnable{get;set;}

    public String getProjectId(){
        return projectId;
    }

    public void setProjectId(String s){
        projectId = s;
        if(project == null)
            getProjectDetails();
    }

    public void getProjectDetails(){
        isEditEnable = false;
        List<Project__c> projectList = new List<Project__c>();
        system.debug('projects before projectID - ' + project);
        system.debug('projectId - ' + projectId);
        project = new Project__c();

        List<Schema.FieldSetMember> fsMembersEditable = Schema.SobjectType.Project__c.fieldSets.Project_Info_Editable.getFields();
        List<Schema.FieldSetMember> fsMembersReadOnly = Schema.SobjectType.Project__c.fieldSets.Project_Info_ReadOnly.getFields();
        for(Schema.FieldSetMember member : fsMembersEditable){
            projectFields.add(member.getFieldPath());
        }
        for(Schema.FieldSetMember member : fsMembersReadOnly){
            projectFields.add(member.getFieldPath());
        }

        List<String> fieldList = new List<String>(projectFields);

        String columns = String.join(fieldList, ',');
        system.debug('ProjectInfoComponentController(): columns - ' + columns);

        String soql = 'Select ' + columns + ' From Project__c where Id =: projectID';
        system.debug('ProjectInfoComponentController(): soql - ' + soql);

        projects = Database.query(soql);
        system.debug('projects - ' + projects);

        if(projects.size() > 0)
            project = projects[0];

    }

    public void enableEdit(){
        isEditEnable = true;
    }

    public void saveProjectInfo(){
        try{
            isEditEnable = false;
            system.debug('projects in Save - ' + project);
            update project;
            getProjectDetails();

        }
        catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }

    public void cancel(){
        isEditEnable = false;
        getProjectDetails();

    }
}