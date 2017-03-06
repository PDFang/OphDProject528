/**
 * Created by mohandaas.rangaswamy on 3/3/2017.
 */

public class CaseCommentTriggerHandler extends TriggerHandler {

    protected override void afterInsert(){
        CallPartnerCaseProxyService((List<CaseComment>) trigger.new, (Map<Id, CaseComment>) trigger.oldMap);
    }

    // push case comments to partner case proxy service
    // Case must be of type Incident and have a X3rdPartyVendorTicket__c
    public static void CallPartnerCaseProxyService(List<CaseComment> newList, Map<Id, CaseComment> oldMap){

        Set<Id> caseIdSet = new Set<Id>();
        for(CaseComment newComment : newList){
            // Does it have to be published?
            caseIdSet.add(newComment.ParentId);
        }

        Map<Id, Case> caseMap = new Map<Id, Case>([
                Select Id, X3rdPartyVendorTicket__c, AccountId, RecordTypeId from Case
                where Id IN :caseIdSet
                and Case.Account.Billing_Group__c = :PartnerCaseProxyServiceHelper.BILLING_GROUP_VERIZON
                and Case.RecordType.Name = 'Incident'
                and Case.X3rdPartyVendorTicket__c != null
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