/**
 * Created by arnab.karsarkar on 4/3/2017.
 */

public with sharing class KnownIssueScoreReportController {

    public string currentDateTime {get; set;}


    public KnownIssueScoreReportController(){
        Datetime myDT = Datetime.now();
        currentDateTime = myDT.format('MM/dd/yyyy - h:mm a');

    }

    @RemoteAction
    public static string GetKnownIssues (string filterData, integer offsetInteger ){
        string result = KnownIssueViewHelper.GetKnownIsssues(filterData, offsetInteger);
        return result;
    }

    @RemoteAction
    public static string GetAccounts (string KICaseId){

        set<Id> accountIds = new set<Id>();
        list<AccountLists> accounts = new list<AccountLists>();
        for(Case incident : [select Id, AccountId, Account.Name, Account.CadebillAccountNoText__c, Account.RecordType.name
                             From Case
                             where KnownIssue__c = :KICaseId ]){

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






    @RemoteAction
    public static string GetAccounts (string KICaseId){

        set<Id> accountIds = new set<Id>();
        list<AccountLists> accounts = new list<AccountLists>();
        for(Case incident : [select Id, AccountId, Account.Name, Account.CadebillAccountNoText__c, Account.RecordType.name
                             From Case
                             where KnownIssue__c = :KICaseId ]){

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
 @RemoteAction
    public static Datetime GetLastLoadDateTime()
    {
        return Datetime.now();
    }


    public class AccountLists {
        public string  AccountId {get; set;}
        public string  AccountName {get; set;}
        public string  CadeBillNum {get; set;}
        public string  AccountRecordType {get; set;}
    }





}