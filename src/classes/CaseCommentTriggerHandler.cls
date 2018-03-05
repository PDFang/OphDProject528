/**
 * Created by mohandaas.rangaswamy on 3/3/2017.
 */

public class CaseCommentTriggerHandler extends TriggerHandler {

    private static boolean staticValuesSet = false;
    private static boolean isProxyServiceTurnedOff = false;
    private static boolean isXMCommentNotificationTurnedOff = false;
    //private static boolean isSetCommentDuringUpdate = false;

    public static boolean alreadyCopiedComments = false;
    public static boolean bypassProxyService = false;

    public CaseCommentTriggerHandler()
    {
        if(!staticValuesSet)
        {
            staticValuesSet = true;
            AppConfiguration__c config = AppConfiguration__c.getInstance();
            if(config != null) {
                isProxyServiceTurnedOff = config.Turn_Off_Partner_Case_Proxy_Service__c;
                isXMCommentNotificationTurnedOff = config.XM_Turn_Off_Comment_Notifications__c;
            }
        }
    }

    protected override void afterInsert(){

        if(!isXMCommentNotificationTurnedOff){
            createXMNotification((List<CaseComment>) trigger.new, (Map<Id, CaseComment>) trigger.oldMap);
        }
        if(!isProxyServiceTurnedOff && !bypassProxyService){
            CallPartnerCaseProxyService((List<CaseComment>) trigger.new, (Map<Id, CaseComment>) trigger.oldMap);
        }
        if (AllCommentTriggerHelper.hasAlreadyCreatedComments() == false){
            AllCommentTriggerHelper.setAlreadyCreatedComments();
            CopyCustomComments ((List<CaseComment>) trigger.new, (Map<Id, CaseComment>) trigger.oldMap);
        }

    }

    protected override void afterUpdate() {

        if (!isXMCommentNotificationTurnedOff) {
            createXMNotification((List<CaseComment>) trigger.new, (Map<Id, CaseComment>) trigger.oldMap);
        }

    }

    public static void UpdateCustomComments(List<CaseComment> newList, Map<Id, CaseComment> oldMap){
        system.debug('Calling UpdateCustomComments');
        List<Case_Comment_Custom__c> commentList = new List<Case_Comment_Custom__c>();
        for(CaseComment newComment : newList){
            if(newComment.IsPublished == false){
                commentList.add(GetNewCustomComment(newComment));
            }
        }
        //need the ID --
        Update(commentList);
    }


    public static void CopyCustomComments(List<CaseComment> newList, Map<Id, CaseComment> oldMap){
        system.debug('Calling CopyCustomComments');
        List<Case_Comment_Custom__c> commentList = new List<Case_Comment_Custom__c>();
        for(CaseComment newComment : newList){
            if(newComment.IsPublished == false){
                commentList.add(GetNewCustomComment(newComment));
            }
        }
        Upsert(commentList);
    }
    private static string GetUserById(Id userId){

        User u = [select id, Name from user where id =: userId];
        return u.Name;
    }

    private static Case_Comment_Custom__c GetNewCustomComment(CaseComment newComment){
        system.debug('GetNewCustomComment');
        Case_Comment_Custom__c comment = new Case_Comment_Custom__c();
        comment.ParentId__c = NewComment.ParentId;
        comment.CommentBody__c = NewComment.CommentBody;
        comment.CommentCreatedDate__c = NewComment.CreatedDate;
        if (NewComment.CreatedById !=null){
            comment.CreatorName__c = GetUserById(NewComment.CreatedById);
        }
        comment.IsDeleted__c = NewComment.IsDeleted;
        comment.IsPublished__c = newComment.IsPublished;
        comment.Case_Comments_Id__c = (string) newComment.id;
        //comment.Id = NewComment.Id;
        return comment;
    }
    // push case comments to partner case proxy service
    // Case must be of type Incident and have a X3rdPartyVendorTicket__c
    public static void CallPartnerCaseProxyService(List<CaseComment> newList, Map<Id, CaseComment> oldMap){

        Set<Id> caseIdSet = new Set<Id>();
        for(CaseComment newComment : newList){
            if(newComment.IsPublished){
                caseIdSet.add(newComment.ParentId);
            }
        }

        if(caseIdSet.isEmpty()){
            return;
        }
        Map<Id, Case> caseMap = new Map<Id, Case>([
                Select Id, X3rdPartyVendorTicket__c, AccountId, RecordTypeId, Status from Case
                where Id IN :caseIdSet
                and Account.Billing_Group__c = :PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON
                and RecordType.Name = 'Incident'
                and X3rdPartyVendorTicket__c != null
                //and IsClosed = false
        ]);
        system.debug('CallPartnerCaseProxyService(): caseMap - ' + caseMap);

        if(caseMap.isEmpty()){
            return;
        }

        Set<Id> createdIdSet = new Set<Id>();
        for(CaseComment newComment : newList){
            Case record = caseMap.get(newComment.ParentId);
            if(record != null){
                createdIdSet.add(newComment.Id);
            }
        }
        system.debug('CallPartnerCaseProxyService(): createdIdSet - ' + createdIdSet);
        if(createdIdSet.size() > 0){
            CallPartnerCaseProxyServiceFuture(createdIdSet);
        }

    } // end of CallPartnerCaseProxyService()

    @future(callout=true)
    private static void CallPartnerCaseProxyServiceFuture(Set<Id> commentIds){

        PartnerCaseProxyServiceHelper.PushCaseCommentToProxyService(commentIds);
    }

    // Create an xmNotification record when new comment is added or existing comment is published
    private void createXmNotification(List<CaseComment> newList, Map<Id, CaseComment> oldMap){

        List<CaseComment> processList = new List<CaseComment>();
        Set<Id> caseIdSet = new Set<Id>();

        // new comment is added or existing comment is published
        for(CaseComment comment : newList) {
            CaseComment oldComment = (oldMap != null && oldMap.containsKey(comment.Id)) ? oldMap.get(comment.Id) : null;
            if(comment.IsPublished && (oldComment == null || comment.IsPublished != oldComment.IsPublished) ){
                processList.add(comment);
                caseIdSet.add(comment.ParentId);
            }
        }

        system.debug('createXmNotification(): processList - ' + processList);

        if(processList.isEmpty()){
            return;
        }

        Map<Id, Case> caseMap = new Map<Id, Case>([
                Select Id, Priority, RecordTypeId, InternalEvent__c, NonEvent__c from Case
                where Id IN :caseIdSet and Status IN ('Confirmed', 'Being Worked')
        ]);
        system.debug('createXmNotification(): caseMap - ' + caseMap);

        List<xmNotification__c> notificationList = new List<xmNotification__c>();

        for(CaseComment comment : processList){

            Case parentCase = caseMap.get(comment.ParentId);
            if(parentCase == null || !CaseTriggerHandler.isQualifiedEvent(parentCase)){
                continue;
            }
            xmNotification__c xmNotification = new xmNotification__c(
                    Case__c = comment.ParentId,
                    Request_Date__c = system.now(),
                    Request_Type__c = XMNotificationTriggerHandler.REQUEST_TYPE_COMMENT,
                    Public_Comment__c = comment.CommentBody
            );
            notificationList.add(xmNotification);
        }

        system.debug('createXmNotification(): notificationList - ' + notificationList);

        if(notificationList.isEmpty())
            return;

        try{
            insert notificationList;
        }catch(Exception ex){
            system.debug('createXmNotification(): Exception - ' + ex);
            inContactBaseClass.SendErrorEmail(ex, processList[0].Id + ' - Failed to create xMatters notification request');
        }finally {
            // avoid recursion
            isXMCommentNotificationTurnedOff = true;
        }

    }

}