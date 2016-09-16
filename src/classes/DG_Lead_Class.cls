public without sharing class DG_Lead_Class {
	public static void ReEngagedMQL_ToSalesDev_OnUpdate(List<Lead> triggerNew, List<Lead> triggerOld){
        String vReEngagedMQL = 'Re-Engaged MQL';
        String vSaleDevProfile = 'Sales Development'; 
             
        list<Id> listSDUsers = new list<Id>();   
        
        integer i;
        for (i=0; i<triggerNew.size(); i++){
            if(triggerNew[i].Status <> triggerOld[i].Status && triggerNew[i].Status == vReEngagedMQL){
                if(triggerNew[i].Sales_Developer__c <> Null){
					listSDUsers.add(triggerNew[i].Sales_Developer__c); 
                }
            }
        } 
        
        if(listSDUsers.size() > 0){
        	map<Id, User> mapSDUsers = new map<Id, User>();
        	mapSDUsers.putAll([Select u.id, u.Profile.Name, u.ProfileId, u.IsActive From User u 
        		where u.Id in :listSDUsers and u.IsActive = true and u.Profile.Name = :vSaleDevProfile]);
        		
    	    integer j;
	        for (j=0; j<triggerNew.size(); j++){
	            if(triggerNew[j].Status <> triggerOld[j].Status && triggerNew[j].Status == vReEngagedMQL){
	                if(triggerNew[j].Sales_Developer__c <> Null){
	                	if(mapSDUsers.containsKey(triggerNew[j].Sales_Developer__c)){
	                		triggerNew[j].OwnerId = triggerNew[j].Sales_Developer__c;
	                	}
	                }
	            }
	        } 
        }
    }   	
    
    public static void ReEngagedMQL_ToAssignmentRule_OnUpdate(List<Lead> triggerNew, List<Lead> triggerOld){
        String vReEngagedMQL = 'Re-Engaged MQL';
        String vSaleDevProfile = 'Sales Development'; 
             
        list<Id> listSDUsers = new list<Id>();   
        
        integer i;
        for (i=0; i<triggerNew.size(); i++){
            if(triggerNew[i].Status <> triggerOld[i].Status && triggerNew[i].Status == vReEngagedMQL){
                if(triggerNew[i].Sales_Developer__c <> Null){
					listSDUsers.add(triggerNew[i].Sales_Developer__c);
                }
            }
        } 
        
        map<Id, User> mapSDUsers = new map<Id, User>();
        if(listSDUsers.size() > 0){
        	mapSDUsers.putAll([Select u.id, u.Profile.Name, u.ProfileId, u.IsActive From User u 
        		where u.Id in :listSDUsers and u.IsActive = true and u.Profile.Name = :vSaleDevProfile]);
        }
        
        list<ID> listLeadId4Assignment = new list<ID>();
	    integer j;
        for (j=0; j<triggerNew.size(); j++){
            if(triggerNew[j].Status <> triggerOld[j].Status && triggerNew[j].Status == vReEngagedMQL){
                if(triggerNew[j].Sales_Developer__c <> Null){
                	if(!mapSDUsers.containsKey(triggerNew[j].Sales_Developer__c)){
                		listLeadId4Assignment.add(triggerNew[j].id);
                	}
                }else{
                	listLeadId4Assignment.add(triggerNew[j].id);
                }
            }
        }
        
        if(listLeadId4Assignment.size()>0){
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            
            list<Lead> listLead4Assignment = [Select id from lead where id in :listLeadId4Assignment];
            for(lead l: listLead4Assignment){
                l.setOptions(dmo);
            }
            try{
            	update listLead4Assignment;
            }catch(exception e){} 
    	}       

    }
 }