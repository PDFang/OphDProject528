/**
 * Created by jeremy.sparrell on 1/4/2018.
 */

public class AdmWorkTriggerHandler  extends TriggerHandler
{
    public override void beforeInsert() {
        CreateEpics(trigger.new);
    }

    public static void CreateEpics(List<agf__ADM_Work__c> works){

        Map<Id,Id> projectEpics = new Map<Id,Id>();
        Map<Id, agf__ADM_Epic__c> newEpics = new Map<Id, agf__ADM_Epic__c>();
        Set<Id> projectIds = GetProjectIds(works);

        Map<Id, Project__c> projects = new Map<Id, Project__c>([SELECT Id, Name, Summary__c FROM Project__c WHERE Id IN :projectIds]);
        agf__ADM_Epic__c[] epics = [SELECT Id, Project__c FROM agf__ADM_Epic__c WHERE Project__c IN :projectIds];

        if(epics.size() > 0){
            for(agf__ADM_Epic__c epic:epics){
                if(!projectEpics.containsKey(epic.Project__c)) {
                    projectEpics.put(epic.Project__c, epic.Id);
                }
            }

        }

        for(Id projectId:projectIds){
            if(!projectEpics.containsKey(projectId)){
                Project__c project = projects.get(projectId);

                agf__ADM_Epic__c epic = new agf__ADM_Epic__c();
                epic.Name = project.Summary__c.left(80);
                epic.Project__c = projectId;

                newEpics.put(projectId, epic);
            }
        }

        if(!newEpics.isEmpty()){
            insert newEpics.values();
        }

        for(agf__ADM_Work__c work:works){
            if(work.Project__c != null && newEpics.containsKey(work.Project__c)) {
                work.agf__Epic__c = newEpics.get(work.Project__c).Id;
            } else if(work.Project__c != null && projectEpics.containsKey(work.Project__c)){
                work.agf__Epic__c = projectEpics.get(work.Project__c);
            }
        }

    }

    public static Set<Id> GetProjectIds(List<agf__ADM_Work__c> works){

        Set<Id> projectIds = new Set<Id>();

        for(agf__ADM_Work__c work: works)
        {
            projectIds.Add(work.Project__c);
        }

        return projectIds;
    }
}