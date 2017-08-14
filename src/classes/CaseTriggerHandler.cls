public class CaseTriggerHandler extends TriggerHandler 
{
    private static boolean staticValuesSet = false;
    private static boolean isProxyServiceTurnedOff = false;
    private static boolean isxMattersNotificationsTurnedOff = false;
    private static String xmEventNotificationPriorities = 'P1;P2;';
    private static Id eventRecordType;
    private static Id maintenanceRecordType;   
    private static Id knownIssueRecordType;
    private static Id incidentRecordType;
    private static Id problemRecordType;
    private static Id incidentUptivityRecordType;
    private static Id serviceRequestRecordType;
    private static Id workOrderRecordType;
    private static Id workOrderUptivityRecordType;
    private static Id helpDeskRCTypeId;
    private static Set<String> closedStatuses;
    private static SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(inContactBaseClass.OrgId15Digit);
    public static boolean callActionHub = true;


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
                xmEventNotificationPriorities = config.XM_Event_Notification_Priorities__c;
            }
        }
    }

    protected override void beforeInsert(){
        CalculateIncidentNetScore((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
    }

    protected override void beforeUpdate(){
        CalculateIncidentNetScore((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
        setCaseStatusFlags((List<Case>) trigger.new, (Map<Id, Case>)trigger.oldMap);
    }

    protected override void afterInsert(){
        if(!isProxyServiceTurnedOff)
            CallPartnerCaseProxyService((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
    }

    protected override void afterUpdate(){
        if(!isxMattersNotificationsTurnedOff)
            createXmNotification((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
        if(!isProxyServiceTurnedOff)
            CallPartnerCaseProxyService((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
    }

    private void setCaseStatusFlags(List<Case> updateList, Map<Id, Case> oldMap) {
        for(Case updatedCase : updateList) {
            Case oldCase = (oldMap != null) ? oldMap.get(updatedCase.Id) : null;
            if(updatedCase.RecordTypeId == eventRecordType && !updatedCase.EventHasBeenResolvedOrClosed__c
                    &&((updatedCase.Status == 'Resolved' && oldCase.Status != 'Resolved')
                    || (updatedCase.Status == 'Confirmed' && oldCase.Status != 'Confirmed'))) {
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
            if(newCase.RecordTypeId == incidentRecordType && (oldCase == null || recalculateScore(newCase, oldCase)) ){
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
                || newRecord.Business_Impacted__c != oldRecord.Business_Impacted__c
                || newRecord.Quality_of_Workaround__c != oldRecord.Quality_of_Workaround__c
                || newRecord.Related_to_Previous_Known_Issue__c != oldRecord.Related_to_Previous_Known_Issue__c
                || newRecord.Security_Issue__c != oldRecord.Security_Issue__c
                || newRecord.Workaround_Available__c != oldRecord.Workaround_Available__c;
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

        //retrieve the newest resolved notification, if there is one, for the cases in the set
        List<AggregateResult> resolvedNotifications = [Select Case__c
                                                         from xmNotification__c
                                                         where Status__c = 'Completed' and Request_Type__c = 'Event Resolved'
                                                            and Case__c in :caseIds
                                                         group by Request_Type__c, Case__c];
        caseIds.clear();
        for(AggregateResult notification : resolvedNotifications) {
            caseIds.add((Id)notification.get('Case__c'));
        }

        for(Case newCase : newList){
            Case oldCase = (oldMap != null) ? oldMap.get(newCase.Id) : null;
            // Is Event confirmed
            system.debug('createXmNotification(): new status - ' + newCase.Status);
            system.debug('createXmNotification(): old status - ' + oldCase.Status);

            //ensure the case is an Event, and it was not just created (oldCase is not null), and
            //that it was not internal
            //and that the non event checkbox is unchecked
            if(newCase.RecordTypeId == eventRecordType && oldCase != null && !newCase.InternalEvent__c && !newCase.NonEvent__c)
            {
                //the Priority of the case must be in the list of xmEventNotificationPriorities or don't send
                if(String.isNotBlank(xmEventNotificationPriorities) && !xmEventNotificationPriorities.containsIgnoreCase(newCase.Priority)){
                    continue;
                }

                //status is equal to Confirmed or Being Worked and no Event Confirmation notification has been sent
                if (((newCase.Status == 'Confirmed' && oldCase.Status != 'Confirmed')
                        || (newCase.Status == 'Being Worked' && oldCase.Status != 'Being Worked'))
                        && !newCase.EventEmailSent__c) {
                    System.debug('Initial event');
                    processList.add(newCase);
                }
                else if (((newCase.Status == 'Resolved' && oldCase.Status != 'Resolved')
                        || (newCase.Status == 'Closed' && oldCase.Status != 'Closed'))
                        && newCase.EventEmailSent__c
                        && !newCase.EventHasBeenResolvedOrClosed__c) {
                    //track that this case has been

                    //if a resolved notification has not been sent, then send it
                    if(!caseIds.contains(newCase.Id)) {
                        System.debug('Resolved event');
                        processList.add(newCase);
                    }
                }
                else if(newCase.Status == 'Confirmed' &&
                        newCase.PlatformsImpacted__c != oldCase.PlatformsImpacted__c){
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

        List<xmNotification__c> notificationList = new List<xmNotification__c>();

        for(Case newCase :processList){
            xmNotification__c xmNotification = new xmNotification__c(
                    Case__c = newCase.Id,
                    Request_Date__c = system.now(),
                    Request_Type__c = requestType == '' ? getXmNotificationRequestType(newCase) : requestType,
                    AddedPlatforms__c = platformsAdded
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

    @TestVisible
    private string getXmNotificationRequestType(Case newCase){

        String requestType = null;

        if(newCase.RecordTypeId == eventRecordType && newCase.Status == 'Resolved'){
            requestType = 'Event Resolved';
        } else if(newCase.RecordTypeId == eventRecordType && newCase.Status == 'Confirmed'){
            requestType = 'Event Initial Confirmation';
        }

        return requestType;

    }

    //push incidents to partner case proxy service
    private void CallPartnerCaseProxyService(List<Case> newList, Map<Id, Case> oldMap){

        Set<Id> accountIdSet = new Set<Id>();
        List<Case> processList = new List<Case>();
        for(Case newCase : newList){
            Case oldCase = (oldMap != null) ? oldMap.get(newCase.Id) : null;
            // Is new incident (or) 3rd Party vendor Ticket is null and Push To Partner is checked
            if(newCase.AccountId != null && newCase.RecordTypeId == incidentRecordType
                    && (oldCase == null || (newCase.Push_To_Partner__c && newCase.X3rdPartyVendorTicket__c == null)) ){
                processList.add(newCase);
                accountIdSet.add(newCase.AccountId);
            }
        }
        if(accountIdSet.isEmpty()){
            return;
        }
        system.debug('CallPartnerCaseProxyService(): processList - ' + processList);
        Map<Id, Account> accountMap = new Map<Id, Account>([
                Select Id, Billing_Group__c from Account where Id IN :accountIdSet
        ]);
        system.debug('CallPartnerCaseProxyService(): accountMap - ' + accountMap);

        Set<Id> createdIdSet = new Set<Id>();
        for(Case newCase: processList){
            Account acct = accountMap.get(newCase.AccountId);
            // Is account billing group 'Verizon'
            if(acct != null && acct.Billing_Group__c == PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON){
                createdIdSet.add(newCase.Id);
            }
        }
        system.debug('CallPartnerCaseProxyService(): createdIdSet - ' + createdIdSet);
        if(createdIdSet.size() > 0 && !system.isFuture() && !system.isBatch()){
            CallPartnerCaseProxyServiceFuture(createdIdSet);
        }

    } // end of CallPartnerCaseProxyService()

    @future(callout=true)
    private static void CallPartnerCaseProxyServiceFuture(Set<Id> caseIds){

        PartnerCaseProxyServiceHelper.PushCaseToProxyService(caseIds);

    }
    

}