public class actionHub_CaseIncidentHandler {
    /**
    * actionHub_CaseHandler - <description>
    * Created by CloudAction
    * @author: Neena Tiwari
    * @version: 1.0
                1.1 Adding the Date SYnc up logic -Mitesh Giddia
*/

    public static boolean firedActionHubCaseIncident = false;
    //public static boolean firedActionHubIncidentCase = false;
    
    public static void caseRecordsHandler(Map<Id,Case> pCaseRecNewMap,Map<Id,Case>pCaseRecOldMap){
            firedActionHubCaseIncident= true;
            set<Id> incidentsIdSet = new Set<Id>();
            Map<Id,BMCServiceDesk__Incident__c> incidentsMap;
            List<BMCServiceDesk__Incident__c> updateIncidentsLst = new List<BMCServiceDesk__Incident__c>();
            
            //Fetched all incident Id from a case and put in a case
            For(Case incidentId : pCaseRecNewMap.values()){
                incidentsIdSet.add(incidentId.Related_Incident__c);
            }
            //query all matching incident from incident object 
            if(!incidentsIdSet.isEmpty()){
             incidentsMap = new Map<Id,BMCServiceDesk__Incident__c>([Select Source_Case__c,BMCServiceDesk__Status_ID__c,RF_Platform_s_Impacted__c,RF_Event_Start_Date_Time__c 
                                                                                                        from BMCServiceDesk__Incident__c 
                                                                                                        where Id IN :incidentsIdSet]);
            }
            //Synching Incident multiselectpicklist field with case multiselect picklist field values.
            For(BMCServiceDesk__Incident__c incidentId : incidentsMap.Values()){
                if(pCaseRecNewMap.get(incidentId.Source_Case__c)!=null && incidentId.BMCServiceDesk__Status_ID__c!='CLOSED'){
                
               //     if(incidentId.BMCServiceDesk__Status_ID__c!='CLOSED')
                //    {
                        incidentId.RF_Platform_s_Impacted__c = pCaseRecNewMap.get(incidentId.Source_Case__c).PlatformsImpacted__c;
                        incidentId.RF_Event_Start_Date_Time__c = pCaseRecNewMap.get(incidentId.Source_Case__c).EventStartDateTime__c;
               //     }
                   updateIncidentsLst.add(incidentId); 
                }
              //  updateIncidentsLst.add(incidentId); 
            }
            //updating incident multiselectpicklist values
            if(!updateIncidentsLst.isEmpty()){
                update updateIncidentsLst;
            }
    }
    
    public static void incidentRecordsHandler(Map<Id,BMCServiceDesk__Incident__c> pincRecNewMap){
            firedActionHubCaseIncident = true;
            set<Id> caseIdSet = new Set<Id>();
            Map<Id,Case> CaseMap;
            List<Case> updateCaseLst = new List<Case>();
            //Fetched all incident Id from a case and put in a case
            For(BMCServiceDesk__Incident__c caseId : pincRecNewMap.values()){
                caseIdSet.add(caseId.Source_Case__c);
            }
            //query all matching incident from incident object 
            if(!caseIdSet.isEmpty()){
             CaseMap = new Map<Id,Case>([Select Related_Incident__c,PlatformsImpacted__c,EventStartDateTime__c from Case where Id IN :caseIdSet]);
            }
            //Synching Incident multiselectpicklist field with case multiselect picklist field values.
            For(Case caseid : CaseMap.Values()){
                 if(pincRecNewMap.get(caseid.Related_Incident__c)!=null ){
                caseid.PlatformsImpacted__c = pincRecNewMap.get(caseid.Related_Incident__c).RF_Platform_s_Impacted__c;
                caseid.EventStartDateTime__c = pincRecNewMap.get(caseid.Related_Incident__c).RF_Event_Start_Date_Time__c;
            
                updateCaseLst.add(caseid); 
                 }
            }
            //updating incident multiselectpicklist values
            if(!updateCaseLst.isEmpty()){
                update updateCaseLst;
            }
    }
}