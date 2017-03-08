/**
 * Created by mohandaas.rangaswamy on 3/3/2017.
 */

public with sharing class PartnerCaseProxyServiceHelper {

    public static final String BILLING_GROUP_VERIZON = 'Verizon';
    public static final String DEFAULT_ETMS_TROUBLE_TYPE = 'Other';
    public static final String DEFAULT_ETMS_TROUBLE_Description = 'Other';

    private static Map<String, List<ETMS_Codes__c>> requestTypeEtmsMap = null;
    @TestVisible
    private static boolean isCasePushed = false;
    @TestVisible
    private static boolean isCaseCommentPushed = false;


    public static void PushCaseToProxyService(Set<Id> caseIds){

        system.debug('PushCaseToProxyService(): caseIds - ' + caseIds);
        List<Case> updateList = new List<Case>();
        try {

            PartnerCaseProxyService.SalesforceCase[] caseArray = new PartnerCaseProxyService.SalesforceCase[]{};
            for (Case newCase : [
                    Select Id, CaseNumber, Priority, Description, CreatedDate, X3rdPartyVendorTicket__c,
                            status, Product_or_Service__c, Request_Type__c, Database__c, Releases__c,
                            Account.Name, Account.Billing_Group__c, Account.CadebillAccountNo__c,
                            Contact.Name, Contact.Phone, OwnerId, Owner.Name, Owner.Phone, Push_To_Partner__c
                    from Case
                    where Id IN :caseIds
                    and Account.Billing_Group__c = :BILLING_GROUP_VERIZON
            ]) {
                // uncheck the field
                if(newCase.Push_To_Partner__c){
                    newCase.Push_To_Partner__c = false;
                    updateList.add(newCase);
                }
                PartnerCaseProxyService.SalesforceCase partnerCase = createPartnerCase(newCase);
                caseArray.add(partnerCase);
            }

            PartnerCaseProxyService.PartnerCaseProxySoap proxy = new PartnerCaseProxyService.PartnerCaseProxySoap();
            proxy.endpoint_x = 'callout:PartnerCaseProxyService';
            system.debug('PushCaseToProxyService():  proxy.endpoint_x - ' +  proxy.endpoint_x);
            // callout
            PartnerCaseProxyService.ArrayOfSalesforceCase caseRequest = new PartnerCaseProxyService.ArrayOfSalesforceCase();
            caseRequest.SalesforceCase = caseArray;
            system.debug('PushCaseToProxyService(): caseRequest - ' + caseRequest);
            proxy.CreatePartnerCase(caseRequest, BILLING_GROUP_VERIZON);
            if(test.isRunningTest()) isCasePushed = true;
        }catch (system.CalloutException ex) {
            system.debug('PushCaseToProxyService(): CalloutException - ' + ex);
            String subject = String.join(new List<Id>(caseIds), ',');
            subject = subject + ' - PartnerCaseProxyService callout failed.';
            SendErrorEmail( ex, subject);
        }catch(system.Exception ex){
            system.debug('PushCaseToProxyService(): Exception - ' + ex);
            String subject = String.join(new List<Id>(caseIds), ',');
            subject = subject + ' - Failed to callout PartnerCaseProxyService.';
            SendErrorEmail( ex, subject);
        }finally{
            if(updateList.size() > 0){
                update updateList;
            }
        }
        
    } // end of PushCaseToProxyService

    public static void PushCaseCommentToProxyService(Set<Id> commentIds){

        system.debug('PushCaseCommentToProxyService(): commentIds - ' + commentIds);
        try {
            PartnerCaseProxyService.PartnerCaseCommentUpdate[] caseCommentArray = new PartnerCaseProxyService.PartnerCaseCommentUpdate[]{};
            for (CaseComment newComment : [
                    Select Id, CommentBody, IsPublished, CreatedDate, CreatorName,
                            Parent.CaseNumber, Parent.Status, Parent.X3rdPartyVendorTicket__c,
                            Parent.Account.Name, Parent.Account.Billing_Group__c, Parent.Account.CadebillAccountNo__c
                    from CaseComment
                    where Id IN :commentIds
                    and Parent.Account.Billing_Group__c = :BILLING_GROUP_VERIZON
            ]) {
                PartnerCaseProxyService.PartnerCaseCommentUpdate partnerComment = createPartnerCaseComment(newComment);
                caseCommentArray.add(partnerComment);
            }

            PartnerCaseProxyService.PartnerCaseProxySoap proxy = new PartnerCaseProxyService.PartnerCaseProxySoap();
            proxy.endpoint_x = 'callout:PartnerCaseProxyService';
            // callout
            PartnerCaseProxyService.ArrayOfPartnerCaseCommentUpdate caseCommentRequest = new PartnerCaseProxyService.ArrayOfPartnerCaseCommentUpdate();
            caseCommentRequest.PartnerCaseCommentUpdate = caseCommentArray;
            proxy.UpdatePartnerCase(caseCommentRequest, BILLING_GROUP_VERIZON);
            if(test.isRunningTest()) isCaseCommentPushed = true;
        }catch (system.CalloutException ex) {
            system.debug('PushCaseCommentToProxyService(): CalloutException - ' + ex);
            String subject = String.join(new List<Id>(commentIds), ',');
            subject = subject + ' - PartnerCaseProxyService callout failed.';
            SendErrorEmail( ex, subject);
        }catch(system.Exception ex){
            system.debug('PushCaseCommentToProxyService(): Exception - ' + ex);
            String subject = String.join(new List<Id>(commentIds), ',');
            subject = subject + ' - Failed to callout PartnerCaseProxyService.';
            SendErrorEmail( ex, subject);
        }

    } // end of PushCaseCommentToProxyService

    private static PartnerCaseProxyService.SalesforceCase createPartnerCase(Case sfCase){

        system.debug('createPartnerCase(): sfCase - ' + sfCase);
        // cache mapping data
        if(requestTypeEtmsMap == null) {
            requestTypeEtmsMap = new Map<String, List<ETMS_Codes__c>>();
            // mapping
            List<ETMS_Codes__c> allEtmsCodes = ETMS_Codes__c.getAll().values();
            for (ETMS_Codes__c entry: allEtmsCodes) {
                List<ETMS_Codes__c> etmsCodes = requestTypeEtmsMap.get(entry.Request_Type__c);
                if (etmsCodes == null) {
                    etmsCodes = new List<ETMS_Codes__c>();
                    requestTypeEtmsMap.put(entry.Request_Type__c, etmsCodes);
                }
                etmsCodes.add(entry);
            }
        }

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
        List<ETMS_Codes__c> etmsCodes = requestTypeEtmsMap.get(sfCase.Request_Type__c);
        if(etmsCodes != null && String.isNotBlank(sfCase.Database__c) && String.isNotBlank(sfCase.Releases__c)){
            for(ETMS_Codes__c entry : etmsCodes){
                if(sfCase.Database__c == entry.Reason__c && sfCase.Releases__c == entry.Reason_Detail__c){
                    partnerCase.EtmsTroubleType = entry.ETMS_Trouble_Type__c;
                    partnerCase.TroubleTypeDescription = entry.ETMS_Trouble_Type_Description__c;
                }
            }
        }
        system.debug('createPartnerCase(): partnerCase - ' + partnerCase);
        return partnerCase;

    } // end of createPartnerCase()

    private static PartnerCaseProxyService.PartnerCaseCommentUpdate createPartnerCaseComment(CaseComment sfCaseComment){

        system.debug('createPartnerCaseComment(): sfCaseComment - ' + sfCaseComment);
        PartnerCaseProxyService.PartnerCaseCommentUpdate partnerComment = new PartnerCaseProxyService.PartnerCaseCommentUpdate();
        partnerComment.AccountName = sfCaseComment.Parent.Account.Name;
        partnerComment.Comment = sfCaseComment.CommentBody;
        partnerComment.UpdateDateTime = sfCaseComment.CreatedDate;
        partnerComment.VendorTicketNumber = sfCaseComment.Parent.X3rdPartyVendorTicket__c;
        system.debug('createPartnerCaseComment(): partnerComment - ' + partnerComment);
        return partnerComment;

    }

    private static void sendErrorEmail(Exception ex, String subject){
        try{
            inContactBaseClass.SendErrorEmail( ex, subject);
        }catch(system.EmailException emailEx){
            system.debug('sendErrorEmail(): subject - ' + subject);
            system.debug('sendErrorEmail(): Email Exception - ' + emailEx);
        }
    }


}