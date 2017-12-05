public class ProjectTriggerHandler extends TriggerHandler{

    public static boolean lockSortingFields = true;

    static boolean initialized = false;
    static Id projectRollupQueueableJobID;
    static Id opportunityRollupQueueableJobID;
    static Id salesEngineeringRecordTypeId;
    static Id psProjectPhaseSaasRecordTypeId, psProjectParentPremiseRecordTypeId;
    static Id psProjectParentSaasRecordTypeId, psProjectPhasePremiseRecordTypeId;
    static set<Id> allowedRecordTypes;

    static final Set<String> debugProjectFields = new Set<String>{
            'Id',
            'RecordTypeId',
            'ParentProject__c',
            'Opportunity__c',
            'Phase_Status__c',
            'EstimatedProjectGoLiveDate__c',
            'ActualProjectGoLiveDate__c',
            'Original_Phase_Forecasted_Go_Live_Date__c',
            'Times_Go_Live_Date_Changed__c'
    };

    public ProjectTriggerHandler(){

        if(!initialized){
            Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c;
            Map<String, Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

            salesEngineeringRecordTypeId = rtMapByName.get('Sales Engineering Project').getRecordTypeId();
            psProjectPhasePremiseRecordTypeId = rtMapByName.get('PS Project Phase Premise WFO').getRecordTypeId();
            psProjectPhaseSaasRecordTypeId = rtMapByName.get('PS Project Phase SaaS').getRecordTypeId();
            psProjectParentPremiseRecordTypeId = rtMapByName.get('PS Parent Project - Premise').getRecordTypeId();
            psProjectParentSaasRecordTypeId = rtMapByName.get('PS Parent Project - SaaS').getRecordTypeId();

            allowedRecordTypes = new set<Id> ();
            for (Schema.RecordTypeInfo recordType : rtMapByName.values())
            {
                String recordTypeName = recordType.getName();

                if(recordTypeName.contains('Phase') && recordTypeName.startsWith('PS'))
                {
                    allowedRecordTypes.add(recordType.getRecordTypeId());
                }
            }

            initialized = true;
        }

    }

    protected override void beforeInsert(){

        //if it is a phase project validate the phase number
        ProjectTriggerHelper.setNextPhaseNumber(Trigger.new);

        setPhaseProjectGoLiveDates();

        // Assign Project owners and set status to New
        ProjectTriggerHelper.assignProjectOwners(Trigger.new);

    }

    protected override void beforeUpdate(){

        // Assign Project owners and set status to New
        ProjectTriggerHelper.setStatusForITAndDbaProjects((List<Project__c>)trigger.new, (Map<Id, Project__c>)Trigger.oldMap);

        setPhaseProjectGoLiveDates();

    }

    public override void afterInsert(){

        new ProjectShareHelper().addShare((List<Project__c>)trigger.new, (Map<Id, Project__c>)trigger.oldMap);
        //new PartnerShareHelper().addShare(trigger.new, trigger.oldMap);
        calculateProjectedDeadline(trigger.new);

        ProjectParentPhaseSummary();

        setParentProjectGoLiveDates();

        SalesEngineeringLogic.CreateNewProjectTasks(trigger.new, salesEngineeringRecordTypeId);
        ProjectTriggerHelper.updateParentPlannedHours(trigger.new, psProjectPhaseSaasRecordTypeId);
        ProjectTriggerHelper.createProjectTasks(Trigger.new);

    }

    public override void afterUpdate(){

        CallTFSService(trigger.new);

        new ProjectShareHelper().deleteShare((List<Project__c>)trigger.new, (Map<Id, Project__c>)trigger.oldMap);
        new ProjectShareHelper().addShare((List<Project__c>)trigger.new, (Map<Id, Project__c>)trigger.oldMap);
        LockDownPriorityFields((List<Project__c>)trigger.new, (Map<Id, Project__c>)trigger.oldMap);

        // roll-up
        calculateProjectedDeadline(trigger.new);
        ProjectParentPhaseSummary();
        ProjectTriggerHelper.updateParentPlannedHours(trigger.new, psProjectPhaseSaasRecordTypeId);
        setParentProjectGoLiveDates();

        calculatePhaseImpQuantityNPercentage(trigger.new, (Map<Id, Project__c>)trigger.oldMap);
        ProjectTriggerHelper.updateAssetStatusForPhasedProject((List<Project__c>)trigger.new, (Map<Id, Project__c>)Trigger.oldMap);
        SalesEngineeringLogic.UpdateProjectRelatedOwners(trigger.old, trigger.new, salesEngineeringRecordTypeId);

    }

    public override void afterDelete(){

        calculateProjectedDeadline(trigger.old);

        ProjectParentPhaseSummary();

        setParentProjectGoLiveDates();

    }

    private static void LockDownPriorityFields(list<Project__c> lstProjects, Map<Id, Project__c> oldmapProjects){

        for(Project__c proj: lstProjects){
            if(((proj.BattingOrder__c != oldmapProjects.get(proj.Id).BattingOrder__c)
                    ||(proj.Ops_Backlog_Priority__c != oldmapProjects.get(proj.Id).Ops_Backlog_Priority__c))
                    && ProjectTriggerHandler.lockSortingFields
                    && !Test.isRunningTest()
                    ){
                proj.addError('Changing Global or Channel priority from the page layout is not allowed, please use the PMO Project Prioritization page to update the priorities.');
            }

        }
    }

    private static void CallTFSService(list<Project__c> lstProjects)
    {
        system.debug('trigger context ==> ' + trigger.isExecuting + ', ' +  trigger.isUpdate);
        set<string> projectIds = new set<String>();

        for(Project__c proj : lstProjects)
        {
            if(proj.TFSId__c != '' )
            {
                if(trigger.isExecuting && trigger.isUpdate && proj.SyncToTFS__c == true)
                {
                    projectIds.add(proj.Id);
                }

            }
        }

        system.debug('projectIds ==> ' + projectIds);

        if(lstProjects.size() >= 100)
        {
            for(Project__c proj : lstProjects)
            {
                proj.addError('Inserting more than 100 records are not allowed in a batch. These records will not be created in TFS. Please use small batches to insert the Work Items');
            }
        }
        else if(projectIds.size() > 0)
        {
            if (!ISTFSINTEGRATIONCLASS.isWebServiceCall)
                ISTFSINTEGRATIONCLASS.CallTFSFutureMethod(projectIds, 'Project__c');

        }


    }

    private static void setPhaseProjectGoLiveDates(){

        system.debug('**** started setPhaseProjectGoLiveDates() ');

        List<Project__c> newList = (List<Project__c>) trigger.new;
        Map<Id, Project__c> oldMap = (Map<Id, Project__c>)trigger.oldMap;

        for(Project__c newProject : newList){

            if(newProject.RecordTypeId != psProjectPhaseSaasRecordTypeId){
                continue;
            }
            system.debug('**** setPhaseProjectGoLiveDates(): EstimatedProjectGoLiveDate__c - '+ newProject.EstimatedProjectGoLiveDate__c);
            system.debug('**** setPhaseProjectGoLiveDates(): Original_Phase_Forecasted_Go_Live_Date__c - '+ newProject.Original_Phase_Forecasted_Go_Live_Date__c);
            system.debug('**** setPhaseProjectGoLiveDates(): Times_Go_Live_Date_Changed__c - '+ newProject.Times_Go_Live_Date_Changed__c);

            Project__c oldProject = oldMap != null ? oldMap.get(newProject.Id) : null;
            if(newProject.isClone()){
                newProject.Times_Go_Live_Date_Changed__c = null;
                newProject.Original_Phase_Forecasted_Go_Live_Date__c = null;
                newProject.Actual_NRR__c = 0;
                newProject.Contracted_NRR__c = 0;
            }
            if(trigger.isInsert && newProject.EstimatedProjectGoLiveDate__c != null){
                newProject.Original_Phase_Forecasted_Go_Live_Date__c = newProject.EstimatedProjectGoLiveDate__c;
                newProject.Unlock_Original_Phase_Go_Live_Date__c = true;
                newProject.Times_Go_Live_Date_Changed__c = 0;
            }
            if(trigger.isUpdate && newProject.EstimatedProjectGoLiveDate__c != oldProject.EstimatedProjectGoLiveDate__c && newProject.EstimatedProjectGoLiveDate__c != null){
                if(newProject.Original_Phase_Forecasted_Go_Live_Date__c == null ){
                    newProject.Original_Phase_Forecasted_Go_Live_Date__c = newProject.EstimatedProjectGoLiveDate__c;
                    newProject.Unlock_Original_Phase_Go_Live_Date__c = true;
                    newProject.Times_Go_Live_Date_Changed__c = 0;
                }else{
                    newProject.Times_Go_Live_Date_Changed__c = (oldProject.Times_Go_Live_Date_Changed__c == null ? 0 : oldProject.Times_Go_Live_Date_Changed__c) + 1;
                }

            }

            system.debug('**** setPhaseProjectGoLiveDates(): EstimatedProjectGoLiveDate__c - '+ newProject.EstimatedProjectGoLiveDate__c);
            system.debug('**** setPhaseProjectGoLiveDates(): Original_Phase_Forecasted_Go_Live_Date__c - '+ newProject.Original_Phase_Forecasted_Go_Live_Date__c);
            system.debug('**** setPhaseProjectGoLiveDates(): Times_Go_Live_Date_Changed__c - '+ newProject.Times_Go_Live_Date_Changed__c);

        }

    }

    private static void setParentProjectGoLiveDates(){

        system.debug('**** started setParentProjectGoLiveDates() ');

        List<Project__c> newList = (List<Project__c>) (trigger.isDelete ? trigger.old : trigger.new);

        Map<Id, Project__c> oldMap = (Map<Id, Project__c>)trigger.oldMap;
        Set<Id> parentProjectIdSet = new Set<Id>();
        Set<Id> projectOppIdSet = new Set<Id>();

        for(Project__c newProject : newList){


            Project__c oldProject = oldMap != null ? oldMap.get(newProject.Id) : null;

            system.debug(' setParentProjectGoLiveDates(): newProject - ' + printInDebugLog(newProject));
            system.debug(' setParentProjectGoLiveDates(): oldProject - ' + printInDebugLog(oldProject));

            // parent SaaS or Premise project is updated or deleted
            if(newProject.RecordTypeId == psProjectParentSaasRecordTypeId || newProject.RecordTypeId == psProjectParentPremiseRecordTypeId){

                if(trigger.isDelete){
                    projectOppIdSet.add(newProject.Opportunity__c);
                } else if(trigger.isUpdate && newProject.Opportunity__c != oldProject.Opportunity__c){
                    projectOppIdSet.add(newProject.Opportunity__c);
                    projectOppIdSet.add(oldProject.Opportunity__c);
                }

                continue;
            }

            // Phase SaaS or Premise project is created or updated or deleted
            if(newProject.RecordTypeId == psProjectPhaseSaasRecordTypeId || newProject.RecordTypeId == psProjectPhasePremiseRecordTypeId) {

                if (trigger.isInsert && (newProject.EstimatedProjectGoLiveDate__c != null || newProject.ActualProjectGoLiveDate__c != null
                        || (newProject.Phase_Status__c != 'Closed' && newProject.Phase_Status__c != 'Cancelled'))
                        || newProject.Actual_NRR__c > 0
                        || newProject.Contracted_NRR__c > 0)
                {
                    system.debug('**** setParentProjectGoLiveDates(): created Phase Project ');
                    parentProjectIdSet.add(newProject.ParentProject__c);
                } else if (trigger.isUpdate && (newProject.EstimatedProjectGoLiveDate__c != oldProject.EstimatedProjectGoLiveDate__c
                        || newProject.ActualProjectGoLiveDate__c != oldProject.ActualProjectGoLiveDate__c
                        || newProject.Phase_Status__c != oldProject.Phase_Status__c
                        || newProject.ParentProject__c != oldProject.ParentProject__c
                        || newProject.Actual_NRR__c != oldProject.Actual_NRR__c
                        || newProject.Contracted_NRR__c != oldProject.Contracted_NRR__c
                        || newProject.Actual_MRR__c != oldProject.Actual_MRR__c
                        || newProject.Contracted_MRR__c != oldProject.Contracted_MRR__c) )
                {
                    system.debug('**** setParentProjectGoLiveDates(): updated Phase Project ');
                    parentProjectIdSet.add(newProject.ParentProject__c);
                    if (newProject.ParentProject__c != oldProject.ParentProject__c) {
                        parentProjectIdSet.add(oldProject.ParentProject__c);
                    }
                } else if (trigger.isDelete) {
                    system.debug('**** setParentProjectGoLiveDates(): deleted Phase Project ');
                    parentProjectIdSet.add(newProject.ParentProject__c);
                }
            }

        }

        // remove null values
        parentProjectIdSet.remove(null);
        projectOppIdSet.remove(null);

        system.debug('**** setParentProjectGoLiveDates(): parentProjectIdSet - ' + parentProjectIdSet);
        system.debug('**** setParentProjectGoLiveDates(): projectOppIdSet - ' + projectOppIdSet);

        if(parentProjectIdSet.size() > 0 && projectRollupQueueableJobID == null){
            projectRollupQueueableJobID = System.enqueueJob(new ProjectRollupQueueable(parentProjectIdSet));
            system.debug('**** setParentProjectGoLiveDates(): projectRollupQueueableJobID - ' + projectRollupQueueableJobID);
        }

        if(projectOppIdSet.size() > 0 && opportunityRollupQueueableJobID == null){
            opportunityRollupQueueableJobID = System.enqueueJob(new OpportunityRollupQueueable(projectOppIdSet));
            system.debug('**** setParentProjectGoLiveDates(): opportunityRollupQueueableJobID - ' + opportunityRollupQueueableJobID);
        }

    }

    private static String printInDebugLog(Project__c project){

        if(project == null){
            return '';
        }

        Map<String, object> projectFields = new Map<String, Object>();
        for(String field : debugProjectFields){
            projectFields.put(field, project.get(field));
        }

        return JSON.serialize(projectFields);

    }

    private static void calculateProjectedDeadline(list<Project__c> newList){
        System.debug('newList in calculateProjectedDeadline' + newList);
        Map<Id, Project__c> oldMap = (Map<Id, Project__c>)( trigger.oldMap );
        Set<Id> vaildRecordTypeIdSet = new Set<Id>();
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Project__c.getRecordTypeInfosByName();
        if(rtMapByName.containsKey('PS Project Phase Premise WFO') == false){
            return;
        }
        vaildRecordTypeIdSet.add(rtMapByName.get('PS Project Phase Premise WFO').getRecordTypeId());

        List<Project__c> processList = new List<Project__c>();
        Set<Id> parentProjectIdSet = new Set<Id>();
        for(Project__c newProject : newList){
            Project__c oldProject = oldMap != null ? oldMap.get(newProject.id) : null;
            if(vaildRecordTypeIdSet.contains(newProject.RecordTypeId) ){
                if(trigger.isDelete || ( oldProject == null && newProject.Projected_Deadline__c != null && newProject.ParentProject__c != null )
                        || (oldProject != null && ( newProject.Projected_Deadline__c != oldProject.Projected_Deadline__c || newProject.ParentProject__c != oldProject.ParentProject__c)) ){
                    processList.add(newProject);
                    parentProjectIdSet.add(newProject.ParentProject__c);
                }
                if(oldProject != null && oldProject.ParentProject__c != null && newProject.ParentProject__c != oldProject.ParentProject__c){
                    parentProjectIdSet.add(oldProject.ParentProject__c);
                }
            }
        }

        system.debug('**** calculateProjectedDeadline(): processList - '+processList);
        system.debug('**** calculateProjectedDeadline(): parentProjectIdSet - '+parentProjectIdSet);

        if(parentProjectIdSet.isEmpty()){
            return;
        }

        List<Project__c> projectUpdateList = new List<Project__c>();
        Map<Id,Project__c> parentProjectMap = new Map<Id,Project__c>([SELECT Id, Projected_Deadline__c FROM Project__c WHERE Id IN :parentProjectIdSet]);
        AggregateResult[] aggregateList = [
                SELECT ParentProject__c, MAX(Projected_Deadline__c) maxDate FROM Project__c
                WHERE ParentProject__c IN :parentProjectIdSet and Projected_Deadline__c != null
                GROUP BY ParentProject__c
        ];

        system.debug('**** calculateProjectedDeadline(): parentProjectMap - '+parentProjectMap);
        system.debug('**** calculateProjectedDeadline(): aggregateList - '+aggregateList);

        for(AggregateResult ar :aggregateList){
            if(ar.get('ParentProject__c') != null && ar.get('maxDate') != null){
                Project__c parentProject = parentProjectMap.get((Id)ar.get('ParentProject__c'));
                if( parentProject.Projected_Deadline__c == null || (trigger.isDelete && (Date)ar.get('maxDate') != parentProject.Projected_Deadline__c) || (Date)ar.get('maxDate') > parentProject.Projected_Deadline__c ) {
                    parentProject.Projected_Deadline__c = (Date)ar.get('maxDate');
                    projectUpdateList.add(parentProject);
                }
            }
        }
        system.debug('**** calculateProjectedDeadline(): projectUpdateList - '+projectUpdateList);
        if(projectUpdateList.size() > 0){
            update projectUpdateList;
        }

    } // end of calculateProjectedDeadline()


    private static void ProjectParentPhaseSummary(){

        Set<Id> psParentProjectIds = new Set<Id>();
        List<Project__c> newList = trigger.new != null ? (List<Project__c>)trigger.new : null;
        List<Project__c> oldList = trigger.old != null ? (List<Project__c>)trigger.old : null;

        if (!trigger.isDelete)
        {
            for (integer i = 0; i < newList.size(); i++)
            {
                Project__c newProject = newList[i];

                // Only perform the update if the record type for parent is a Phased Project
                if (allowedRecordTypes.contains(newProject.RecordTypeId))
                {
                    if (newProject.ParentProject__c != null)
                    {
                        psParentProjectIds.add(newProject.ParentProject__c);
                    }

                    if (!trigger.isInsert)
                    {
                        Project__c oldProject = oldList[i];

                        if (newProject.ParentProject__c != oldProject.ParentProject__c && oldProject.ParentProject__c != Null)
                        {
                            psParentProjectIds.add(oldProject.ParentProject__c);
                        }
                    }
                }
            }
        }
        else
        {
            for (Project__c p : oldList)
            {
                if (p.ParentProject__c != null && allowedRecordTypes.Contains(p.RecordTypeId))
                {
                    psParentProjectIds.add(p.ParentProject__c);
                }
            }
        }

        if (!psParentProjectIds.isEmpty())
        {
            Map<Id, Project__c> psParentProjects = ProjectClass.ProjectParentPhaseSummary(psParentProjectIds);
            update psParentProjects.values();
        }

    }

    //Assign Phase Implemented Quantity, Percentage and Status
    private static void calculatePhaseImpQuantityNPercentage(List<Project__c> newList, Map<Id, Project__c> oldMap){
        Set<String> phaseProjectRecordTypeSet = new Set<String>{
                'PS Project Phase Premise WFO',
                'PS Project Phase SaaS'
        };

        System.debug('phaseProjectRecordTypeSet' + phaseProjectRecordTypeSet);

        System.debug('newList in calculatePhaseImpQuantityNPercentage' + newList);

        Set<Id> projectIds = new Set<Id>();

        Map<String, Schema.RecordTypeInfo> recordTypeNameMap = Schema.SObjectType.Project__c.getRecordTypeInfosByName();
        Set<Id> psPhaseProjectIdSet = new Set<Id>();
        for(String psPhaseProject :  phaseProjectRecordTypeSet){
            psPhaseProjectIdSet.add(recordTypeNameMap.get(psPhaseProject).recordTypeId);
        }

        for(Project__c newProject : newList) {
            System.debug('newProject.RecordType.Name' + newProject.RecordType.Name);
            System.debug('newProject.Phase_Status__c' + newProject.Phase_Status__c);
            if (psPhaseProjectIdSet.contains(newProject.RecordTypeId)) {
                //System.debug('projectRecordType[0].RecordType.Name' + projectRecordType[0].RecordType.Name);
                if ((newProject.Phase_Status__c == 'Closed' && oldMap.get(newProject.Id).Phase_Status__c != 'Closed')
                        || (newProject.ActualProjectGoLiveDate__c != null && oldMap.get(newProject.Id).ActualProjectGoLiveDate__c == null)) {
                    System.debug('newProject.Phase_Status__c' + newProject.Phase_Status__c);
                    projectIds.add(newProject.Id);
                }
            }
        }

        // skip processing if none of the records meet the criteria
        if(projectIds.isEmpty()){
            return;
        }

        List<Project_Asset_Allocation__c> listProjectAssetAllocations = new List<Project_Asset_Allocation__c>(
        [Select Id, Asset__c, Percent_Allocation__c, Implemented__c, Phase_Allocated__c,Phase_Implemented__c, PhaseImplemented__c, Phase_Implemented_Quantity__c,
                Quantity_Allocation__c from  Project_Asset_Allocation__c where Project__c IN : projectIds]);

        List<Project_Asset_Allocation__c> updateProjectAssetAllocationsList = new List<Project_Asset_Allocation__c>();
        Set<Id> assetIds = new Set<Id>();
        List<Asset> updateAssetList = new List<Asset>();

        for(Project_Asset_Allocation__c projectAssetAllocation: listProjectAssetAllocations){
            updateProjectAssetAllocationsList.add(new Project_Asset_Allocation__c(Id = projectAssetAllocation.Id,
                    Phase_Implemented_Quantity__c = projectAssetAllocation.Quantity_Allocation__c,
                    PhaseImplemented__c = projectAssetAllocation.Percent_Allocation__c,
                    Implemented__c = true));
            assetIds.add(projectAssetAllocation.Asset__c);
        }

        if(updateProjectAssetAllocationsList.size() > 0)
            update updateProjectAssetAllocationsList;


        List<Project_Subscription_Allocation__c> listProjectSubscriptionAllocations = new List<Project_Subscription_Allocation__c>(
        [Select Id, Subscription__c, Phase_Implemented_Quantity__c, Phase_Implemented__c, Subscription__r.Subscription__c,
                Phase_Allocated__c, Percent_Allocation__c, PhaseImplemented__c, Quantity_Allocation__c from  Project_Subscription_Allocation__c where Project__c IN : projectIds]);

        System.debug('listProjectSubscriptionAllocations' + listProjectSubscriptionAllocations);
        List<SBQQ__Subscription__c> updateSubscriptionList = new List<SBQQ__Subscription__c>();
        Set<Id> subscriptionIds = new Set<Id>();

        List<Project_Subscription_Allocation__c> upProjectSubscriptionAllocationsList = new List<Project_Subscription_Allocation__c>();

        for(Project_Subscription_Allocation__c projectSubscriptionAllocation: listProjectSubscriptionAllocations) {
            upProjectSubscriptionAllocationsList.add(new Project_Subscription_Allocation__c(Id = projectSubscriptionAllocation.Id,
                    Phase_Implemented_Quantity__c = projectSubscriptionAllocation.Quantity_Allocation__c,
                    PhaseImplemented__c = projectSubscriptionAllocation.Percent_Allocation__c,
                    Implemented__c = true));

            if (!subscriptionIds.contains(projectSubscriptionAllocation.Subscription__c)) {
                subscriptionIds.add(projectSubscriptionAllocation.Subscription__c);
                updateSubscriptionList.add(new SBQQ__Subscription__c(Id = projectSubscriptionAllocation.Subscription__r.Subscription__c, Status__c = '4 - Delivered'));
            }
        }

        if(upProjectSubscriptionAllocationsList.size() > 0)
            update upProjectSubscriptionAllocationsList;

        if(updateSubscriptionList.size() > 0)
            update updateSubscriptionList;


        updateAssetList = new List<Asset>([SELECT Id, Quantity, Status, Total_Implemented_Quantity__c, QuantityCancelled__c, FullyImplemented__c from Asset where Id IN : assetIds ]);

        for(Asset updateAsset: updateAssetList){
            System.debug('updateAsset' + updateAsset);
            Decimal cancelledQuantity = 0.00;
            if(updateAsset.QuantityCancelled__c != null)
                cancelledQuantity = updateAsset.QuantityCancelled__c;

            updateAsset.Status = '4 - Delivered';

            if((updateAsset.Total_Implemented_Quantity__c + cancelledQuantity >= updateAsset.Quantity)){
                updateAsset.FullyImplemented__c = true;
            }
        }

        if(updateAssetList.size() > 0)
            update updateAssetList;

        List<SubscriptionReplica__c> updateSubscriptionCustomList = new List<SubscriptionReplica__c>(
        [SELECT Id, Quantity__c, Status1__c, Total_Implemented_Quantity__c, QuantityCancelled__c, FullyImplemented__c from SubscriptionReplica__c where Id IN : subscriptionIds]);

        for(SubscriptionReplica__c updateSubscriptionCustom: updateSubscriptionCustomList){
            System.debug('updateSubscriptionCustom' + updateSubscriptionCustom);
            Decimal cancelledQuantity = 0.00;
            if(updateSubscriptionCustom.QuantityCancelled__c != null)
                cancelledQuantity = updateSubscriptionCustom.QuantityCancelled__c;

            if((updateSubscriptionCustom.Total_Implemented_Quantity__c + cancelledQuantity >= updateSubscriptionCustom.Quantity__c)){
                updateSubscriptionCustom.FullyImplemented__c = true;
            }
        }

        if(updateSubscriptionCustomList.size() > 0)
            update updateSubscriptionCustomList;

    }
}