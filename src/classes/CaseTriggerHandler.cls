public class CaseTriggerHandler extends TriggerHandler
{
    private static boolean staticValuesSet = false;
    private static boolean isProxyServiceTurnedOff = false;
    @TestVisible
    private static Integer noOfProxyServiceCallouts = 0;
    private static boolean isxMattersNotificationsTurnedOff = false;
    private static String xmEventNotificationPriorities = 'P1;P2;';
    public static Id eventRecordType;
    private static Id maintenanceRecordType;
    private static Id knownIssueRecordType;
    private static Id incidentRecordType;
    private static Id problemRecordType;
    private static Id incidentUptivityRecordType;
    private static Id serviceRequestRecordType;
    private static Id workOrderRecordType;
    private static Id workOrderUptivityRecordType;
    private static Id helpDeskRCTypeId;
    public static Set<String> closedStatuses;
    private static SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(inContactBaseClass.OrgId15Digit);
    public static boolean callActionHub = true;
    public static String JIRA_KEY_TEMP = Label.JIRA_Temporary_Key;
    public static boolean createJiraBug = false;
    public static boolean bypassProxyService = false;
    private Static Map<String, ETMS_Trouble_Report_State_Status__mdt> etmsTroubleStateStatusMap;
    private static boolean isInsertCall = false;
    private Set<Id> affectedQueueIDs = new Set<ID>();
    private Set<Id> affectedUserIDs = new Set<ID>();
    private Set<Id> parentCaseIds = new Set<Id>();
    private Set<Id> closedHelpdeskCaseIds = new Set<ID>();
    private List<Id> closedCasesForEntitlements = new List<ID>();
    public static Map<ID,Group> allQueues = new Map<ID,Group>();
    public static Map<ID,SET<ID>> queueUsers = new Map<ID,SET<ID>>();
    private Map<Id,String> eventCasePriorities = new Map<Id,String>();
    private static Set<Id> attachedToKnownIssue = new Set<Id>();

    /**
    * Name: Transposition of CaseAfterUpdate, consolidation of case update functionality
    * Created By: Phil Dennison Fang
    * Version: 1.01
    * Date: May 25, 2018
    */

    private static Schema.DescribeSObjectResult desObjRslt;
    private static Map<String,Schema.RecordTypeInfo> recTMapNamCaseUp;

    //Get Order management record type
    private static Id rBllRcType;
    private static Id ctrAudtRcType;
    private static Id knwnIssueRcType;

    private static List<Approval.ProcessSubmitRequest> reqstLst;
    private static Set<Id> evtMngerChange;
    private static List<Task> tsk;
    private static List<CaseComment> cscomm;
    private static List<Case> cas;
    private static Set<String> closedStatusesScnd;
    private static Set<ID> reOpenCas;
    private static Set<Id> closKnownIsse;


    public CaseTriggerHandler()
    {
        if(!staticValuesSet)
        {
            SetRecordTypeIds();
            GetClosedCaseStatuses();
            staticValuesSet = true;
            AppConfiguration__c config = AppConfiguration__c.getInstance();
            if(config != null) {
                isProxyServiceTurnedOff = config.Turn_Off_Partner_Case_Proxy_Service__c;
                isxMattersNotificationsTurnedOff = config.XM_Turn_Off_Event_Notifications__c;
                xmEventNotificationPriorities = String.isNotBlank(config.XM_Event_Notification_Priorities__c) ? config.XM_Event_Notification_Priorities__c : xmEventNotificationPriorities;
            }
            etmsTroubleStateStatusMap = new Map<String, ETMS_Trouble_Report_State_Status__mdt>();
            for(ETMS_Trouble_Report_State_Status__mdt mdt : [
                    Select Case_Status__c, Trouble_Report_State__c, Trouble_Report_Status__c
                    From ETMS_Trouble_Report_State_Status__mdt
            ]){
                etmsTroubleStateStatusMap.put(mdt.Case_Status__c.toLowerCase(), mdt);
            }
        }
    }

    protected override void beforeInsert(){
        isInsertCall = true;
        //CalculateIncidentNetScore((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
        setTroubleReportStateStatus((List<Case>) trigger.new, (Map<Id, Case>)trigger.oldMap);
    }

    protected override void beforeUpdate(){
        Map<Id, Case> oldCases = (Map<Id, Case>)trigger.oldMap;
        List<Case> newCases = (List<Case>)trigger.new;

        for(Case newCase:newCases){
            Case oldCase = oldCases.get(newCase.Id);
            storeQueryValues(newCase);
        }
        SetAllQueues();
        SetEventPriorities();

        for(Case newCase:newCases){
            Case oldCase = oldCases.get(newCase.Id);
            setTimestamps(newCase, oldCase);
            setPriority(newCase);
            ClosedCases(newCase, oldCase);
            OwnerAndAssignedToChanged(newCase, oldCase);
            EventActions(newCase, oldCase);
            ResolvedCases(newCase, oldCase);
            GetSurveyCases(newCase, oldCase);
        }

        CalculateIncidentNetScore(newCases, oldCases);
        setCaseStatusFlags(newCases, oldCases);
        setTroubleReportStateStatus(newCases, oldCases);
        KnownIssueCheck();
        SendSurveys();
        CaseOwnershipClass.updateCaseOwnerShip(Trigger.new,allqueues);
        CloseEntitlements();
    }


    protected override void afterInsert(){
        createJiraBugForKI((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
        if(!isProxyServiceTurnedOff && noOfProxyServiceCallouts == 0 && !bypassProxyService)
            CallPartnerCaseProxyService((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
    }

    protected override void afterUpdate(){
        createJiraBugForKI((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
        if(!isxMattersNotificationsTurnedOff)
            createXmNotification((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
        if(!isProxyServiceTurnedOff && noOfProxyServiceCallouts == 0 && !bypassProxyService)
            CallPartnerCaseProxyService((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);

        /** Name: Transposition of CaseAfterUpdate, combining case update logic, created By: Phil Dennison Fang **/
        desObjRslt = Schema.SObjectType.Case;
        recTMapNamCaseUp = desObjRslt.getRecordTypeInfosByName();

        rBllRcType = recTMapNamCaseUp.get('Re-Bill Request').getRecordTypeId();
        ctrAudtRcType = recTMapNamCaseUp.get('Contract Billing Audit').getRecordTypeId();
        knwnIssueRcType = recTMapNamCaseUp.get('Known Issue').getRecordTypeId();

        reqstLst = new List<Approval.ProcessSubmitRequest>();
        evtMngerChange = new Set<Id>();
        tsk = new List<Task>();
        cscomm = new List<CaseComment>();
        cas = new List<Case>();
        closedStatusesScnd = CaseAssignmentClass.GetClosedStatuses();
        reOpenCas = new Set<Id>();
        closKnownIsse = new Set<id>();

        for(integer i=0; i<trigger.new.size(); i++) {
            Case oldRec = (Case)trigger.old[i];
            Case newRec = (Case)trigger.new[i];
            //submit contract audits for approval
            if(!closedStatusesScnd.contains(oldRec.Status) && closedStatusesScnd.contains(newRec.Status) && newRec.RecordTypeId == ctrAudtRcType) {
                Approval.ProcessSubmitRequest appReqst1 = new Approval.ProcessSubmitRequest();
                appReqst1.setComments('Submitting Contract Audit for approval.');
                appReqst1.setObjectId(newRec.id);
                Approval.ProcessResult appReslt = Approval.process(appReqst1);
            }
            if(!closedStatusesScnd.contains(oldRec.Status) && closedStatusesScnd.contains(newRec.Status) && newRec.RecordTypeId == knownIssueRecordType) {
                closKnownIsse.add(newRec.Id);
            }
            if(oldRec.EventCommander__c != newRec.EventCommander__c) {
                evtMngerChange.add(newRec.Id);
            }
            if(newRec.RecordTypeId == rBllRcType) {
                if(oldRec.Status <> 'Request Review' && newRec.Status == 'Request Review') {
                    Approval.ProcessSubmitRequest appReqst1 = new Approval.ProcessSubmitRequest();
                    appReqst1.setComments('Submitting request for approval.');
                    appReqst1.setObjectId(newRec.id);
                    reqstLst.add(appReqst1);
                }
            }
            if(newRec.WorkDuration__c > 0 || newRec.PublicComment__c != NULL) {
                Case caseRec = newRec.Clone(true);
                caseRec.WorkDuration__c = NULL;
                caseRec.PublicComment__c = NULL;
                cas.add(caseRec);
            }
            //check for work duration and public comment
            if(newRec.WorkDuration__c > 0) {
                Task tskRec = new Task();
                tskRec.ActivityDate = date.today();
                tskRec.WhatId = newRec.Id;
                tskRec.WorkDuration__c = newRec.WorkDuration__c;
                tskRec.Subject = 'Log Time on Case ' + String.valueof(newRec.CaseNumber);
                tskRec.Status = 'Completed';
                tskRec.Type = 'Time Tracking';
                tsk.add(tskRec);
            }
            if(newRec.PublicComment__c != NULL) {
                CaseComment ccmt = new CaseComment();
                ccmt.CommentBody = newRec.PublicComment__c;
                ccmt.ParentId = newRec.Id;
                ccmt.IsPublished = true;
                cscomm.add(ccmt);
            }
            //remove resolved date
            if((newRec.Status != 'Resolved' && !closedStatuses.contains(newRec.Status) && oldRec.ResolvedDate__c != NULL)) {
                reOpenCas.add(newRec.Id);
            }
            if(oldRec.KnownIssue__c != NULL && newRec.KnownIssue__c == NULL) {
                Case reAssgCas = newRec.clone(true); //set default assignment rule
                database.DMLOptions dbMo = new database.DMLOptions();
                dbMo.assignmentRuleHeader.useDefaultRule = true;
                reAssgCas.setOptions(dbMo);
                cas.add(reAssgCas);
            }
        }

        if(!reqstLst.isEmpty())
            List<Approval.ProcessResult> appReslt = Approval.process(reqstLst);
        //create case comments
        if(!cas.isEmpty())
            update cas;
        //create tasks
        if(!tsk.isEmpty())
            insert tsk;
        //create case comments
        if(!cscomm.isEmpty())
            insert cscomm;
        if(!evtMngerChange.isEmpty()) {
            List<RCA__c> rcaUpdList = new List<RCA__c>();
            for(RCA__c rcaRecrd :[SELECT Id, EventCommander__c, Event__r.EventCommander__c FROM RCA__c WHERE Event__c IN :evtMngerChange]) {
                rcaRecrd.EventCommander__c = rcaRecrd.Event__r.EventCommander__c;
                rcaUpdList.add(rcaRecrd);
            }
            update rcaUpdList;
        }
        if(!reOpenCas.isEmpty() && !System.isFuture())
            CaseAssignmentClass.ReopenSlaMilestone(reOpenCas);
        if(!closKnownIsse.isEmpty())
            CaseAssignmentClass.KnowIssueClosed(closKnownIsse);
        //case trigger merge --End
    }

    private void setCaseStatusFlags(List<Case> updateList, Map<Id, Case> oldMap) {
        for(Case updatedCase : updateList) {
            Case oldCase = (oldMap != null) ? oldMap.get(updatedCase.Id) : null;
            if(updatedCase.RecordTypeId == eventRecordType && !updatedCase.EventHasBeenResolvedOrClosed__c
                    && updatedCase.xmEvent_Notification_Sent__c
                    &&((updatedCase.Status == 'Resolved' && oldCase.Status != 'Resolved')
                    || (updatedCase.Status == 'Closed' && oldCase.Status != 'Closed'))) {
                //set the flag showing that the event has been in resolved or closed status
                updatedCase.EventHasBeenResolvedOrClosed__c = true;
            }
        }
    }

    private void SetRecordTypeIds()
    {
        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        //Get Event record type id
        eventRecordType = rtMapByName.get('Event').getRecordTypeId();
        maintenanceRecordType = rtMapByName.get('Maintenance Notification').getRecordTypeId();
        knownIssueRecordType = rtMapByName.get('Known Issue').getRecordTypeId();
        incidentRecordType = rtMapByName.get('Incident').getRecordTypeId();
        problemRecordType = rtMapByName.get('Problem').getRecordTypeId();
        incidentUptivityRecordType = rtMapByName.get('Incident - Premise').getRecordTypeId();
        serviceRequestRecordType = rtMapByName.get('Service Request').getRecordTypeId();
        workOrderRecordType = rtMapByName.get('Work Orders').getRecordTypeId();
        workOrderUptivityRecordType = rtMapByName.get('Work Orders - Premise').getRecordTypeId();
        helpDeskRCTypeId = rtMapByName.get('Help Desk').getRecordTypeId(); // Added the HelpDesk RecordType - Arnab
    }

    private void GetClosedCaseStatuses()
    {
        closedStatuses = new Set<String>();
        //get all closed statuses
        for(CaseStatus cs:[SELECT MasterLabel FROM CaseStatus WHERE IsClosed = true])
        {
            closedStatuses.add(cs.MasterLabel);
        }
    }

    private void CalculateIncidentNetScore(List<Case> newList, Map<Id, Case> oldMap){

        List<Case> processList = new List<Case>();
        for(Case newCase : newList){
            Case oldCase = (oldMap != null) ? oldMap.get(newCase.Id) : null;
            // Is new incident
            if(newCase.RecordTypeId == incidentRecordType && (oldCase == null || recalculateScore(newCase, oldCase) || isInsertCall) ){
                processList.add(newCase);
            }
        }
        system.debug('CalculateIncidentNetScore(): processList - ' + processList);

        if(processList.size() > 0){
            try{
                ImpactCalculationService calculationService = new ImpactCalculationService(new IncidentImpactCalculationImplementation());
                calculationService.CalculateIncidentNetScore(processList);
            }catch(System.Exception ex){
                inContactBaseClass.SendErrorEmail(ex, processList[0].CaseNumber);
            }

        }

    } // end of calculateIncidentNetScore()

    private boolean recalculateScore(Case newRecord, Case oldRecord){
        return newRecord.Severity__c != oldRecord.Severity__c
                || newRecord.Priority != oldRecord.Priority
                || newRecord.RepeatIssue__c != oldRecord.RepeatIssue__c
                || newRecord.Related_to_Previous_Known_Issue__c != oldRecord.Related_to_Previous_Known_Issue__c
                || newRecord.Security_Issue__c != oldRecord.Security_Issue__c;
    }

    // Create an xmNotification record when an event is confirmed or resolved
    private void createXmNotification(List<Case> newList, Map<Id, Case> oldMap){

        List<Case> processList = new List<Case>();
        string platformsAdded = '',
                requestType = '';

        //for each case that is resolved or closed, determine whether the resolved notification
        //has already been sent
        Set<Id> caseIds = new Set<Id>();
        for(Case c : newList) {
            if(c.Status == 'Resolved' || c.Status == 'Closed') {
                caseIds.add(c.Id);
            }
        }

        if(caseIds.size() > 0){
            //retrieve the newest resolved notification, if there is one, for the cases in the set
            List<AggregateResult> resolvedNotifications = [
                    Select Case__c
                    from xmNotification__c
                    where Status__c = 'Completed' and Request_Type__c = 'Event Resolved'
                    and Case__c in :caseIds
                    group by Request_Type__c, Case__c
            ];
            caseIds.clear();
            for(AggregateResult notification : resolvedNotifications) {
                caseIds.add((Id)notification.get('Case__c'));
            }
        }


        for(Case newCase : newList){
            Case oldCase = (oldMap != null) ? oldMap.get(newCase.Id) : null;
            // Is Event confirmed
            system.debug('createXmNotification(): new status - ' + newCase.Status);
            system.debug('createXmNotification(): old status - ' + oldCase.Status);

            //ensure the case is an Event, and it was not just created (oldCase is not null), and
            //that it was not internal
            //and that the non event checkbox is unchecked
            //the Priority of the case must be in the list of xmEventNotificationPriorities or don't send
            if(oldCase != null && isQualifiedEvent(newCase))
            {

                //status is equal to Confirmed or Being Worked and no Event Confirmation notification has been sent
                if((newCase.Status == 'Confirmed' || newCase.Status == 'Being Worked' || newCase.Status == 'Validation')  //status is Confirmed or Being Worked
                        && !newCase.xmEvent_Notification_Sent__c) { //no notification has been sent
                    System.debug('Initial event');
                    processList.add(newCase);
                }
                else if((newCase.Status == 'Resolved' || newCase.Status == 'Closed') //event is Resolved or Closed
                        && newCase.xmEvent_Notification_Sent__c  //an event Confirmation has been sent
                        && !oldCase.EventHasBeenResolvedOrClosed__c) { //check to ensure that the event has never been resolved or closed

                    //if a resolved notification has not been sent, then send it
                    if(!caseIds.contains(newCase.Id)) {
                        System.debug('Resolved event');
                        processList.add(newCase);
                    }
                }
                else if((newCase.Status == 'Confirmed' || newCase.Status == 'Being Worked' || newCase.Status == 'Validation') &&
                        newCase.PlatformsImpacted__c != oldCase.PlatformsImpacted__c && newCase.xmEvent_Notification_Sent__c){
                    System.debug('Add event');
                    requestType = 'Event Platforms Add';

                    Integer newPlatforms = 0;

                    for(string s : newCase.PlatformsImpacted__c.split(';'))
                    {
                        if(!oldCase.PlatformsImpacted__c.contains(s))
                        {
                            platformsAdded += s + ';';
                            newPlatforms ++;
                        }
                    }

                    // Only add the case if the platforms have been added ignore removing
                    if(newPlatforms > 0){
                        processList.add(newCase);
                    }
                }
            }
        }
        system.debug('platformsAdded(): platformsAdded - ' + platformsAdded);
        system.debug('createXmNotification(): processList - ' + processList);
        if(processList.isEmpty()){
            return;
        }

        Map<Id, CaseComment> caseCommentMap = new Map<Id, CaseComment>();

        for(CaseComment comment : [
                Select Id, ParentId, CommentBody from CaseComment
                where ParentId IN :processList and IsPublished = true
                order by ParentId, createddate
        ]){
            caseCommentMap.put(comment.ParentId, comment);
        }

        List<xmNotification__c> notificationList = new List<xmNotification__c>();

        for(Case newCase :processList){

            CaseComment lastComment = caseCommentMap.containsKey(newCase.Id) ? caseCommentMap.get(newCase.Id) : null;

            xmNotification__c xmNotification = new xmNotification__c(
                    Case__c = newCase.Id,
                    Request_Date__c = system.now(),
                    Request_Type__c = requestType == '' ? getXmNotificationRequestType(newCase) : requestType,
                    AddedPlatforms__c = platformsAdded,
                    Public_Comment__c = lastComment != null ? lastComment.CommentBody : null,
                    CommentId__c = lastComment != null ? lastComment.Id : null
            );
            notificationList.add(xmNotification);
        }
        system.debug('createXmNotification(): notificationList - ' + notificationList);

        try{
            insert notificationList;
        }catch(Exception ex){
            system.debug('createXmNotification(): Exception - ' + ex);
            newList[0].addError('Failed to create an xmNotification. '+ ex.getMessage());
        }finally {
            // avoid recursion
            isxMattersNotificationsTurnedOff = true;
        }

    }

    public boolean isQualifiedEvent(Case newCase){

        system.debug('isQualifiedEvent(): eventRecordType - ' + eventRecordType);
        return newCase.RecordTypeId == eventRecordType && !newCase.InternalEvent__c && !newCase.NonEvent__c
                && xmEventNotificationPriorities.containsIgnoreCase(newCase.Priority);

    }

    @TestVisible
    private string getXmNotificationRequestType(Case newCase){

        String requestType = null;

        if(newCase.RecordTypeId == eventRecordType && newCase.Status == 'Resolved' || newCase.Status == 'Closed'){
            requestType = 'Event Resolved';
        } else if(newCase.RecordTypeId == eventRecordType && newCase.Status == 'Confirmed' || newCase.Status == 'Being Worked' || newCase.Status == 'Validation'){
            requestType = 'Event Initial Confirmation';
        }

        return requestType;

    }

    // set Trouble Report State and Status
    private void setTroubleReportStateStatus(List<Case> newList, Map<Id, Case> oldMap){

        Decimal defaultState = Decimal.valueOf(Case.ETMS_Trouble_Report_State__c.getDescribe().getDefaultValueFormula());
        Decimal defaultStatus = Decimal.valueOf(Case.ETMS_Trouble_Report_Status__c.getDescribe().getDefaultValueFormula());

        for(Case newCase : newList) {
            Case oldCase = (oldMap != null) ? oldMap.get(newCase.Id) : null;

            if(newCase.isClone()){
                newCase.ETMS_Trouble_Report_State__c = defaultState;
                newCase.ETMS_Trouble_Report_Status__c = defaultStatus;
                newCase.X3rdPartyVendorTicket__c = null;
            }
            if(newCase.RecordTypeId == incidentRecordType && newCase.AccountBillingGroup__c == PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON
                    && oldCase != null && newCase.Status != oldCase.Status){

                String statusLowerCase = newCase.Status.toLowerCase();
                // 'Waiting on Customer', 'Waiting on Customer - No Auto Close', 'Resolved' and 'Closed' have been mapped
                if(etmsTroubleStateStatusMap != null && etmsTroubleStateStatusMap.containsKey(statusLowerCase)){
                    newCase.ETMS_Trouble_Report_State__c = etmsTroubleStateStatusMap.get(statusLowerCase).Trouble_Report_State__c;
                    newCase.ETMS_Trouble_Report_Status__c = etmsTroubleStateStatusMap.get(statusLowerCase).Trouble_Report_Status__c;
                } else if(closedStatuses.contains(newCase.Status) && etmsTroubleStateStatusMap != null && etmsTroubleStateStatusMap.containsKey('closed')){
                    newCase.ETMS_Trouble_Report_State__c = etmsTroubleStateStatusMap.get('closed').Trouble_Report_State__c;
                    newCase.ETMS_Trouble_Report_Status__c = etmsTroubleStateStatusMap.get('Closed').Trouble_Report_Status__c;
                } else{
                    newCase.ETMS_Trouble_Report_State__c = defaultState;
                    newCase.ETMS_Trouble_Report_Status__c = defaultStatus;
                }

                system.debug('setTroubleReportStateStatus(): Trouble report status changed from  - '
                        + oldCase.ETMS_Trouble_Report_Status__c + ' to ' + newCase.ETMS_Trouble_Report_Status__c);
                system.debug('setTroubleReportStateStatus(): Trouble report state changed from  - '
                        + oldCase.ETMS_Trouble_Report_State__c + ' to ' + newCase.ETMS_Trouble_Report_State__c);

                // Is the case Reopened i.e changed from Deferred, Resolved or Closed status
                if(newCase.ETMS_Trouble_Report_State__c == defaultState && newCase.ETMS_Trouble_Report_Status__c == defaultStatus
                        && oldCase.ETMS_Trouble_Report_State__c != defaultState && oldCase.ETMS_Trouble_Report_Status__c != defaultStatus
                        && etmsTroubleStateStatusMap != null && etmsTroubleStateStatusMap.containsKey('re-opened'))
                {
                    newCase.ETMS_Trouble_Report_State__c = etmsTroubleStateStatusMap.get('re-opened').Trouble_Report_State__c;
                    newCase.ETMS_Trouble_Report_Status__c = etmsTroubleStateStatusMap.get('re-opened').Trouble_Report_Status__c;
                }
            }
        }
    }

    //push incidents to partner case proxy service
    private void CallPartnerCaseProxyService(List<Case> newList, Map<Id, Case> oldMap){

        Set<Id> accountIdSet = new Set<Id>();
        List<Case> processList = new List<Case>();
        for(Case newCase : newList){

            Case oldCase = (oldMap != null) ? oldMap.get(newCase.Id) : null;
            // Not an Incident
            if(newCase.AccountId == null || newCase.RecordTypeId != incidentRecordType){
                continue;
            }
            // Is new incident
            if(oldCase == null){
                system.debug('CallPartnerCaseProxyService(): New Incident - ' + newCase.CaseNumber);
            }
            // 3rd Party vendor Ticket is null and Push To Partner is checked
            else if (newCase.Push_To_Partner__c && newCase.X3rdPartyVendorTicket__c == null) {
                system.debug('CallPartnerCaseProxyService(): Push to Partner - ' + newCase.CaseNumber);
            }
            // Case status is changed
            else if(newCase.Status != oldCase.Status && newCase.X3rdPartyVendorTicket__c != null
                    && (newCase.ETMS_Trouble_Report_State__c != oldCase.ETMS_Trouble_Report_State__c || newCase.ETMS_Trouble_Report_Status__c != oldCase.ETMS_Trouble_Report_Status__c) )
            {
                system.debug('CallPartnerCaseProxyService(): Case status changed from '
                        + oldCase.Status + ' to ' + newCase.CaseNumber);
                system.debug('CallPartnerCaseProxyService(): Trouble report status changed from  - '
                        + oldCase.ETMS_Trouble_Report_Status__c + ' to ' + newCase.ETMS_Trouble_Report_Status__c);
                system.debug('CallPartnerCaseProxyService(): Trouble report state changed from  - '
                        + oldCase.ETMS_Trouble_Report_State__c + ' to ' + newCase.ETMS_Trouble_Report_State__c);

            }
            else if(newCase.Priority != oldCase.Priority){
                system.debug('CallPartnerCaseProxyService(): Case priority changed from '
                        + oldCase.Priority + ' to ' + newCase.CaseNumber);
            }
            // Product or Service is changed to 'Toll Free'
            else if(newCase.Product_or_Service__c == PartnerCaseProxyServiceHelper.PRODUCT_TOLLFREE && newCase.Product_or_Service__c != oldCase.Product_or_Service__c)
            {
                system.debug('CallPartnerCaseProxyService(): Product or Service is changed - ' + newCase.CaseNumber);
            }
            else {
                continue;
            }

            processList.add(newCase);
            accountIdSet.add(newCase.AccountId);

        }

        if(accountIdSet.isEmpty()){
            return;
        }
        system.debug('CallPartnerCaseProxyService(): processList - ' + processList);
        Map<Id, Account> accountMap = new Map<Id, Account>([
                Select Id, Billing_Group__c from Account where Id IN :accountIdSet
        ]);
        system.debug('CallPartnerCaseProxyService(): accountMap - ' + accountMap);

        Set<Id> createIdSet = new Set<Id>();
        Set<Id> updateIdSet = new Set<Id>();

        for(Case newCase: processList){
            Account acct = accountMap.get(newCase.AccountId);
            // Is account billing group 'Verizon'
            if(acct != null && acct.Billing_Group__c == PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON){
                Case oldCase = (oldMap != null) ? oldMap.get(newCase.Id) : null;

                if(oldMap == null || (oldMap.containsKey(newCase.Id) && newCase.Push_To_Partner__c && newCase.X3rdPartyVendorTicket__c == null) ){
                    createIdSet.add(newCase.Id);
                } else if(oldMap != null && oldMap.containsKey(newCase.Id) && newCase.X3rdPartyVendorTicket__c != null
                        && (newCase.ETMS_Trouble_Report_State__c != oldCase.ETMS_Trouble_Report_State__c || newCase.ETMS_Trouble_Report_Status__c != oldCase.ETMS_Trouble_Report_Status__c
                        || newCase.Priority != oldCase.Priority))
                {
                    updateIdSet.add(newCase.Id);
                }

                // create second Verizon ETMS ticket
                if(oldMap != null && oldMap.containsKey(newCase.Id) && newCase.Product_or_Service__c == PartnerCaseProxyServiceHelper.PRODUCT_TOLLFREE
                        && oldMap.get(newCase.Id).Product_or_Service__c != PartnerCaseProxyServiceHelper.PRODUCT_TOLLFREE)
                {
                    createIdSet.add(newCase.Id);
                }

            }
        }

        system.debug('CallPartnerCaseProxyService(): createIdSet - ' + createIdSet);
        if(createIdSet.size() > 0 && !system.isFuture() && !system.isBatch()){
            CallPartnerCaseProxyServiceFuture(createIdSet);
            noOfProxyServiceCallouts++;
        }

        system.debug('CallPartnerCaseProxyService(): updateIdSet - ' + updateIdSet);
        if(updateIdSet.size() > 0 && !system.isFuture() && !system.isBatch()){
            CallUpdatePartnerCaseProxyServiceFuture(updateIdSet);
            noOfProxyServiceCallouts++;
        }


    } // end of CallPartnerCaseProxyService()

    @future(callout=true)
    private static void CallPartnerCaseProxyServiceFuture(Set<Id> caseIds){

        PartnerCaseProxyServiceHelper.PushCaseToProxyService(caseIds);

    }

    @future(callout=true)
    private static void CallUpdatePartnerCaseProxyServiceFuture(Set<Id> caseIds){

        PartnerCaseProxyServiceHelper.PushCaseStatusUpdateToProxyService(caseIds);

    }


    private void createJiraBugForKI(List<Case> newList, Map<Id, Case> oldMap){

        system.debug('createJiraBugForKI(): createJiraBug - ' + createJiraBug);
        system.debug('createJiraBugForKI(): Cases - ' + newList.size());

        if(createJiraBug == false){
            system.debug('createJiraBugForKI(): skipped @future callout');
            return;
        }

        createJiraBug = false;
        Set<Id> caseIds = new Set<Id>();
        for(Case newCase : newList){
            Case oldCase = (oldMap != null) ? oldMap.get(newCase.Id) : null;
            if(newCase.RecordTypeId == knownIssueRecordType && oldCase == null && newCase.JIRA_Key__c == JIRA_KEY_TEMP
                    || (oldCase != null && oldCase.JIRA_Key__c != newCase.JIRA_Key__c && String.isBlank(oldCase.JIRA_Key__c) && newCase.JIRA_Key__c == JIRA_KEY_TEMP))
            {
                caseIds.add(newCase.Id);
            }
        }

        system.debug('createJiraBugForKI(): caseIds - ' + caseIds);

        if(caseIds.size() > 0 && !system.isFuture() && !system.isBatch()){
            createJiraBugForKIFuture(new List<Id>(caseIds)[0]);
        }

    }

    @Future(callout=true)
    private static void createJiraBugForKIFuture(String caseId){

        String jiraKey = null;
        try{
            JiraRestWrapper wrapper = new JiraRestWrapper();
            jiraKey = wrapper.CreateJIRABug(caseId);
        }catch(Exception ex) {
            inContactBaseClass.SendErrorEmail(ex,caseId);
        }

        // clear the TEMP key in case of error
        if(String.isBlank(jiraKey)){
            Case knownIssue = new Case(
                    Id = caseId,
                    JIRA_Key__c = null
            );
            update knownIssue;
        }

    }

    private void storeQueryValues(Case newCase){

        affectedQueueIDs.add(newCase.OwnerID);
        //get all the affect User IDs
        if(newCase.Assigned_To__c != null)
            affectedUserIDs.add(newCase.Assigned_To__c);

        //get parent cases
        if(newCase.ParentId != null) parentCaseIds.add(newCase.ParentId);
    }

    private void SetAllQueues(){
        allQueues = new Map<ID,Group>([Select g.ID, g.Name, (Select UserOrGroupId From GroupMembers) from Group g Where g.ID IN : affectedQueueIDs ]);

        if(!CaseAssignmentClass.isTest)
        {
            system.debug('Allqueue*************'+allQueues);
            //create a map of affected queues with all their users
            queueUsers = CaseAssignmentClass.GetValidQueueUsers(allQueues, affectedUserIDs);
            system.debug('queueUsers*************'+queueUsers);
        }
    }

    private void setTimestamps(Case newCase, Case oldCase){
        if(oldCase.StatusDetails__c != newCase.StatusDetails__c)
        {
            newCase.StatusDetailsLastModifiedDateTime__c = system.now();
        }

        if(!oldCase.FirstResponseViolated__c && newCase.FirstResponseViolated__c)
        {
            newCase.FirstResponseViolationQueue__c = allQueues.get(oldCase.OwnerId).Name;
        }

        if(!oldCase.SLAViolated__c && newCase.SLAViolated__c)
        {
            newCase.SLAViolationQueue__c =   allQueues.get(oldCase.OwnerId).Name;
        }
    }

    private void setPriority(Case newCase){
        if(newCase.RecordTypeId == incidentRecordType || newCase.RecordTypeId == problemRecordType)
        {
            if(!eventCasePriorities.isEmpty() && eventCasePriorities.containsKey(newCase.ParentId))
            {
                // set to Event priority
                newCase.Priority = eventCasePriorities.get(newCase.ParentId);
                if(newCase.Priority != null && newCase.Priority.startsWith('P')){
                    newCase.Severity__c = newCase.Priority.replace('P','S');
                }
            }
            else
            {
                //CaseAssignmentClass.setCasePriority(cn,true);
                if(newCase.Severity__c != null && newCase.Severity__c.startsWith('S')){
                    newCase.Priority = newCase.Severity__c.replace('S','P');
                }
            }
        }
    }

    private void SetEventPriorities(){
        if(!parentCaseIds.isEmpty())
        {
            for(Case event:[SELECT Id, Priority FROM Case WHERE Id IN :parentCaseIds AND RecordTypeId = :eventRecordType])
            {
                eventCasePriorities.put(event.Id,event.Priority);
            }
        }
    }

    private void ClosedCases(Case newCase, Case oldCase){
        if(isNewlyClosed(newCase, oldCase) && Userinfo.getLastName() == '_castiron')
        {
            if(newCase.Disposition__c == null)
            {
                newCase.Disposition__c = 'Customer Closed';
            }
            if(newCase.Reason == null)
            {
                newCase.Reason = 'Customer Closed';
            }
            if(newCase.Issue_Product__c == null)
            {
                newCase.Issue_Product__c = 'Customer Closed';
            }
        }

        if(isNewlyClosed(newCase, oldCase)  && (newCase.RecordTypeId == incidentRecordType || newCase.RecordTypeId == incidentUptivityRecordType))
        {
            closedCasesForEntitlements.add(newCase.Id);
            newCase.EntitlementStatus__c = 'Closed';
        }
    }

    private void OwnerAndAssignedToChanged(Case newCase, Case oldCase){
        if(newCase.RecordTypeId != eventRecordType)
        {
            //Check if Owner has changed
            if(oldCase.OwnerId != newCase.OwnerId  && oldCase.OwnerId != UserInfo.getUserId() && newCase.IsClosed == False)
            {
                //Set Escalation based on Priority
                if(newCase.Priority == 'P1' || newCase.Priority == 'P2')
                    newCase.Escalation_Date_Time__c = System.now().addMinutes(10);
                else
                        newCase.Escalation_Date_Time__c = System.now().addMinutes(60);

                //Remove any assignment when the queue changes
                if(oldCase.Assigned_To__c == newCase.Assigned_To__c)
                {
                    newCase.Assigned_To__c = null;
                }

                //change the case status to Transferred if the owner changes.
                if(oldCase.Status == 'New')
                {
                    if(newCase.RecordTypeId != '01270000000MHOw')//Corp IT
                    {
                        if(newCase.RecordTypeId == incidentRecordType && newCase.KnownIssue__c != NULL)
                        {
                            newCase.Status = 'Assigned To Known Issue';
                            newCase.Disposition__c = 'Assigned To Known Issue';
                            attachedToKnownIssue.add(newCase.KnownIssue__c);
                        }
                        else
                        {
                            newCase.Status = 'Auto-Assigned';
                        }
                    }
                }
                else
                {
                    newCase.Acknowledge_By__c = System.now().addHours(2);
                    newCase.Transferred_By__c = UserInfo.getUserId();

                    if(newCase.RecordTypeId != '01270000000MHOw' && newCase.KnownIssue__c == NULL && newCase.Status != 'Case Rejected')//Corp IT
                    {
                        newCase.Status = 'Transferred';
                    }
                    else if(newCase.KnownIssue__c != NULL && newCase.RecordTypeId == incidentRecordType)
                    {
                        newCase.Status = 'Assigned To Known Issue';
                        newCase.Disposition__c = 'Assigned To Known Issue';
                        attachedToKnownIssue.add(newCase.KnownIssue__c);
                    }
                }

            }
            else
            {
                if(queueUsers.containsKey(newCase.OwnerID))
                {
                    if(newCase.Assigned_To__c != null && oldCase.Assigned_To__c != newCase.Assigned_To__c && newCase.IsClosed == False && newCase.Status != 'Case Rejected')
                    {
                        if(queueUsers.get(newCase.OwnerID).contains(newCase.Assigned_To__c))
                        {
                            if(newCase.RecordTypeId != '01270000000MHOw' && newCase.RecordTypeId != eventRecordType && newCase.KnownIssue__c == NULL)//Corp IT
                            {
                                //if the current user is the assigned user then acknowledged
                                if(newCase.Assigned_To__c == UserInfo.getUserId())
                                    newCase.Status = 'Acknowledged';
                                else
                                        newCase.Status = 'Assigned';
                            }

                        }
                        else
                        {
                            newCase.AddError('Assigned To user is not assigned to the case owner queue.');
                        }
                    }
                }
                else
                {
                    if(!CaseAssignmentClass.isTest)
                    {
                        newCase.AddError('Only a Queue can be the owner of a case.');
                    }
                }

                if(newCase.KnownIssue__c != NULL && newCase.RecordTypeId == incidentRecordType && newCase.Status != 'Closed')
                {
                    newCase.Status = 'Assigned To Known Issue';
                    newCase.Disposition__c = 'Assigned To Known Issue';
                    attachedToKnownIssue.add(newCase.KnownIssue__c);
                }
                else if(oldCase.KnownIssue__c != NULL && newCase.KnownIssue__c == NULL)
                {

                    newCase.Status = 'Transferred';
                }

                //Check if Priority has increased to a P1 or P2 set escalation times based on priority
                if((oldCase.Priority == 'P3' || oldCase.Priority == 'P4') && (newCase.Priority == 'P1' || newCase.Priority == 'P2'))
                    newCase.Escalation_Date_Time__c = System.now().addMinutes(10);
                else if((oldCase.Priority == 'P1' || oldCase.Priority == 'P2') && (newCase.Priority == 'P3' || newCase.Priority == 'P4'))
                    newCase.Escalation_Date_Time__c = System.now().addMinutes(60);
            }
        }
    }


    private void EventActions(Case newCase, Case oldCase){
        if(newCase.RecordTypeId == eventRecordType)
        {

            list<String> listPlatforms = new list<string>();
            if(siteConfig.AutoEventEmails__c && !newCase.IsClosed)
            {
                //RUN FOR EVENTS. Initial communication
                if((newCase.Priority == 'P1' || newCase.Priority == 'P2') && newCase.Status != 'Resolved')
                {
                    if(newCase.EventConfirmedDateTime__c != null && !newCase.EventEmailSent__c && !newCase.InternalEvent__c)
                    {
                        NotificationHelperClass.NewEventEmailAsync(newCase.Id, null);
                        newCase.EventEmailSent__c = true;
                    }
                    else if (newCase.EventEmailSent__c && newCase.PlatformsImpacted__c != oldCase.PlatformsImpacted__c && newCase.EventConfirmedDateTime__c != null && !newCase.InternalEvent__c)
                    {
                        for(string s : newCase.PlatformsImpacted__c.split(';'))
                        {
                            if(!oldCase.PlatformsImpacted__c.contains(s))
                            {
                                listPlatforms.add(s);
                            }
                        }
                        if(listPlatforms.size() > 0)
                        {
                            system.debug('test lstPlatforms CaseBeforeUpdate => ' + listPlatforms);
                            NotificationHelperClass.NewEventEmailAsync(newCase.Id, listPlatforms);
                        }
                    }
                }

            }

            Set<string> eventResolvedPriorities = new Set<string>();
            if(!string.isBlank(siteConfig.EventResolvedPriorities__c))
            {
                eventResolvedPriorities = new Set<string>(siteConfig.EventResolvedPriorities__c.split('\\;'));
            }

            if(siteConfig.EventResolvedEmails__c && newCase.Status == 'Resolved' && !newCase.EventResolvedEmailRequested__c && (eventResolvedPriorities.contains(newCase.Priority) || newCase.SendNotificationEmail__c) && !newCase.InternalEvent__c)
            {
                NotificationHelperClass.ResolvedEventEmail(newCase.Id);
                newCase.EventResolvedEmailRequested__c = true;
                newCase.SendNotificationEmail__c = false;
            }
        }
    }

    private void ResolvedCases(Case newCase, Case oldCase) {
        //set resolved date
        if((!isResolved(oldCase) && isResolved(newCase)) || (!isClosed(oldCase) && isClosed(newCase) && newCase.ResolvedDate__c == null))
        {
            newCase.ResolvedDate__c = system.now();
            newCase.ResolvedBy__c = Userinfo.getUserId();
        }

        //remove resolved date
        if((!isResolved(newCase) && !isClosed(newCase) && newCase.ResolvedDate__c != NULL))
        {
            newCase.ResolvedDate__c = NULL;
            newCase.ResolvedBy__c = NULL;
            newCase.EntitlementStatus__c = 'Reopened';
        }
    }


    private void GetSurveyCases(Case newCase, Case oldCase) {
        if(!System.isFuture() && newCase.SystemClosed__c != true && !system.isBatch())//batch soql does not accept @future callouts
        {
            if (isNewlyClosed(newCase, oldCase) && newCase.RecordTypeId == helpDeskRCTypeId) { // Get Closed cases for HelpDesk - Arnab (The man)
                closedHelpdeskCaseIds.add(newCase.Id);
            }
        }
    }

    private void SendSurveys(){
        if(!System.isFuture() && !system.isBatch())
        {
            System.debug('closedHelpdeskCaseIds ==>' + closedHelpdeskCaseIds);

            //if there are closed tech support cases send survey
            if(!closedHelpdeskCaseIds.isEmpty())
            {
                CaseSendSurvey.TechSupportSurveyMain(closedHelpdeskCaseIds);
            }
        }
    }

    private void KnownIssueCheck(){
        if(!System.isFuture() && !attachedToKnownIssue.isEmpty() && !system.isBatch()){
            CaseAssignmentClass.KnownIssueClusterCheck(attachedToKnownIssue);
        }
    }

    private void CloseEntitlements() {
        if (!closedCasesForEntitlements.isEmpty()) {
            //close out any remaining first response milestones first.
            List<String> entitlementsToClose = new List<String>{
                    'First Response', 'Status Update', 'SLA'
            };
            CaseAssignmentClass.CompleteMilestone(closedCasesForEntitlements, entitlementsToClose, system.now());
        }
    }

    private boolean isNewlyClosed(Case newCase, Case oldCase){
        if(!isClosed(oldCase) && isClosed(newCase)){
            return true;
        }

        return false;
    }

    private boolean isClosed(Case caseToCheck){
        if(closedStatuses.contains(caseToCheck.Status)){
            return true;
        }

        return false;
    }

    private boolean isResolved(Case caseToCheck){
        if(caseToCheck.Status == 'Resolved'){
            return true;
        }

        return false;
    }




}