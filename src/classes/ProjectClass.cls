public class ProjectClass
{
/*
    //the ProjectPhaseAssetSummary method rolls-up related phase asset financial fields as totals on the phase record.
    public static Map<Id,Project__c> ProjectPhaseAssetSummary(Set<Id> phaseIds)
    {
        Map<Id,Project__c> phases = new Map<Id,Project__c>([SELECT Id, Phase_Asset__c,  PhaseMRC__c, PhaseNRC__c, Phase_Telco__c FROM Project__c WHERE Id IN:phaseIds]);
        AggregateResult[] phaseTotalPrice = [SELECT Project_Phase__c, Type__c, RecordType.Name, SUM(Price), SUM(FinalPrice__c) FROM Asset WHERE Project_Phase__c IN:phaseIds GROUP BY Project_Phase__c, Type__c, RecordType.Name];

        for(Project__c p: phases.values())
        {
            p.Phase_Asset__c = 0;
            p.PhaseMRC__c = 0;
            p.PhaseNRC__c = 0;
            p.Phase_Telco__c = 0;
        }
        
        if(!phaseTotalPrice.isEmpty())
        {
            for(AggregateResult ar:phaseTotalPrice)
            {
                decimal price = 0.00;
                decimal finalPrice = 0.00;
                Id projId = Id.valueOf(string.valueOf(ar.get('Project_Phase__c')));
                
                if(ar.get('Name') != Null)
                {
                    String arRT = string.valueOf(ar.get('Name'));
                    
                    if(arRT == 'Premise Asset' && ar.get('expr0') != null)                     
                    {  
                        price = decimal.valueOf(string.valueOf(ar.get('expr0')));
                        phases.get(projId).Phase_Asset__c +=  price;
                    }
                                        
                    else if(arRT == 'SaaS Asset' && ar.get('expr1') != Null){ 
                        
                        finalPrice = decimal.valueOf(string.valueOf(ar.get('expr1')));
                        phases.get(projId).Phase_Asset__c +=  finalPrice;
                        if(ar.get('Type__c') != Null)
                        {
                            String aType = string.valueOf(ar.get('Type__c'));
                            
                            if (aType == 'MRC')
                            {
                                phases.get(projId).PhaseMRC__c +=  finalPrice;
                            }
                            else if(aType == 'NRC'){
                                phases.get(projId).PhaseNRC__c +=  finalPrice;
                            }
                            else if(aType == 'Telco'){
                                phases.get(projId).Phase_Telco__c +=  finalPrice;
                            }
                        }
                    }
                }  
            } 
        }
        return phases;
    }    
    
     //the ProjectParentAssetSummary method rolls-up related project asset financial fields as totals on the parent project record.
    public static Map<Id,Project__c> ProjectParentAssetSummary(Set<Id> parentProjectIds)
    {
        Map<Id,Project__c> parentProjects = new Map<Id,Project__c>([SELECT Id, Project_Asset__c, ProjectMRC__c, ProjectNRC__c, Project_Telco__c FROM Project__c WHERE Id IN:parentProjectIds]);
        AggregateResult[] projectTotalPrice = [SELECT Parent_Project__c, Type__c, RecordType.Name, SUM(Price), SUM(FinalPrice__c) FROM Asset WHERE Parent_Project__c IN:parentProjectIds GROUP BY Parent_Project__c, Type__c, RecordType.Name];
        
        for(Project__c p: parentProjects.values())
        {
            p.Project_Asset__c = 0;
            p.ProjectMRC__c = 0;
            p.ProjectNRC__c = 0;
            p.Project_Telco__c = 0;
        }

        if(!projectTotalPrice.isEmpty())
        {
            for(AggregateResult ar:projectTotalPrice)
            {
                decimal price = 0.00;
                decimal finalPrice = 0.00;
                Id projId = Id.valueOf(string.valueOf(ar.get('Parent_Project__c')));
                
                if(ar.get('Name') != Null)
                {
                    String arRT = string.valueOf(ar.get('Name'));
                    if(arRT =='Premise Asset' && ar.get('expr0') != null)
                    {
                        price = decimal.valueOf(string.valueOf(ar.get('expr0')));
                        parentProjects.get(projId).Project_Asset__c +=  price;
                    }
                    else if(arRT =='SaaS Asset' && ar.get('expr1') != null){
                        finalPrice = decimal.valueOf(string.valueOf(ar.get('expr1')));
                        parentProjects.get(projId).Project_Asset__c += finalPrice;
                        
                        if(ar.get('Type__c') != Null)
                        {
                            String aType  = string.valueOf(ar.get('Type__c'));
                            if(aType =='MRC')
                            {
                                parentProjects.get(projId).ProjectMRC__c += finalPrice;   
                            }
                            else if (aType =='NRC'){
                                parentProjects.get(projId).ProjectNRC__c += finalPrice;
                            }
                            else if(aType =='Telco'){
                                parentProjects.get(projId).Project_Telco__c += finalPrice;
                            }
                        }
                    }
                }
            }
        }
        
        return parentProjects;
    }
*/
    //the ProjectParentPhaseSummary method rolls-up related phase financial fields as totals on the parent project record.
    public static Map<Id,Project__c> ProjectParentPhaseSummary(Set<Id> psParentProjectIds)
    {
        Map<Id,Project__c> psParentProjects = new Map<Id,Project__c>([SELECT Id, MRC_Delivered__c, NRC_Delivered__c FROM Project__c WHERE Id IN:psParentProjectIds]);
        AggregateResult[] projectRevenue = [SELECT ParentProject__c, SUM(PhaseMRC__c), SUM(PhaseNRC__c), Phase_Status__c FROM Project__c WHERE ParentProject__c IN:psParentProjectIds GROUP BY ParentProject__c, Phase_Status__c]; 
        
        for(Project__c p: psParentProjects.values())
        {
            p.MRC_Delivered__c = 0;
            p.NRC_Delivered__c = 0;
        }    
        if(!projectRevenue.isEmpty())
        {
            for(AggregateResult arpr:projectRevenue)
            {
                decimal MrcDelivered = 0.00;
                decimal NrcDelivered = 0.00;
                
                Id projId = Id.valueOf(string.valueOf(arpr.get('ParentProject__c')));
                String phaseStatus = string.valueOf(arpr.get('Phase_Status__c'));
  			                
            	if(phaseStatus == 'Closed')
                {
                	if(arpr.get('expr0') != null)
                	{
                    	mrcDelivered = decimal.valueOf(string.valueOf(arpr.get('expr0')));
                        psParentProjects.get(projId).MRC_Delivered__c = MrcDelivered;
                        nrcDelivered = decimal.valueOf(string.valueOf(arpr.get('expr0')));
                        psParentProjects.get(projId).NRC_Delivered__c = NrcDelivered;
                     }
                    if(arpr.get('expr1') != null)
                	{
                        nrcDelivered = decimal.valueOf(string.valueOf(arpr.get('expr1')));
                        psParentProjects.get(projId).NRC_Delivered__c = NrcDelivered;
                     }
                 }
            }
        }		     
        return psParentProjects;
    }
}