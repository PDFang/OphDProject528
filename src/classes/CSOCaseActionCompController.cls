/**
 * Created by ravish.chawla on 1/11/2018.
 */

public with sharing class CSOCaseActionCompController {
    public String currentCommentCaseId{get;set;}
    public Case csoCaseDetails{get; set;}
    public List<Group> queueIds {get; set;}
    public Boolean showCloseCaseButton {get; set;}
    public List<SelectOption> cosCaseCloseSubReason {get; set;}


    public CSOCaseActionCompController(){
        if (currentCommentCaseId == null) {
            currentCommentCaseId = System.currentPageReference().getParameters().get('id');
        }
        csoCaseDetails = getCaseDetails(currentCommentCaseId);
        queueIds = getQueueId();
        showCloseCaseButton = getOrderLineItemsStatus(csoCaseDetails);
        cosCaseCloseSubReason = getCSOCaseCloseSubReason();

    }

    static Case currentCase;


    @RemoteAction
    public static string saveCaseComment(string comment, Boolean isCommentPublic, string caseId){
        try{
            System.debug('InSaveCaseComment');
            if(comment == '' || comment == null)
                return 'Empty comments are not allowed to save.';


            CaseComment newCaseComment = new CaseComment(
                    CommentBody = comment,
                    IsPublished = isCommentPublic,
                    ParentId = caseId
            );
            insert newCaseComment;
            return 'Success';
        }catch (Exception ex){
            return 'Error while adding case comment. Technical error message -  ' + ex.getMessage();
        }
    }


    @RemoteAction
    public static string SendToCOPQueue(string Id, string caseId){
        try{
            System.debug('SendToCOPQueue');
            Case caseDet = [Select Id, OwnerId from Case where Id =: caseId Limit 1];
            caseDet.OwnerId = Id;

            update caseDet;
            return 'Success';
        }catch (Exception ex){
            return 'Error while adding case comment. Technical error message -  ' + ex.getMessage();
        }
    }

    @RemoteAction
    public static string closeCSOCase(string closeSubReason, string caseId){
        try{
            System.debug('closeCSOCase');
            Case caseDet = [Select Id, Disposition__c, Closed_Reason__c from Case where Id =: caseId Limit 1];
            caseDet.Disposition__c = closeSubReason;
            caseDet.Closed_Reason__c = 'CSO - DID Manual Process';

            update caseDet;
            return 'Success';
        }catch (Exception ex){
            return 'Error while closing the case. Technical error message -  ' + ex.getMessage();
        }
    }



    public static Case getCaseDetails(string caseId){
        try{

            Case rtnCase = [Select CSO_Resolution_Type__c, Assigned_To__c, OwnerId, CustomerOrder__c, CustomerOrder__r.Name, Disposition__c, Closed_Reason__c  from Case where Id =: caseId Limit 1];
            System.debug('queIds >' + rtnCase);
            return rtnCase;

        }catch(Exception ex){
            return null;
        }
    }

    public static List<Group> getQueueId(){
        try{

            List<Group> queueIds = new List<Group>([Select g.ID, g.Name from Group g Where g.Name = 'Customer Operations Queue' LIMIT 1]);
            System.debug('queIds >' + queueIds);
            return queueIds;

        }catch(Exception ex){
            return null;
        }
    }

    public static Boolean getOrderLineItemsStatus(Case caseDetail){
        try{
            Boolean showCloseBtn = false;
            List<OrderLineGeneralItems__c> csoOrderLineItems = new List<OrderLineGeneralItems__c>();
            csoOrderLineItems = [SELECT ItemId__c, ItemStatus__c from OrderLineGeneralItems__c where CustomerOrder__c =: caseDetail.CustomerOrder__c AND ItemStatus__c NOT IN ('Completed','Canceled','Closed')];

            if(csoOrderLineItems.size() == 0)
                showCloseBtn = true;

            return showCloseBtn;

        }catch(Exception ex){
             return false;
        }

    }

    public static List<SelectOption> getCSOCaseCloseSubReason(){
        try{

            List<SelectOption> options = new List<SelectOption>{ new SelectOption('', '-Select Sub Reason-')};

            Schema.DescribeFieldResult fieldResult = Case.Disposition__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();


            for( Schema.PicklistEntry f : ple)
            {
                options.add(new SelectOption(f.getLabel(), f.getValue()));
            }
            return options;

        }catch(Exception ex){
            return null;
        }
    }
}