/**
 * Created by mohandaas.rangaswamy on 3/3/2017.
 */

public class CaseCommentTriggerHandler extends TriggerHandler {

    private static boolean staticValuesSet = false;
    private static boolean isProxyServiceTurnedOff = false;
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
            }
        }
    }

    protected override void afterInsert(){
        if(!isProxyServiceTurnedOff && !bypassProxyService){
            CallPartnerCaseProxyService((List<CaseComment>) trigger.new, (Map<Id, CaseComment>) trigger.oldMap);
        }
        if (AllCommentTriggerHelper.hasAlreadyCreatedComments() == false){
            AllCommentTriggerHelper.setAlreadyCreatedComments();
            CopyCustomComments ((List<CaseComment>) trigger.new, (Map<Id, CaseComment>) trigger.oldMap);
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
                and IsClosed = false
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

}