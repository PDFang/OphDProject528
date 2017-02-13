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

    public static final String BILLING_GROUP_VERIZON = 'Verizon';
    public static final String DEFAULT_ETMS_TROUBLE_TYPE = 'Other';
    public static final String DEFAULT_ETMS_TROUBLE_Description = 'Other';

    public CaseTriggerHandler()
    {
        if(!staticValuesSet)
        {
            SetRecordTypeIds();
            GetClosedCaseStatuses();
        	staticValuesSet = true;
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

    // push incidents to partner case proxy service
    public static void CallPartnerCaseProxyService(List<Case> newList, Map<Id, Case> oldMap){

        Set<Id> accountIdSet = new Set<Id>();
        List<Case> processList = new List<Case>();
        for(Case newCase : newList){
            Case oldCase = (oldMap != null) ? oldMap.get(newCase.Id) : null;
            if(newCase.RecordTypeId == incidentRecordType && (oldCase == null || (newCase.Push_To_Partner__c && newCase.X3rdPartyVendorTicket__c == null)) ){
                processList.add(newCase);
                accountIdSet.add(newCase.AccountId);
            }
        }

        if(accountIdSet.isEmpty()){
            return;
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([
                Select Id, Billing_Group__c from Account where Id IN :accountIdSet
        ]);
        Set<Id> createdIdSet = new Set<Id>();
        for(Case newCase: processList){
            Account acct = accountMap.get(newCase.AccountId);
            if(acct.Billing_Group__c == BILLING_GROUP_VERIZON){
                createdIdSet.add(newCase.Id);
            }
        }

        if(createdIdSet.size() > 0){
            CallPartnerCaseProxyServiceFuture(createdIdSet);
        }

    } // end of CallPartnerCaseProxyService()

    @future(callout=true)
    private static void CallPartnerCaseProxyServiceFuture(Set<Id> caseIds){

        try {
            List<ETMS_Codes__c> allEtmsCodes = ETMS_Codes__c.getAll().values();
            Map<String, List<ETMS_Codes__c>> requestTypeMap = new Map<String, List<ETMS_Codes__c>>();
            for (ETMS_Codes__c entry: allEtmsCodes) {
                List<ETMS_Codes__c> etmsCodes = requestTypeMap.get(entry.Request_Type__c);
                if (etmsCodes == null) {
                    etmsCodes = new List<ETMS_Codes__c>();
                    requestTypeMap.put(entry.Request_Type__c, etmsCodes);
                }
                etmsCodes.add(entry);
            }
            PartnerCaseProxyService.SalesforceCase[] caseArray = new PartnerCaseProxyService.SalesforceCase[]{
            };
            for (Case newCase : [
                    Select Id, CaseNumber, Priority, Description, CreatedDate, X3rdPartyVendorTicket__c,
                            Product_or_Service__c, Request_Type__c, Database__c, Releases__c,
                            Account.Name, Account.Billing_Group__c, Account.CadebillAccountNo__c,
                            Contact.Name, Contact.Phone, OwnerId, Owner.Name, Owner.Phone
                    from Case
                    where Id IN :caseIds and Account.Billing_Group__c = :BILLING_GROUP_VERIZON
            ]) {
                PartnerCaseProxyService.SalesforceCase partnerCase = createPartnerCase(newCase, requestTypeMap);
                caseArray.add(partnerCase);
            }

            PartnerCaseProxyService.PartnerCaseProxySoap proxy = new PartnerCaseProxyService.PartnerCaseProxySoap();
            // TBD: add Named credentials
            proxy.endpoint_x = 'https://labproxy.ucn.net/PartnerProxyService/PartnerCaseProxy.asmx';
            PartnerCaseProxyService.ArrayOfSalesforceCase caseRequest = new PartnerCaseProxyService.ArrayOfSalesforceCase();
            caseRequest.SalesforceCase = caseArray;
            try {
                proxy.CreatePartnerCase(caseRequest, BILLING_GROUP_VERIZON);
            } catch (system.CalloutException ex) {
                system.debug('CallPartnerCaseProxyServiceFuture(): CalloutException - ' + ex);
                // send error email
                throw ex;
            }
        }catch(system.Exception ex){
            system.debug('CallPartnerCaseProxyServiceFuture(): Exception - ' + ex);
            // send error email
            throw ex;
        }

    } // end of CallPartnerCaseProxyServiceFuture()
    
    private static PartnerCaseProxyService.SalesforceCase createPartnerCase(Case sfCase, Map<String, List<ETMS_Codes__c>> requestTypeMap){
        PartnerCaseProxyService.SalesforceCase partnerCase = new PartnerCaseProxyService.SalesforceCase();
        partnerCase.SalesforceId = sfCase.Id;
        partnerCase.Number_x = sfCase.CaseNumber;
        partnerCase.Description = sfCase.Description;
        partnerCase.ContactName = sfCase.Contact.Name;
        partnerCase.ContactPhone = sfCase.Contact.Phone;
        partnerCase.OwnerName = sfCase.Owner.Name;
        if(((String)sfCase.OwnerId).startsWith('005')){
            partnerCase.OwnerPhone = sfCase.Owner.Phone;
        }
        partnerCase.CadebillAccountNumber = Integer.valueOf(sfCase.Account.CadebillAccountNo__c);
        partnerCase.EventTime = sfCase.CreatedDate;
        partnerCase.AccountName = sfCase.Account.Name;
        partnerCase.Priority = sfCase.Priority;
        partnerCase.Product = sfCase.Product_or_Service__c;
        partnerCase.RequestType = sfCase.Request_Type__c;
        partnerCase.Reason = sfCase.Database__c;
        partnerCase.ReasonDetails = sfCase.Releases__c;
        partnerCase.EtmsTroubleType = DEFAULT_ETMS_TROUBLE_TYPE;
        partnerCase.TroubleTypeDescription = DEFAULT_ETMS_TROUBLE_Description;
        // find out mapping ETMS Trouble Type and Description, if there is one
        List<ETMS_Codes__c> etmsCodes = requestTypeMap.get(sfCase.Request_Type__c);
        if(etmsCodes != null && String.isNotBlank(sfCase.Database__c) && String.isNotBlank(sfCase.Releases__c)){
            for(ETMS_Codes__c entry : etmsCodes){
                if(sfCase.Database__c == entry.Reason__c && sfCase.Releases__c == entry.Reason_Detail__c){
                    partnerCase.EtmsTroubleType = entry.ETMS_Trouble_Type__c;
                    partnerCase.TroubleTypeDescription = entry.ETMS_Trouble_Type_Description__c;
                }
            }
        }
		return partnerCase;

    } // end of createPartnerCase()
}