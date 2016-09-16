trigger actionHub_Incident on BMCServiceDesk__Incident__c bulk (after insert,after update) {



 if(trigger.isAfter && trigger.isUpdate || trigger.isAfter && trigger.isInsert){
 
        if(!system.isFuture() && !actionHub_CaseIncidentHandler.firedActionHubCaseIncident)
        {
            String source = 'Cloudaction Dev 3';
            CloudactionInt.EventHandler handler = new CloudactionInt.EventHandler();
            handler.objectSaveEvent(trigger.old, trigger.new, source);
        }
        
        //version 1.1
        
        map<Id,BMCServiceDesk__Incident__c> newValuesMap = new map<Id,BMCServiceDesk__Incident__c>();
       
        if(!actionHub_CaseIncidentHandler.firedActionHubCaseIncident){
     
            if(trigger.isAfter && trigger.isUpdate){
                for(BMCServiceDesk__Incident__c inc : trigger.newMap.Values()){
                    if(inc.Source_Case__c != null && inc.RF_Platform_s_Impacted__c != null){
                        newValuesMap.put(inc.Id,inc);
                    }
                }
                if(!newValuesMap.isEmpty()){
                    actionHub_CaseIncidentHandler.incidentRecordsHandler(newValuesMap);
                }
            }
        } 
    }
}