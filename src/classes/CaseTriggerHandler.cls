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

    public static void CallPartnerCaseProxyService(List<Case> newList, Map<Id, Case> oldMap){

        Set<Id> caseIdSet = new Set<Id>();
        for(Case newCase : newList){
            Case oldCase = (oldMap != null) ? oldMap.get(newCase.Id) : null;
            if(oldCase == null || (newCase.Push_To_Partner__c && newCase.X3rdPartyVendorTicket__c == null) ){
                caseIdSet.add(newCase.Id);
            }
        }

        if(caseIdSet.size() > 0){
            CallPartnerCaseProxyServiceFuture(caseIdSet);
        }

    }

    @future(callout=true)
    private static void CallPartnerCaseProxyServiceFuture(Set<Id> caseIds){

        try{
            PartnerCaseProxyService.SalesforceCase[] caseArray = new PartnerCaseProxyService.SalesforceCase[]{};
            for(Case newCase : [
                    Select Id, CaseNumber, Priority, Description, CreatedDate,
                            Product_or_Service__c, Request_Type__c, Database__c, Releases__c,
                            Account.Name, Account.Billing_Group__c, Account.CadebillAccountNo__c,
                            Contact.Name, Contact.Phone, Owner.Name, Owner.Phone
                    from Case
                    where Id IN :caseIds and Account.Billing_Group__c = :BILLING_GROUP_VERIZON
            ]){
                PartnerCaseProxyService.SalesforceCase partnerCase = createPartnerCase(newCase);
                caseArray.add(partnerCase);
            }

            PartnerCaseProxyService.PartnerCaseProxySoap proxy = new PartnerCaseProxyService.PartnerCaseProxySoap();
            proxy.endpoint_x = 'https://labproxy.ucn.net/PartnerProxyService/PartnerCaseProxy.asmx';
            PartnerCaseProxyService.ArrayOfSalesforceCase caseRequest = new PartnerCaseProxyService.ArrayOfSalesforceCase();
            caseRequest.SalesforceCase = caseArray;
            proxy.CreatePartnerCase(caseRequest, BILLING_GROUP_VERIZON);
        } catch(system.CalloutException ex){
            throw ex;
        } catch(system.Exception ex){
            throw ex;
        }

    }
    
    private static PartnerCaseProxyService.SalesforceCase createPartnerCase(Case sfCase){
        PartnerCaseProxyService.SalesforceCase partnerCase = new PartnerCaseProxyService.SalesforceCase();
        partnerCase.SalesforceId = sfCase.Id;
        partnerCase.Number_x = sfCase.CaseNumber;
        //partnerCase.Comment = '';
        partnerCase.Description = sfCase.Description;
        partnerCase.ContactName = sfCase.Contact.Name;
        partnerCase.ContactPhone = sfCase.Contact.Phone;
        partnerCase.OwnerName = sfCase.Description;
        partnerCase.OwnerPhone = sfCase.Description;
        partnerCase.CadebillAccountNumber = Integer.valueOf(sfCase.Account.CadebillAccountNo__c);
        partnerCase.EventTime = sfCase.CreatedDate;
        //partnerCase.Country = '';
        partnerCase.AccountName = sfCase.Account.Name;
        partnerCase.Priority = sfCase.Priority;
        partnerCase.Product = sfCase.Product_or_Service__c;
        partnerCase.RequestType = sfCase.Request_Type__c;
        partnerCase.Reason = sfCase.Database__c;
        partnerCase.ReasonDetails = sfCase.Releases__c;
        partnerCase.EtmsTroubleType = '';
        partnerCase.TroubleTypeDescription = '';

		return partnerCase;
    }
}