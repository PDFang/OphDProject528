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
    
    @future(callout=true)
    public static void CallPartnerCaseProxyService(Set<Id> caseIds){
        
        List<Case> caseList = [Select Id, CaseNumber, Priority, Description, Account.Partner_Agent_ID__c from Case where Id IN :caseIds];
        
        PartnerCaseProxyService.SalesforceCase[] caseArray = new PartnerCaseProxyService.SalesforceCase[]{};		
		for(Case newCase: caseList){
			PartnerCaseProxyService.SalesforceCase partnerCase = createPartnerCase(newCase);
            caseArray.add(partnerCase);
		}
        
        PartnerCaseProxyService.PartnerCaseProxySoap proxy = new PartnerCaseProxyService.PartnerCaseProxySoap();
        
        PartnerCaseProxyService.ArrayOfSalesforceCase caseParam = new PartnerCaseProxyService.ArrayOfSalesforceCase();
        caseParam.SalesforceCase = caseArray;
        
        proxy.CreatePartnerCase(caseParam, '');
        
    }
    
    private static PartnerCaseProxyService.SalesforceCase createPartnerCase(Case sfCase){
        PartnerCaseProxyService.SalesforceCase partnerCase = new PartnerCaseProxyService.SalesforceCase();
        partnerCase.SalesforceId = sfCase.Id;
        partnerCase.Priority = sfCase.Priority;
        partnerCase.Number_x = sfCase.CaseNumber;
        partnerCase.Description = sfCase.Description;
		return partnerCase;
    }
}