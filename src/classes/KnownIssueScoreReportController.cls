/**
 * Created by arnab.karsarkar on 4/3/2017.
 */

public with sharing class KnownIssueScoreReportController {

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
        for(Case incident : [select Id, AccountId, Account.Name, Account.CadebillAccountNoText__c, Account.RecordType.name
                             From Case
                             where KnownIssue__c = :KICaseId and AccountId != null ]){

            if(!accountIds.contains(incident.AccountId)){
                accountIds.add(incident.AccountId);
                // Add to the list
                AccountLists newAccount = new AccountLists();
                newAccount.AccountId = incident.AccountId;
                newAccount.AccountName = incident.Account.Name;
                newAccount.AccountRecordType = incident.Account.RecordType.Name;
                newAccount.CadeBillNum = incident.Account.CadebillAccountNoText__c;
                accounts.add(newAccount);
            }
        }

        return JSON.serialize(accounts);
    }

    public class AccountLists {
        public string  AccountId {get; set;}
        public string  AccountName {get; set;}
        public string  CadeBillNum {get; set;}
        public string  AccountRecordType {get; set;}
    }










}