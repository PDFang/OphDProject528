/**
    * LinkedTaskHandler- This Handler class will get called from LinkedTask 
    *                    trigger which will update Incident and Problem when all related task get closed.
    * Created by CloudAction
    * Date - 13/7/2016
    * @author: Neena Tiwari
    * @version: 1.0
*/
public class LinkedTaskHandler {
	//This method will update Incident and Problems to "All Task closed", 
	//when all related task get closed

		
	Public void updateIncidenAndProblem(Map<Id,BMCServiceDesk__Task__c> pTaskNewMap,Set<Id>incidentIdSet,Set<Id> problemIdSet){
		
		Map<BMCServiceDesk__Incident__c,List<BMCServiceDesk__Task__c>> incidentRelatedTask = getIncidentRelatedTask(incidentIdSet);
		Map<BMCServiceDesk__Problem__c,List<BMCServiceDesk__Task__c>> problemRelatedTask =   getproblemRelatedTask(problemIdSet);
		Map<String,Id> statusWithId = CCRControlsClass.StatusName();
		
		List<BMCServiceDesk__Incident__c> toUpdateLst = new list<BMCServiceDesk__Incident__c>();
		List<BMCServiceDesk__Problem__c> toUpdateProblemLst = new list<BMCServiceDesk__Problem__c>();
		Integer count = 0;

		if(!incidentRelatedTask.isEmpty()){
			For(BMCServiceDesk__Incident__c incident : incidentRelatedTask.keySet()){

				List<BMCServiceDesk__Task__c> allTask = incidentRelatedTask.get(incident);
					system.debug('allTask55555555555555  '+allTask.size());
					for(BMCServiceDesk__Task__c task: allTask){
						if(task.BMCServiceDesk__FKStatus__c == statusWithId.get('CLOSED')){
							count++;
						}
					}

					if(allTask.size() == count){
						incident.BMCServiceDesk__FKStatus__c = statusWithId.get('ALL TASKS COMPLETED');
						system.debug('incident.BMCServiceDesk__FKStatus__c%%%%%%%%%%%%%'+incident.BMCServiceDesk__FKStatus__c);
						toUpdateLst.add(incident);
					}
					count = 0;

			}
		}

		if(!problemRelatedTask.isEmpty()){
			For(BMCServiceDesk__Problem__c problm : problemRelatedTask.keySet()){

				List<BMCServiceDesk__Task__c> allTask = problemRelatedTask.get(problm);
					system.debug('allTask55555555555555  '+allTask.size());
					for(BMCServiceDesk__Task__c task: allTask){
						if(task.BMCServiceDesk__FKStatus__c == statusWithId.get('CLOSED')){
							count++;
						}
					}

					if(allTask.size() == count){
						problm.BMCServiceDesk__FKStatus__c = statusWithId.get('ALL TASKS COMPLETED');
						system.debug('incident.BMCServiceDesk__FKStatus__c%%%%%%%%%%%%%'+problm.BMCServiceDesk__FKStatus__c);
						toUpdateProblemLst.add(problm);
					}
					count = 0;

			}
		}				
		system.debug('toUpdateLst@@@@@@@'+toUpdateLst);
		system.debug('toUpdateProblemLst@@@@@@@'+toUpdateProblemLst);


		if(!toUpdateLst.isEmpty()){
			update toUpdateLst;
		}
		if(!toUpdateProblemLst.isEmpty()){
			update toUpdateProblemLst;
		}

	}

	
	public Map<BMCServiceDesk__Incident__c,List<BMCServiceDesk__Task__c>> getIncidentRelatedTask(Set<Id> pIncidentId){

		Map<BMCServiceDesk__Incident__c,List<BMCServiceDesk__Task__c>> incidentRelatedTask = new Map<BMCServiceDesk__Incident__c,List<BMCServiceDesk__Task__c>>();
		system.debug('pIncidentId##############'+pIncidentId);

		For(BMCServiceDesk__Incident__c incident : [Select Id,BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name,
														(Select Id,Name,BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name 
														from BMCServiceDesk__Tasks__r)
												From BMCServiceDesk__Incident__c where Id IN:pIncidentId]){

				incidentRelatedTask.put(incident,incident.BMCServiceDesk__Tasks__r);
			}
		system.debug('incidentRelatedTask@@@@@@@'+incidentRelatedTask);

		return incidentRelatedTask;
	}


	public Map<BMCServiceDesk__Problem__c,List<BMCServiceDesk__Task__c>> getproblemRelatedTask(Set<Id> problemIdSet){
		Map<BMCServiceDesk__Problem__c,List<BMCServiceDesk__Task__c>> problemRelatedTask = new Map<BMCServiceDesk__Problem__c,List<BMCServiceDesk__Task__c>>();

		For(BMCServiceDesk__Problem__c problm : [Select Id,BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name,
														(Select Id,Name,BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name 
														from BMCServiceDesk__Tasks__r)
												From BMCServiceDesk__Problem__c where Id IN:problemIdSet]){

				problemRelatedTask.put(problm,problm.BMCServiceDesk__Tasks__r);
			}
		system.debug('problemRelatedTask@@@@@@@'+problemRelatedTask);

		return problemRelatedTask;
	}
	
}