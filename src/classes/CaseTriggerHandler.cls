public class CaseTriggerHandler extends TriggerHandler 
{
    private static boolean staticValuesSet = false;
    private static boolean isProxyServiceTurnedOff = false;
    private static boolean isxMattersNotificationsTurnedOff = false;
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
                isxMattersNotificationsTurnedOff = config.Turn_Off_xMatters_Notifications__c;
            }
        }
    }

    protected override void beforeInsert(){
        CalculateIncidentNetScore((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
    }

    protected override void beforeUpdate(){
        CalculateIncidentNetScore((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
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

    // Create an xmNotification record when an event is confirmed
    private void createXmNotification(List<Case> newList, Map<Id, Case> oldMap){

        List<Case> processList = new List<Case>();
        for(Case newCase : newList){
            Case oldCase = (oldMap != null) ? oldMap.get(newCase.Id) : null;
            // Is Event confirmed
            if(newCase.RecordTypeId == eventRecordType && oldCase != null
                    && ( (newCase.EventConfirmedDateTime__c != null && oldCase.EventConfirmedDateTime__c == null)
                    || (newCase.Status == 'Resolved' && oldCase.Status != 'Resolved') ) )
            {
                processList.add(newCase);
            }
        }

        system.debug('createXmNotification(): processList - ' + processList);
        if(processList.isEmpty()){
            return;
        }

        List<xmNotification__c> notificationList = new List<xmNotification__c>();

        for(Case newCase :processList){
            xmNotification__c xmNotification = new xmNotification__c(
                    Case__c = newCase.Id,
                    Request_Date__c = system.now(),
                    Request_Type__c = getXmNotificationRequestType(newCase)
            );
            notificationList.add(xmNotification);
        }
        system.debug('createXmNotification(): notificationList - ' + notificationList);

        insert notificationList;

    }

    private string getXmNotificationRequestType(Case newCase){

        String requestType = null;

        if(newCase.RecordTypeId == eventRecordType && newCase.Status == 'Resolved'){
            requestType = 'Event Resolved';
        } else if(newCase.RecordTypeId == eventRecordType && newCase.EventConfirmedDateTime__c != null){
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