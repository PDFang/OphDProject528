/**
    * actionHub_Case - <description>
    * Created by BrainEngine Cloud Studio
    * @author: Bruce Morgan
    * @version: 1.0
    *           1.1 - Adding case trigger logic to sync multiselet - Neena
*/

trigger actionHub_Case on Case bulk (after insert,after update) {

     System.Debug('***** Starting actionHub_Case.');
     System.Debug('**Trigger.New*****'+Trigger.newMap);
     System.Debug('**Trigger.OLD*****'+trigger.oldMap);
    if(!system.isFuture() && !actionHub_CaseIncidentHandler.firedActionHubCaseIncident)
    {
        System.Debug('***** Executing objectSaveEvent.');
        String source = 'Team Cloudaction Demo 2 Case';
        
        CloudactionInt.EventHandler handler = new CloudactionInt.EventHandler();
        handler.objectSaveEvent(trigger.old, trigger.new, source);
        System.Debug('***** objectSaveEvent has been executed.');
    }
    System.Debug('***** Closing actionHub_Case.');
    
    //version 1.1
   
    map<Id,case> newMapValuesMap = new map<Id,Case>();
    System.Debug('**actionHub_CaseIncidentHandler.firedActi*onHubIncidentCase*****'+actionHub_CaseIncidentHandler.firedActionHubCaseIncident);
    if(!actionHub_CaseIncidentHandler.firedActionHubCaseIncident){
        if(trigger.isAfter && trigger.isUpdate){
            System.Debug('**underinsertUpdate*****');
            for(Case c : trigger.newMap.Values()){
                System.Debug('**c.Related_Incident__c*****'+c.Related_Incident__c);
                System.Debug('**PlatformsImpacted__cNew*****'+c.PlatformsImpacted__c);
                System.Debug('**PlatformsImpacted__cOLD*****'+trigger.oldMap.get(c.Id).PlatformsImpacted__c);
                if(c.Related_Incident__c != null){
                    newMapValuesMap.put(c.Id,c);
                }
            }
            
            if(!newMapValuesMap.isEmpty()){
                actionHub_CaseIncidentHandler.caseRecordsHandler(newMapValuesMap,trigger.oldMap);
            }
        }
    }
    
    
 
}