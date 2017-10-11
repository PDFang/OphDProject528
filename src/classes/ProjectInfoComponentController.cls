/**
 * Created by ravish.chawla on 10/10/2017.
 */

public class ProjectInfoComponentController {

    public String projectId;
    public Project__c project {get; set;}
    Static Set<String> projectFields = new Set<String>();
    List<Project__c> projects = new List<Project__c>();

    public String getProjectId(){
        return projectId;
    }

    public void setProjectId(String s){
        projectId = s;
        getProjectDetails();
    }

//    public ProjectInfoComponentController(ApexPages.StandardController sc){
//        project = sc.getRecord();
//    }

    public void getProjectDetails(){
        List<Project__c> projectList = new List<Project__c>();
        system.debug('projectId - ' + projectId);

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

//    public pagereference cancel(){
//
//        return new PageReference('/'+ ApexPages.currentPage().getParameters().get('retURL')).setRedirect(true);
//    }

    public pagereference saveProjectInfo(){

        try{
            system.debug('projects in Save - ' + project);

//            Project__c updateProject = new Project__c();
//            updateProject.Id = projectId;
//            updateProject.ImplementationPartner__c = project.ImplementationPartner__c;
//            system.debug('updateProject - ' + updateProject);

//            updateProject(updateProject);
            upsert project;

        }
        catch (Exception ex){

        }
        return null;

    }

    public void updateProject(Project__c project){
        update project;
    }
}

