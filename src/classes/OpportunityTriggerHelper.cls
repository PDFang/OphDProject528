public class OpportunityTriggerHelper {
    public static final string PS_PROJECT_PARENT_SAAS = 'PS Parent Project - SaaS';
    public static final string PS_PROJECT_PHASE_SAAS = 'PS Project Phase SaaS';
    public static final Set<String> profileSet = new Set<String>{
            'Implementation Management',
            'Implementation Management - Agent Console',
            'Sales Rep - Outlook Connector Enabled',
            'PS Management'
    };
    private static Map<Id, String> profileMap = null;
    private static Map<String,Schema.RecordTypeInfo> OpportunityRecordTypes = null;

    public static final String OPPORTUNITY_STAGE_ONE = '1 - Identification / Qualification';
    public static final String OPPORTUNITY_STAGE_TWO = '2 - Determining Problem / Impact';
    public static final String OPPORTUNITY_STAGE_THREE = '3 - Aligning Benefits & Value';
    public static final String OPPORTUNITY_STAGE_FOUR = '4 - Confirm Value & Agreement';
    public static final String OPPORTUNITY_STAGE_FIVE = '5 - Proposal / Negotiation';
    public static final String OPPORTUNITY_STAGE_SIX = '6 - Pending';
    public static final String OPPORTUNITY_STAGE_CLOSED_WON = 'Closed – Won';
    private static final Map<String, Integer> stageRankMap = new Map<String, Integer>{
            OPPORTUNITY_STAGE_ONE => 1,
            OPPORTUNITY_STAGE_TWO => 2,
            OPPORTUNITY_STAGE_THREE => 3,
            OPPORTUNITY_STAGE_FOUR => 4,
            OPPORTUNITY_STAGE_FIVE => 5,
            OPPORTUNITY_STAGE_SIX => 6,
            OPPORTUNITY_STAGE_CLOSED_WON => 7
    };
    private static Integer getStageRank(String stageName){
        return stageRankMap.containsKey(stageName) ? stageRankMap.get(stageName) : -1;
    }

    private static Id GetOpportunityRecordTypeIdByName(string recordTypeName){
        if(OpportunityRecordTypes == null){
            OpportunityRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        }

        return OpportunityRecordTypes.get(recordTypeName).getRecordTypeId();
    }


    public static void updateTimeStamps(list<Opportunity> newOppList){
        String eduOppRT = GetOpportunityRecordTypeIdByName('Education Request');
        String saasRT = GetOpportunityRecordTypeIdByName('SaaS Request');
        for(Opportunity o:newOppList)
        {
            if(o.RecordTypeId == saasRT)
            {
                o.Sales_Developer__c = Userinfo.getUserId();
            }
            if(o.RecordTypeId == eduOppRT)
            {
                o.RequestDate__c = system.now();
            }

        }
//        OpportunityTriggerHelper.timestampHelper(newOppList);
    }

    // create trip reports for Education request opportunities
    public static void createTripAndProjects(list<Opportunity> newOppList){
        String eduTRRT = inContactBaseClass.SelectRecordTypeIDByName('Education Trip', 'Trip_Report__c');
        String eduOppRT = GetOpportunityRecordTypeIdByName('Education Request');
        String psChangeProj = inContactBaseClass.SelectRecordTypeIDByName('PS Change Request Phase', 'Project__c');

        Map<Id,Trip_Report__c> trList = new Map<Id,Trip_Report__c>();
        List<Opportunity> opList = new List<Opportunity>();
        List<Project__c> projList = new List<Project__c>();

        //loop through opportunities and create trip reports.
        for(Opportunity o:newOppList)
        {
            if(o.PSEducationConsultant__c != NULL && o.TripReport__c == NULL && o.RecordTypeId == eduOppRT)
            {
                Trip_Report__c tr = new Trip_Report__c();
                tr.Account__c = o.AccountId;
                tr.Status__c = 'New';
                tr.RecordTypeId = eduTRRT;
                tr.AssignedTo__c = o.PSEducationConsultant__c;

                trList.put(o.Id,tr);

                //create new PS Change Request Project
                Project__c p = new Project__c();
                p.Opportunity__c = o.Id;
                p.Summary__c = o.Name;
                p.RecordTypeId = psChangeProj;
                p.Account__c = o.AccountId;
                p.Team__c = 'Education Services';
                p.OwnerId = o.PSEducationConsultant__c;
                p.PlannedStartDate__c = o.RequestedTrainingDate__c;

                projList.add(p);
            }

        }
        if(!trList.isEmpty())
        {
            //insert trip reports
            insert trList.values();

            //loop through opportunities in the trip reports and add the trip report ID to the opp
            for(Opportunity no:[SELECT Id, TripReport__c FROM Opportunity WHERE ID IN:trList.keySet()])
            {
                no.TripReport__c = trList.get(no.Id).Id;

                opList.Add(no);
            }

            update opList;
        }

        if(!projList.isEmpty())
        {
            for(Project__c p:projList)
            {
                p.TripReport__c = trList.get(p.Opportunity__c).Id;
            }

            insert projList;
        }


    }

    //salesengineer reassigned
    public static void salesEnginnerReassign(list<Opportunity> newOppList, map<Id, Opportunity> oldOppMap, boolean isInserted){
        Schema.DescribeSObjectResult projectSchema = Schema.SObjectType.Project__c;
        Map<String,Schema.RecordTypeInfo> projectRecordTypeMapByName = projectSchema.getRecordTypeInfosByName();
        Id salesEngineeringProjectRecordTypeId = projectRecordTypeMapByName.get('Sales Engineering Project').getRecordTypeId();
        Set<Id> salesEngineerReassigned = new Set<Id>();
        //String wfoPremiseOpp = inContactBaseClass.SelectRecordTypeIDByName('WFO Premise', 'Opportunity');
        //Project #75777 - Label changed from 'WFO Premise' to 'Qualified WFO Premise'
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        String wfoPremiseQualifiedOpp = rtMapByName.containsKey('Qualified WFO Premise')
                    ? rtMapByName.get('Qualified WFO Premise').getRecordTypeId() : null;
        String wfoPremiseNewOpp = rtMapByName.containsKey('New WFO Premise')
                    ? rtMapByName.get('New WFO Premise').getRecordTypeId() : null;

        for(Opportunity o : newOppList)
        {

            if(o.RecordTypeId != wfoPremiseQualifiedOpp && o.RecordTypeId != wfoPremiseNewOpp)
            {
                if(isInserted && o.SalesEngineer__c != null)
                {
                    salesEngineerReassigned.add(o.Id);
                }
                else if(!isInserted)
                {


                    if(oldOppMap.get(o.Id).SalesEngineer__c != o.SalesEngineer__c && o.SalesEngineer__c != null)
                    {
                        salesEngineerReassigned.add(o.Id);
                    }
                }
            }
        }

        if(!salesEngineerReassigned.isEmpty())
        {
            SalesEngineeringLogic.OpportunitySalesEngineerReassigned(salesEngineerReassigned, salesEngineeringProjectRecordTypeId);
        }

    }

    //update timestamp when opportunity stage changes
    public static void timestampHelper(list<Opportunity> newOppList, Map<Id, Opportunity> oldMap){

        for( Opportunity newOpp : newOppList)
        {
            Integer newRank = getStageRank(newOpp.StageName);
            String previousStage = (oldMap != null) ? oldMap.get(newOpp.Id).StageName : null;
            Integer oldRank = getStageRank(previousStage);

            system.debug('timestampHelper(): new StageName - '+ newOpp.StageName + ', rank #'+ newRank);
            system.debug('timestampHelper(): previous StageName - '+ previousStage + ', rank #'+ oldRank);
            if(String.isNotBlank(previousStage) && newOpp.StageName == previousStage){
                continue;
            }
            if(newRank == 2 || ( newRank > 2 && oldRank < 2 && oldRank > 0) ){
                newOpp.Stage_2_Timestamp__c = system.today();
            }
            if(newRank == 3 || ( newRank > 3 && oldRank < 3 && oldRank > 0) ){
                newOpp.Stage_3_Timestamp__c = system.today();
            }
            if(newRank == 4 || ( newRank > 4 && oldRank < 4 && oldRank > 0) ){
                newOpp.Stage_4_Timestamp__c = system.today();
            }
            if(newRank == 5 || ( newRank > 5 && oldRank < 5 && oldRank > 0) ){
                newOpp.Stage_5_Timestamp__c = system.today();
            }
            if(newRank == 6 || ( newRank > 6 && oldRank < 6 && oldRank > 0) ){
                newOpp.Stage_6_Timestamp__c = system.today();
            }

            system.debug('timestampHelper(): Stage_2_Timestamp__c - '+ newOpp.Stage_2_Timestamp__c);
            system.debug('timestampHelper(): Stage_3_Timestamp__c - '+ newOpp.Stage_3_Timestamp__c);
            system.debug('timestampHelper(): Stage_4_Timestamp__c - '+ newOpp.Stage_4_Timestamp__c);
            system.debug('timestampHelper(): Stage_5_Timestamp__c - '+ newOpp.Stage_5_Timestamp__c);
            system.debug('timestampHelper(): Stage_6_Timestamp__c - '+ newOpp.Stage_6_Timestamp__c);
        }

    } // end of timestampHelper()

    // all other Update operations -
    // Chatter Closed deal update
    // if record type changes from CS-Upsells change the owner and update probability
    // if stage = 2 - determining problem/impact & record type is new, update record type = qualified opportunity
    // purchased hours for PS requests
    // if stage changes update the stage timestamp
    public static void performOtherOperations(list<Opportunity> newOppList, map<Id, Opportunity> oldOppMap){
        string r = GetOpportunityRecordTypeIdByName('SaaS Request');
        string rQualified = GetOpportunityRecordTypeIdByName('Qualified Opportunity');
        string rNew = GetOpportunityRecordTypeIdByName('New Opportunity');
        String psRequestRecordType = GetOpportunityRecordTypeIdByName('GSD PS Requests');

        Set<ID> closedDeals = new Set<Id>();
        Map<Id, List<Opportunity>> psRequestsGoLive = new Map<Id, List<Opportunity>>();

        list<Opportunity> updateOpportunityList = new list<Opportunity>();

        for(Opportunity o:newOppList)
        {
            ID recTypeIDold = oldOppMap.get(o.Id).RecordTypeId;
            ID recTypeIDnew = o.RecordTypeId;
            // Chantter Closed deal update
            if(o.PostClosedDealChatter__c)
            {
                o.PostClosedDealChatter__c = false;
                closedDeals.add(o.Id);
            }
            // record type change
            if(recTypeIDnew != recTypeIDold)
            {

                if(recTypeIDold == r)//if the old record type equals CS-Upsells
                {
                    o.OwnerId = o.Account_Sales_Rep__c;//the opportunity owner is update to the account sales rep
                    o.Probability = 25;//update probability to 25%
                }
            }
            // update the record type
            if(o.StageName == '2 - Determining Problem / Impact')//if the current stage equals "2 - Determining Problem / Impact"
            {

                if(recTypeIDnew == rNew)//if the current record type not equal to Qualified_Opportunity;
                {
                    o.RecordTypeId = rQualified;
                }
            }
            //check for purchased hours for PS requests
            if(o.RecordTypeId == psRequestRecordType)
            {
                if(oldOppMap.get(o.Id).PM_Go_Live_Date__c == null && o.PM_Go_Live_Date__c != null)
                {
                    if(psRequestsGoLive.containsKey(o.AccountId))
                    {
                        psRequestsGoLive.get(o.AccountId).add(o);
                    }
                    else
                    {
                        List<Opportunity> psOpps = new List<Opportunity>();
                        psOpps.add(o);
                        psRequestsGoLive.put(o.AccountId, psOpps);
                    }
                }
            }
            if(o.StageName != oldOppMap.get(o.Id).StageName)
                updateOpportunityList.add(o);
        }

//        if(!updateOpportunityList.isEmpty())
//            OpportunityTriggerHelper.timestampHelper(updateOpportunityList);

        if(!closedDeals.isEmpty())
            ChatterUpdates.ChatterPostClosedDeal(closedDeals);

        if(!psRequestsGoLive.isEmpty())
            OpportunityProcessing.PsHoursValidation(psRequestsGoLive);
    }

    //Description: Update the Account Sales Rep field to equal the Active Sales Rep field on the account
    //so the CS Upsells are assigned to the proper sales rep.
    public static void updateSalesRepFromAccount(list<Opportunity> newOppList){
        Set<ID> accountIds = new Set<Id>();
        for(Opportunity o:newOppList)
            accountIds.add(o.AccountId);
        Map<Id,Account> accounts = new Map<Id,Account>([SELECT Id, Active_Sales_Rep__c FROM Account WHERE Id IN :accountIds]);
        for(Opportunity o:newOppList)
        {
            Account a = accounts.get(o.AccountId);
            if(accounts.containsKey(o.AccountId))
            {
                if (o.Account_Sales_Rep__c!=a.Active_Sales_Rep__c)
                {
                    //update the account sales rep on the opportunity
                    o.Account_Sales_Rep__c = a.Active_Sales_Rep__c;
                }
            }
        }
    }

    //update sales rep on Opportunity
    public static void updateSalesRep(list<Opportunity> newOppList,boolean isInserted){
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> sdOwnerIds = new Set<Id>();
        Map<Id, User> owners = new map<id, user>();
        for(Opportunity x:newOppList){
            if(string.valueOf(x.OwnerId).startsWith('005'))
                ownerIds.add(x.OwnerId);
        }


        if (ownerIds.size() > 0)
        {
            owners = new Map<Id, User>([SELECT Id, UserRole.Name FROM User WHERE Id IN :ownerIds
            AND (UserRole.Name IN :InContactConfiguration.salesRoles)]);
            for(Opportunity o:newOppList)
            {
                if(!isInserted)
                {
                    if(o.Sales_Rep__c != o.OwnerId && owners.ContainsKey(o.OwnerId))
                        o.Sales_Rep__c = o.OwnerId;
                }
                else
                {
                    if(owners.ContainsKey(o.OwnerId))
                        o.Sales_Rep__c = o.OwnerId;
                }

            }

        }

    }

    // Prevent implementation managers (IM) from checking the "Handed off to CC/CS" checkbox on the opportunity record until all related SaaS project phases are complete
    public static void isAvailableForCCHandOff(List<Opportunity> newList, Map<Id, Opportunity> oldMap){

        Set<Id> oppIdSet = new Set<Id>();
        List<Opportunity> processList = new List<Opportunity>();
        for(Opportunity newOpp : newList){
            Opportunity oldOpp = (oldMap == null) ? null : oldMap.get(newOpp.Id);
            if(newOpp.HandedOffToCCCS__c && ( oldOpp == null || !oldOpp.HandedOffToCCCS__c) ){
                oppIdSet.add(newOpp.Id);
                processList.add(newOpp);
            }
        }
        system.debug( 'isAvailableForCCHandOff(): oppIdSet - '+oppIdSet);
        if(oppIdSet.isEmpty()){
            return;
        }

        if(profileMap == null){
            profileMap = new Map<Id, String>();
            for(Profile p: [Select Id, Name from Profile where Name IN :profileSet]){
                profileMap.put(p.Id, p.Name);
            }
        }
        system.debug( 'isAvailableForCCHandOff(): profileMap - '+profileMap);

        String profileName = profileMap.get(userInfo.getProfileId());
        system.debug( 'isAvailableForCCHandOff(): profileName - '+profileName);
        if(profileName == null || profileSet.contains(profileName) == false){
            return;
        }

        Set<Id> oppNotReadySet = new Set<Id>();
        for(Project__c psPhase : [
                Select Id, ParentProject__r.Opportunity__c from Project__c
                where RecordType.Name = :PS_PROJECT_PHASE_SAAS and ParentProject__r.RecordType.Name = :PS_PROJECT_PARENT_SAAS
                and ParentProject__r.Opportunity__c IN :oppIdSet
                and Phase_Status__c not in('Closed', 'Cancelled', 'Suspended')
        ]){
            oppNotReadySet.add(psPhase.ParentProject__r.Opportunity__c);
        }
        system.debug( 'isAvailableForCCHandOff(): oppNotReadySet - '+oppNotReadySet);

        for(Opportunity newOpp : processList){
            if(oppNotReadySet.contains(newOpp.Id)){
                newOpp.addError('All project phases must be closed before an opportunity can be handed off to CC/CS.');
            }
        }

    } // end of isAvailableForCCHandOff()

}