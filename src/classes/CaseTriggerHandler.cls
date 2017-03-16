public class CaseTriggerHandler extends TriggerHandler 
{
    private static boolean staticValuesSet = false;
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


    public CaseTriggerHandler()
    {
        if(!staticValuesSet)
        {
            SetRecordTypeIds();
            GetClosedCaseStatuses();
        	staticValuesSet = true;
        }
    }

    protected override void beforeInsert(){
        CalculateIncidentNetScore((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
    }

    protected override void afterInsert(){
        CallPartnerCaseProxyService((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
    }

    protected override void afterUpdate(){
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
            if(newCase.RecordTypeId == incidentRecordType && oldCase == null){
                processList.add(newCase);
            }
        }
        system.debug('CalculateIncidentNetScore(): processList - ' + processList);

        if(processList.size() > 0){
            ImpactCalculationService calculationService = new ImpactCalculationService(new IncidentImpactCalculationImplementation());
            calculationService.CalculateIncidentNetScore(processList);
        }

    } // end of calculateIncidentNetScore()

    // push incidents to partner case proxy service
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
        if(createdIdSet.size() > 0){
            CallPartnerCaseProxyServiceFuture(createdIdSet);
        }

    } // end of CallPartnerCaseProxyService()

    @future(callout=true)
    private static void CallPartnerCaseProxyServiceFuture(Set<Id> caseIds){

        PartnerCaseProxyServiceHelper.PushCaseToProxyService(caseIds);

    }
    



}