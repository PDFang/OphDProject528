/**
 * Created by mohandaas.rangaswamy on 3/3/2017.
 */

public class PartnerCaseProxyServiceHelper {

    public static final String BILLING_GROUP_VERIZON = 'Verizon';
    public static final String DEFAULT_ETMS_TROUBLE_TYPE = 'Other';
    public static final String DEFAULT_ETMS_TROUBLE_Description = 'Other';
    public static final String PRODUCT_TOLLFREE = 'Toll Free';
    public static final String PRODUCT_DIALTF = 'DIALTF';
    public static final String PRODUCT_HOSTING = 'HOSTING';
    public static final String PRODUCT_GENERAL = 'GENERAL';

    private static Integer noOfRetries = 2;
    @TestVisible
    private static final String DEFAULT_COUNTRY_USA = 'USA';
    @TestVisible
    private static final String PARTNER_CUSTOMER_ID_PREFIX = 'IC-';

    private static Map<String, List<ETMS_Codes__c>> requestTypeEtmsMap = null;
    private static Map<String, ETMS_Incident_Location_To_Country__mdt> locationCountryMap = null;

    @TestVisible
    private static boolean isCasePushed = false;
    @TestVisible
    private static boolean isCaseCommentPushed = false;

    public PartnerCaseProxyServiceHelper(){

        AppConfiguration__c config = AppConfiguration__c.getInstance();
        if(config != null && config.Verizon_Partner_Service_Retries_Allowed__c != null) {
            noOfRetries = (Integer)config.Verizon_Partner_Service_Retries_Allowed__c;
        }

    }

    // when a new case is created
    public static void PushCaseToProxyService(Set<Id> caseIds){

        system.debug('PushCaseToProxyService(): caseIds - ' + caseIds);
        List<Case> updateList = new List<Case>();
        try {

            PartnerCaseProxyService.SalesforceCase[] caseArray = new PartnerCaseProxyService.SalesforceCase[]{};
            for (Case newCase : [
                    Select Id, CaseNumber, Priority, Description, CreatedDate, X3rdPartyVendorTicket__c,
                            status, Product_or_Service__c, Request_Type__c, Database__c, Releases__c,
                            Account.Name, Account.Billing_Group__c, Account.CadebillAccountNo__c, Account.Partner_Customer_Account_ID__c,
                            Contact.Name, Contact.Phone, OwnerId, Owner.Name, Owner.Phone, Push_To_Partner__c,
                            ETMS_Trouble_Report_State__c, ETMS_Trouble_Report_Status__c, Dial_From_ANI__c, Dial_To_DNIS__c,
                            Customer_s_Toll_Free_POC__c, Incident_Location__c
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
            proxy.CreatePartnerCase(caseRequest, BILLING_GROUP_VERIZON, noOfRetries);
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

    // when a case is updated that results change in trouble report state or status
    public static void PushCaseStatusUpdateToProxyService(Set<Id> caseIds){

        system.debug('PushCaseStatusUpdateToProxyService(): caseIds - ' + caseIds);
        try {
            PartnerCaseProxyService.PartnerCaseUpdate[] caseUpdateArray = new PartnerCaseProxyService.PartnerCaseUpdate[]{
            };
            for (Case newCase : [
                    Select Id, CaseNumber, X3rdPartyVendorTicket__c, LastModifiedDate,
                            ETMS_Trouble_Report_State__c, ETMS_Trouble_Report_Status__c, Priority
                    from Case
                    where Id IN :caseIds
                    and Account.Billing_Group__c = :BILLING_GROUP_VERIZON
            ]) {
                PartnerCaseProxyService.PartnerCaseUpdate partnerCaseUpdate = createPartnerCaseUpdate(newCase);
                caseUpdateArray.add(partnerCaseUpdate);
            }

            if(caseUpdateArray.size() > 0){
                callUpdatePartnerCase(caseUpdateArray);
                if(test.isRunningTest()) isCasePushed = true;
            }

        } catch (system.CalloutException ex) {
            system.debug('PushCaseStatusUpdateToProxyService(): CalloutException - ' + ex);
            String subject = String.join(new List<Id>(caseIds), ',');
            subject = subject + ' - PartnerCaseProxyService callout failed.';
            SendErrorEmail( ex, subject);
        }catch(system.Exception ex){
            system.debug('PushCaseStatusUpdateToProxyService(): Exception - ' + ex);
            String subject = String.join(new List<Id>(caseIds), ',');
            subject = subject + ' - Failed to callout PartnerCaseProxyService.';
            SendErrorEmail( ex, subject);
        }

    }

    // when a new case comment is created
    public static void PushCaseCommentToProxyService(Set<Id> commentIds){

        system.debug('PushCaseCommentToProxyService(): commentIds - ' + commentIds);
        try {
            PartnerCaseProxyService.PartnerCaseUpdate[] caseUpdateArray = new PartnerCaseProxyService.PartnerCaseUpdate[]{};
            Map<Id, CaseComment> events = new Map<Id, CaseComment>();
            for (CaseComment newComment : [
                    Select Id, CommentBody, IsPublished, CreatedDate, CreatorName,
                            Parent.CaseNumber, Parent.Status, Parent.X3rdPartyVendorTicket__c, Parent.RecordType.Name
                    from CaseComment
                    where Id IN :commentIds
                    and (Parent.Account.Billing_Group__c = :BILLING_GROUP_VERIZON OR Parent.RecordType.Name = 'Event')
            ]) {
                if(newComment.Parent.RecordType.Name == 'Event' && newComment.IsPublished){
                    events.put(newComment.ParentId, newComment);
                }else {
                    PartnerCaseProxyService.PartnerCaseUpdate partnerCaseUpdate = createPartnerCaseUpdate(newComment);
                    caseUpdateArray.add(partnerCaseUpdate);
                }
            }

            if(caseUpdateArray.size() > 0){
                callUpdatePartnerCase(caseUpdateArray);
                if(test.isRunningTest()) isCaseCommentPushed = true;
            }

            if(!events.isEmpty()){
                callSendBulkCaseComment(events);
                if(test.isRunningTest()) {
                    isCaseCommentPushed = true;
                }
            }

        } catch (system.CalloutException ex) {
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

    private static void callUpdatePartnerCase(PartnerCaseProxyService.PartnerCaseUpdate[] caseUpdateArray){

        PartnerCaseProxyService.PartnerCaseProxySoap proxy = new PartnerCaseProxyService.PartnerCaseProxySoap();
        proxy.endpoint_x = 'callout:PartnerCaseProxyService';
        // callout
        PartnerCaseProxyService.ArrayOfPartnerCaseUpdate caseUpdateRequest = new PartnerCaseProxyService.ArrayOfPartnerCaseUpdate();
        caseUpdateRequest.PartnerCaseUpdate = caseUpdateArray;
        proxy.UpdatePartnerCase(caseUpdateRequest, BILLING_GROUP_VERIZON, noOfRetries);

    }

    private static void callSendBulkCaseComment(Map<Id,CaseComment> eventComment){


        Map<Id,String[]> caseList = new Map<Id, String[]>();

        for(Case c:[SELECT Id, CaseNumber, ParentId FROM Case WHERE ParentId IN :eventComment.keySet() AND AccountBillingGroup__c = :BILLING_GROUP_VERIZON AND X3rdPartyVendorTicket__c != null]){
            if(caseList.containsKey(c.ParentId)){
                caseList.get(c.ParentId).add(c.CaseNumber);
            } else {
                caseList.put(c.ParentId, new String[]{c.CaseNumber});
            }
        }

        if(!caseList.isEmpty()) {

            for(Id caseId:caseList.keySet()) {
                PartnerCaseProxyService.PartnerCaseProxySoap proxy = new PartnerCaseProxyService.PartnerCaseProxySoap();
                proxy.endpoint_x = 'callout:PartnerCaseProxyService';
                // callout
                PartnerCaseProxyService.ArrayOfString caseNumbers = new PartnerCaseProxyService.ArrayOfString();
                caseNumbers.string_x = caseList.get(caseId);

                CaseComment comment = eventComment.get(caseId);
                system.debug('callSendBulkCaseComment caseList' + caseNumbers.string_x);
                proxy.SendBulkUpdateComment(caseNumbers,comment.CommentBody,comment.CreatedDate, noOfRetries);
            }
        }

    }

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

        locationCountryMap = new Map<String, ETMS_Incident_Location_To_Country__mdt>();
        for(ETMS_Incident_Location_To_Country__mdt mdt : [
                Select Incident_Location__c, Country__c from ETMS_Incident_Location_To_Country__mdt
        ]){
            locationCountryMap.put(mdt.Incident_Location__c, mdt);
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
        // Product property default value PRODUCT_HOSTING
        //partnerCase.Product = sfCase.Product_or_Service__c;
        partnerCase.RequestType = sfCase.Request_Type__c;

        String cadebillAccountNoText = sfCase.Account.CadebillAccountNo__c != null
                ? sfCase.Account.CadebillAccountNo__c.format().remove(',') : null;

        if(sfCase.Product_or_Service__c == PRODUCT_TOLLFREE){
            partnerCase.DialFrom = String.isBlank(sfCase.Dial_From_ANI__c) ? null : sfCase.Dial_From_ANI__c.replace(' ','');
            partnerCase.DialTo = String.isBlank(sfCase.Dial_To_DNIS__c) ? null : sfCase.Dial_To_DNIS__c.replace(' ','');
            partnerCase.NEID = sfCase.Customer_s_Toll_Free_POC__c;
            partnerCase.ServiceId = sfCase.Customer_s_Toll_Free_POC__c;
            partnerCase.Product = PRODUCT_DIALTF;
        } else{
            partnerCase.NEID = cadebillAccountNoText;
            String serviceId = String.isNotBlank(sfCase.Account.Partner_Customer_Account_ID__c)
                    ? sfCase.Account.Partner_Customer_Account_ID__c : cadebillAccountNoText;
            partnerCase.ServiceId = String.isNotBlank(serviceId) ? serviceId.removeStartIgnoreCase(PARTNER_CUSTOMER_ID_PREFIX) : null;
            partnerCase.Product = (String.isNotBlank(serviceId) && serviceId.startsWithIgnoreCase(PARTNER_CUSTOMER_ID_PREFIX))
                    ? PRODUCT_GENERAL : PRODUCT_HOSTING;
        }

        if(partnerCase.Product == PRODUCT_DIALTF && locationCountryMap.containsKey(sfCase.Incident_Location__c)){
            partnerCase.Country = locationCountryMap.get(sfCase.Incident_Location__c).Country__c;
        } else{
            partnerCase.Country = DEFAULT_COUNTRY_USA;
        }

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

        String logString = 'Product {0}, NEID {1}, ServiceId {2}, EtmsTroubleType {3}, TroubleTypeDescription {4}';
        logString = String.format(logString, new String[]{
                partnerCase.Product, partnerCase.NEID, partnerCase.ServiceId, partnerCase.EtmsTroubleType, partnerCase.TroubleTypeDescription
        });
        system.debug('logString - ' + logString);

        system.debug('createPartnerCase(): partnerCase - ' + partnerCase);
        return partnerCase;

    } // end of createPartnerCase()

    private static PartnerCaseProxyService.PartnerCaseUpdate createPartnerCaseUpdate(CaseComment sfCaseComment){

        system.debug('createPartnerCaseUpdate(): sfCaseComment - ' + sfCaseComment);
        PartnerCaseProxyService.PartnerCaseUpdate partnerCaseUpdate = new PartnerCaseProxyService.PartnerCaseUpdate();
        partnerCaseUpdate.Comment = sfCaseComment.CommentBody;
        partnerCaseUpdate.UpdateDateTime = sfCaseComment.CreatedDate;
        partnerCaseUpdate.CaseNumber = sfCaseComment.Parent.CaseNumber;
        system.debug('createPartnerCaseUpdate(): partnerCaseUpdate - ' + partnerCaseUpdate);
        return partnerCaseUpdate;

    }

    private static PartnerCaseProxyService.PartnerCaseUpdate createPartnerCaseUpdate(Case sfCase){

        system.debug('createPartnerCaseUpdate(): sfCase - ' + sfCase);
        PartnerCaseProxyService.PartnerCaseUpdate partnerCaseUpdate = new PartnerCaseProxyService.PartnerCaseUpdate();
        partnerCaseUpdate.TroubleReportState = (Integer)sfCase.ETMS_Trouble_Report_State__c;
        partnerCaseUpdate.TroubleReportStatus = (Integer)sfCase.ETMS_Trouble_Report_Status__c;
        partnerCaseUpdate.UpdateDateTime = sfCase.LastModifiedDate;
        partnerCaseUpdate.CaseNumber = sfCase.CaseNumber;
        partnerCaseUpdate.PreferredPriority = sfCase.Priority;

        //These are hardcoded as of 2/13/18 to look for Closed status updates to Verizon
        if(sfCase.ETMS_Trouble_Report_State__c == 4 && sfCase.ETMS_Trouble_Report_Status__c == 27) {
            partnerCaseUpdate.Comment = 'System Closed';
        }

        system.debug('createPartnerCaseUpdate(): partnerCaseUpdate - ' + partnerCaseUpdate);
        return partnerCaseUpdate;

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