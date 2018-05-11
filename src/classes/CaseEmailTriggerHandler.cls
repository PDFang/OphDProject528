/**
 * Created by jeremy.sparrell on 5/10/2018.
 */

public class CaseEmailTriggerHandler extends TriggerHandler {

    private static boolean staticValuesSet = false;
    private static Map<Id,Schema.RecordTypeInfo> rtMapById;
    private static Id helpDeskRecordTypeID;
    private static Id eventRecordTypeID;
    private static Id notificationRecordTypeID;
    private static Id incidentRecordTypeId;
    private static Id workOrderRecordTypeId;
    private static Id serviceRequestRecordTypeId;
    public Map<ID,Case> cases;
    public List<Case> casesToUpdate = new List<Case>();
    public List<CaseComment> caseComments = new List<CaseComment>();
    public List<CaseComment> partnerCaseComments = new List<CaseComment>();

    public CaseEmailTriggerHandler(){
        if(!staticValuesSet){
            staticValuesSet = true;
            SetRecordTypeIds();
        }
    }

    protected override void afterInsert(){
        GetAssociatedCases((List<EmailMessage>)trigger.new);
        for(EmailMessage emailMessage:(List<EmailMessage>)trigger.new){

            Case emailCase = cases.get(emailMessage.ParentId);

            if(!HasExcludedSubject(emailMessage) && emailCase.RecordTypeId != eventRecordTypeID && emailCase.RecordTypeId != notificationRecordTypeID) {
                CreateComments(emailMessage, emailCase);
                UpdateCaseStatus(emailMessage, emailCase);
            }
        }
        ProcessAfterInsertUpdates();
        CallPartnerCaseProxyService();
    }

    private void ProcessAfterInsertUpdates(){

        if(!casesToUpdate.isEmpty())
        {
            update casesToUpdate;
        }

        if(!caseComments.isEmpty())
        {
            insert caseComments;
        }

    }

    private void CallPartnerCaseProxyService(){
        if(!partnerCaseComments.isEmpty()){
            Set<Id> caseCommentIds = new Set<Id>();
            for(CaseComment comment:partnerCaseComments){
                caseCommentIds.add(comment.Id);
            }

            CallPartnerCaseProxyServiceFuture(caseCommentIds);
        }
    }

    @future(callout=true)
    private static void CallPartnerCaseProxyServiceFuture(Set<Id> commentIds){

        PartnerCaseProxyServiceHelper.PushCaseCommentToProxyService(commentIds);
    }

    public boolean HasExcludedSubject(EmailMessage e){
        if(e.Subject == NULL
                || e.Subject.containsIgnoreCase('OUT OF OFFICE')
                || e.Subject.containsIgnoreCase('Automatic reply:')) {
            return true;
        } else {
            return false;
        }
    }
    private void UpdateCaseStatus(EmailMessage e, Case c){
        if(e.Incoming){
            //mark help desk tickets
            if(c.RecordTypeId == helpDeskRecordTypeID)
            {
                if(!c.IsClosed)
                {
                    c.Status = 'Email Received';
                }

                casesToUpdate.add(c);
            } else if((c.RecordTypeId == incidentRecordTypeId || rtMapById.get(c.RecordTypeId).getName().Contains('Premise')
                    || c.RecordTypeId == workOrderRecordTypeId || c.RecordTypeId == serviceRequestRecordTypeId)
                    && !c.IsClosed && !e.FromAddress.containsIgnoreCase('incontact.com'))
            {
                c.Status = 'Customer Updated';
                casesToUpdate.add(c);
            }
        } else {

            //mark help desk tickets
            if(c.RecordTypeId == helpDeskRecordTypeID)
            {
                if(!c.IsClosed)
                {
                    c.Status = 'Waiting for Reply';
                }

                casesToUpdate.add(c);
            }
        }
    }


    private void CreateComments(EmailMessage e, Case c){

        String msgBody = '';
        Integer sLimit = 199;

        if(string.isNotBlank(e.TextBody) && e.TextBody.length() < 200)
        {
            sLimit = e.TextBody.length() - 1;
        }

        CaseComment cc = new CaseComment();
        cc.IsPublished = false;
        cc.ParentId = e.ParentId;

        if(e.Incoming)
        {
            msgBody = msgBody + 'EMAIL RECEIVED FROM: ' + e.FromName + '<' + e.FromAddress + '>\n\r';
        }
        else
        {
            msgBody = msgBody + 'EMAIL SENT TO: ' + e.ToAddress + '\n\r';
        }

        msgBody = msgBody + 'SUBJECT: ' + e.Subject + '\n\r';
        msgBody = msgBody + 'For more information see the email attached to the Case \n\r';

        if(string.isNotBlank(e.TextBody))
        {
            msgBody = msgBody + '\n\r' + e.TextBody.substring(0,sLimit);
        }

        cc.CommentBody = msgBody;
        caseComments.Add(cc);
        GetPartnerEmailComments(cc, c);
    }

    private void GetPartnerEmailComments(CaseComment cc, Case c){
        if(c.AccountId != null && c.Account.Billing_Group__c == PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON
                            && c.RecordTypeId == incidentRecordTypeId
                            && c.X3rdPartyVendorTicket__c != null
                ){

            partnerCaseComments.add(cc);
        }
    }

    private void GetAssociatedCases(List<EmailMessage> caseEmails){

        Set<ID> caseIds = new Set<ID>();
        //get all Case IDs
        for(EmailMessage e:caseEmails)
        {
            caseIds.add(e.ParentId);
        }

        cases = new Map<Id,Case>([SELECT CaseNumber, Id, IsClosed, Status, RecordTypeID, OwnerId, Assigned_To__c, X3rdPartyVendorTicket__c, AccountId, Account.Billing_Group__c FROM Case WHERE ID IN:caseIds]);
    }

    private void SetRecordTypeIds(){
        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String,Schema.RecordTypeInfo> recordTypeMapByName = d.getRecordTypeInfosByName();
        rtMapById = d.getRecordTypeInfosById();

        helpDeskRecordTypeID = recordTypeMapByName.get('Help Desk').getRecordTypeId();
        eventRecordTypeID = recordTypeMapByName.get('Event').getRecordTypeId();
        notificationRecordTypeID = recordTypeMapByName.get('Maintenance Notification').getRecordTypeId();
        incidentRecordTypeId = recordTypeMapByName.get('Incident').getRecordTypeId();
        workOrderRecordTypeId = recordTypeMapByName.get('Work Orders').getRecordTypeId();
        serviceRequestRecordTypeId = recordTypeMapByName.get('Service Request').getRecordTypeId();
    }
}