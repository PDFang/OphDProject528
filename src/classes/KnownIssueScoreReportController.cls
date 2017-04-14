/**
 * Created by arnab.karsarkar on 4/3/2017.
 */

public without sharing class KnownIssueScoreReportController {

    public string currentDateTime {get; set;}
    public integer pageSize {get; set;}

    public KnownIssueScoreReportController(){
        refreshDateTime();
        pageSize = KnownIssueViewHelper.PageSize;
    }

    public void refreshDateTime()
    {
        Datetime myDT = Datetime.now();
        currentDateTime = myDT.format('MM/dd/yyyy - h:mm a');
    }

    @RemoteAction
    public static string GetKnownIssues (){
        string result = KnownIssueViewHelper.GetKnownIsssues();
        return result;
    }

    @RemoteAction
    public static string GetFilterString (string fieldName, string fieldValue ) {
        string result = KnownIssueViewHelper.GetSpecificFieldValue(fieldName, fieldValue);
        return result;
    }

    @RemoteAction
    public static string GetAccounts (string KICaseId){

        set<Id> accountIds = new set<Id>();
        list<AccountLists> accounts = new list<AccountLists>();
        for(Case incident : [select Id, AccountId
                             From Case
                             where KnownIssue__c = :KICaseId and AccountId != null ]){

            if(!accountIds.contains(incident.AccountId)){
                accountIds.add(incident.AccountId);
            }
        }


        for(JBCXM__CustomerInfo__c CustInfo :
                            [select Id, JBCXM__ASV__c,JBCXM__Account__c, JBCXM__Account__r.Name, JBCXM__Account__r.RecordType.Name,JBCXM__Account__r.CadebillAccountNoText__c
                             From JBCXM__CustomerInfo__c
                             WHERE JBCXM__Account__c in :accountIds order by JBCXM__ASV__c desc]){

            // Add to the list
            AccountLists newAccount = new AccountLists();
            newAccount.AccountId = CustInfo.JBCXM__Account__c;
            newAccount.AccountName = CustInfo.JBCXM__Account__r.Name;
            newAccount.AccountRecordType = CustInfo.JBCXM__Account__r.RecordType.Name;
            newAccount.CadeBillNum = CustInfo.JBCXM__Account__r.CadebillAccountNoText__c;
            newAccount.ACVValue =  CustInfo.JBCXM__ASV__c;
            accounts.add(newAccount);

        }

        return JSON.serialize(accounts);
    }

    public class AccountLists {
        public string  AccountId {get; set;}
        public string  AccountName {get; set;}
        public string  CadeBillNum {get; set;}
        public string  AccountRecordType {get; set;}
        public double  ACVValue {get; set;}
    }










}