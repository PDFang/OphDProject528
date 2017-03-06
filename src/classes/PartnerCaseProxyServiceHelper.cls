/**
 * Created by mohandaas.rangaswamy on 3/3/2017.
 */

public with sharing class PartnerCaseProxyServiceHelper {

    public static final String BILLING_GROUP_VERIZON = 'Verizon';
    public static final String DEFAULT_ETMS_TROUBLE_TYPE = 'Other';
    public static final String DEFAULT_ETMS_TROUBLE_Description = 'Other';

    public static void PushCaseToProxyService(Set<Id> caseIds){

        List<Case> updateList = new List<Case>();
        try {
            // mapping
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
            PartnerCaseProxyService.SalesforceCase[] caseArray = new PartnerCaseProxyService.SalesforceCase[]{};
            for (Case newCase : [
                    Select Id, CaseNumber, Priority, Description, CreatedDate, X3rdPartyVendorTicket__c,
                            Product_or_Service__c, Request_Type__c, Database__c, Releases__c,
                            Account.Name, Account.Billing_Group__c, Account.CadebillAccountNo__c,
                            Contact.Name, Contact.Phone, OwnerId, Owner.Name, Owner.Phone, Push_To_Partner__c
                    from Case
                    where Id IN :caseIds and Account.Billing_Group__c = :BILLING_GROUP_VERIZON
            ]) {
                PartnerCaseProxyService.SalesforceCase partnerCase = createPartnerCase(newCase, requestTypeMap);
                caseArray.add(partnerCase);
                // uncheck the field
                if(newCase.Push_To_Partner__c){
                    newCase.Push_To_Partner__c = false;
                    updateList.add(newCase);
                }
            }

            PartnerCaseProxyService.PartnerCaseProxySoap proxy = new PartnerCaseProxyService.PartnerCaseProxySoap();
            proxy.endpoint_x = 'callout:PartnerCaseProxyService';
            // callout
            PartnerCaseProxyService.ArrayOfSalesforceCase caseRequest = new PartnerCaseProxyService.ArrayOfSalesforceCase();
            caseRequest.SalesforceCase = caseArray;
            proxy.CreatePartnerCase(caseRequest, BILLING_GROUP_VERIZON);
        }catch (system.CalloutException ex) {
            system.debug('PartnerCaseProxyServiceHelper(): CalloutException - ' + ex);
            String subject = String.join(new List<Id>(caseIds), ',');
            subject = subject + ' - PartnerCaseProxyService callout failed.';
            SendErrorEmail( ex, subject);
        }catch(system.Exception ex){
            system.debug('PartnerCaseProxyServiceHelper(): Exception - ' + ex);
            String subject = String.join(new List<Id>(caseIds), ',');
            subject = subject + ' - Failed to callout PartnerCaseProxyService.';
            SendErrorEmail( ex, subject);
        }finally{
            if(updateList.size() > 0){
                update updateList;
            }
        }
        
    } // end of PushCaseToProxyService

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
        // find mapped ETMS Trouble Type and Description, if there is one
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


    private static void sendErrorEmail(Exception ex, String subject){
        try{
            inContactBaseClass.SendErrorEmail( ex, subject);
        }catch(system.EmailException emailEx){
            system.debug('sendErrorEmail(): subject - ' + subject);
            system.debug('sendErrorEmail(): Email Exception - ' + emailEx);
        }
    }


}