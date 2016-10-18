/**
    * LinkedTasK -  Trigger on LinkedTask on after update
    * Created by CloudAction
    * Date - 13/7/2016
    * @author: Neena Tiwari
    * @version: 1.0
*/

trigger LinkedTask on BMCServiceDesk__Task__c (after update) {

	LinkedTaskHandler handler = new LinkedTaskHandler();
	Map<Id,BMCServiceDesk__Task__c> newTaskMap = new Map<Id,BMCServiceDesk__Task__c>();	
	Set<Id> incidentIdSet = new Set<Id>();
	Set<Id> problemIdSet = new Set<Id>();
	system.debug('Entered Trigger');
	Map<String,Id> statusWithId = CCRControlsClass.StatusName();
	  For ( BMCServiceDesk__Task__c newtest : Trigger.new){ 
	  		system.debug('newtest.STATUSName@@@@@@@@@@@@'+newtest.BMCServiceDesk__FKStatus__c);

	  		If( newtest.BMCServiceDesk__FKStatus__c == statusWithId.get('CLOSED') && 
	  			trigger.oldMap.get(newtest.Id).BMCServiceDesk__FKStatus__c != statusWithId.get('CLOSED')){
	  				system.debug('inside if condition');
	  				newTaskMap.put(newtest.Id,newtest);	 
	  				incidentIdSet.add(newtest.BMCServiceDesk__FKIncident__c);
	  				problemIdSet.add(newtest.BMCServiceDesk__FKProblem__c); 				
	  		}
	  } 

	  //Pass value to handler method
	  If(!newTaskMap.isEmpty()){
	  	system.debug('newTaskMap@@@@@@@'+newTaskMap);
		handler.updateIncidenAndProblem(newTaskMap,incidentIdSet,problemIdSet);
	  } 
}