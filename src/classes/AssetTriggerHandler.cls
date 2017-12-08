public class AssetTriggerHandler extends TriggerHandler {

    private static Id assetRollupQueueableJobID;

    public override void afterUpdate()
    {
        rollupNRRToPhaseProject();
        ProjectPhaseAssetSummary();
        ProjectParentAssetSummary();
    }

    public override void afterInsert()
    {
        rollupNRRToPhaseProject();
        ProjectPhaseAssetSummary();
        ProjectParentAssetSummary();
        AttachParentProject();
    }

    public override void afterDelete()
    {
        rollupNRRToPhaseProject();
        ProjectPhaseAssetSummary();
        ProjectParentAssetSummary();
    }

    // roll-up Asset NRR's to related phase project
    private static void rollupNRRToPhaseProject() {

        system.debug('**** started rollupNRRToPhaseProject() ');

        List<Asset> newList = (List<Asset>) (trigger.isDelete ? trigger.old : trigger.new);

        Set<Id> assetIdSet = new Set<Id>();

        for (Asset newAsset : newList) {

            if (trigger.isInsert || trigger.isUpdate){
                system.debug('**** rollupNRRToPhaseProject(): created or updated asset ');
                assetIdSet.add(newAsset.Id);
            } else if (trigger.isDelete) {
                system.debug('**** rollupNRRToPhaseProject(): deleted asset ');
                assetIdSet.add(newAsset.Id);
            }

        }

        system.debug('**** rollupNRRToPhaseProject(): assetIdSet - ' + assetIdSet);

        if(assetIdSet.size() > 0 && assetRollupQueueableJobID == null){
            assetRollupQueueableJobID = System.enqueueJob(new AssetRollupQueueable(assetIdSet));
            system.debug('**** rollupNRRToPhaseProject(): assetRollupQueueableJobID - ' + assetRollupQueueableJobID);
        }

    }

    //the ProjectPhaseAssetSummary method rolls-up related phase asset financial fields as totals on the phase record.
    public static void ProjectPhaseAssetSummary()
    {
        Set<Id> phaseIds = new Set<Id>();
        List<Asset> newList = (List<Asset>)( (trigger.isDelete) ? trigger.old : trigger.new );
        Map<Id, Asset> oldMap = (Map<Id, Asset>)( (trigger.isDelete) ? trigger.newMap : trigger.oldMap );

        for(Asset newAsset : newList)
        {
            Asset oldAsset = ( oldMap != null && oldMap.containsKey(newAsset.Id) ) ? oldMap.get(newAsset.Id) : null;
            if ( oldAsset == null
                    || newAsset.project_Phase__c != oldAsset.Project_Phase__C
                    || newAsset.FinalPrice__c != oldAsset.FinalPrice__c
                    || newAsset.Price != oldAsset.Price
                    || newAsset.Type__c != oldAsset.Type__c )
            {
                if (newAsset.Project_Phase__c != null)
                {
                    phaseIds.add(newAsset.Project_Phase__c);
                }
                if (oldAsset != null && oldAsset.Project_Phase__c != null)
                {
                    phaseIds.add(oldAsset.Project_Phase__c);
                }
            }
        }
        system.debug('**** ProjectPhaseAssetSummary() : phaseIds - '+phaseIds);
        if(phaseIds.isEmpty())
        {
            return;
        }

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
                System.debug('**** ProjectPhaseAssetSummary() : ar - '+ar);
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
        system.debug('**** ProjectPhaseAssetSummary() : phases - '+phases.values());
        update phases.values();

    } // end of ProjectPhaseAssetSummary()

    //the ProjectParentAssetSummary method rolls-up related project asset financial fields as totals on the parent project record.
    public static void ProjectParentAssetSummary()
    {
        Set<Id> projectIds = new Set<Id>();
        List<Asset> newList = (List<Asset>)( (trigger.isDelete) ? trigger.old : trigger.new );
        Map<Id, Asset> oldMap = (Map<Id, Asset>)( (trigger.isDelete) ? trigger.newMap : trigger.oldMap );

        for(Asset newAsset : newList)
        {
            Asset oldAsset = ( oldMap != null && oldMap.containsKey(newAsset.Id) ) ? oldMap.get(newAsset.Id) : null;
            if ( oldAsset == null
                    || newAsset.Parent_Project__c != oldAsset.Parent_Project__c
                    || newAsset.FinalPrice__c != oldAsset.FinalPrice__c
                    || newAsset.Price != oldAsset.Price
                    || newAsset.Type__c != oldAsset.Type__c )
            {
                if (newAsset.Parent_Project__c != null)
                {
                    projectIds.add(newAsset.Parent_Project__c);
                }
                if (oldAsset != null && oldAsset.Parent_Project__c != null)
                {
                    projectIds.add(oldAsset.Parent_Project__c);
                }
            }
        }
        System.debug('**** ProjectParentAssetSummary() : projectIds - '+projectIds);
        if(projectIds.isEmpty())
        {
            return;
        }

        Map<Id,Project__c> parentProjects = new Map<Id,Project__c>([SELECT Id, Project_Asset__c, ProjectMRC__c, ProjectNRC__c, Project_Telco__c FROM Project__c WHERE Id IN:projectIds]);
        AggregateResult[] projectTotalPrice = [SELECT Parent_Project__c, Type__c, RecordType.Name, SUM(Price), SUM(FinalPrice__c) FROM Asset WHERE Parent_Project__c IN:projectIds GROUP BY Parent_Project__c, Type__c, RecordType.Name];

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
                System.debug('**** ProjectParentAssetSummary() : ar - '+ar);
                decimal price = 0.00;
                decimal finalPrice = 0.00;
                Id projId = Id.valueOf(string.valueOf(ar.get('Parent_Project__c')));

                if(ar.get('Name') != null)
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

                        if(ar.get('Type__c') != null)
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
        system.debug('**** ProjectParentAssetSummary() : parentProjects - '+parentProjects.values());
        update parentProjects.values();

    } // end of ProjectParentAssetSummary()

    public static void AttachParentProject(){
        Set<Id> assetIds = new Set<Id>();
        Set<Id> quoteLineIds = new Set<Id>();
        List<Asset> newList = (List<Asset>)( trigger.new );
        for(Asset newAsset : newList){
            if(newAsset.SBQQ__QuoteLine__c != null){
                quoteLineIds.add(newAsset.SBQQ__QuoteLine__c);
                assetIds.add(newAsset.Id);
            }
        }
        if(quoteLineIds.size() > 0){
            PSProjectAssetAttachment.AttachAssetsByIdToParentProject(quoteLineIds, assetIds, new set<Id>());
        }
    }

}