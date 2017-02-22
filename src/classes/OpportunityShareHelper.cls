/**
 * Created by mohandaas.rangaswamy on 2/21/2017.
 */

public with sharing class OpportunityShareHelper {

    static Map<ID, List<User>> accountUserMap = null; // key account Id
    static Map<Id, List<Account_Partner__c>> partnerMap = null; // key customer Id

    public class OpportunityShareHelperException extends Exception{}

    // Share Opportunities with partner account users
    public void addShare(List<Opportunity> newList, Map<Id, Opportunity> oldMap){

        if(newList == null || newList.isEmpty()){
            return;
        }

        Set<Id> recordIdSet = new Set<Id>();
        for(Opportunity record : newList){
            Opportunity oldRecord = ( oldMap != null ) ? oldMap.get(record.Id) : null;
            if(record.Partner_Account__c != null && ( oldRecord == null || oldRecord.Partner_Account__c != record.Partner_Account__c ) ){
                recordIdSet.add(record.Id);
            }
        }
        system.debug(' **** addShare() : recordIdSet - '+recordIdSet);

        if(recordIdSet.isEmpty() == false){
            addShareFuture(recordIdSet);
        }

    } // end of addShare()

    @Future
    private static void addShareFuture(Set<Id> recordIdSet){

        List<Opportunity> recordList = new List<Opportunity>();
        Set<Id> partnerIdSet = new Set<Id>();
        for(Opportunity opp : [
                Select Id, Partner_Account__c, RecordType.Name from Opportunity
                where Id IN :recordIdSet and Partner_Account__c != null
        ]){
            recordList.add(opp);
            partnerIdSet.add(opp.Partner_Account__c);
        }
        system.debug(' **** addShareFuture() : recordList - '+recordList);
        if(recordList.isEmpty()){
            return;
        }

        // Get partner user info
        Map<ID, List<User>> lAccountUserMap = findPartnerUsers(partnerIdSet);
        if(lAccountUserMap.isEmpty()){
            return;
        }
        system.debug(' **** addShareFuture() : lAccountUserMap - '+lAccountUserMap);

        List<OpportunityShare> shareList = new List<OpportunityShare>();
        for(Opportunity record : recordList){
            List<User> userList = lAccountUserMap.get(record.Partner_Account__c);
            system.debug(' **** addShareFuture() : userList - '+userList);
            if (userList == null || userList.isEmpty()) {
                continue;
            }
            // user iteration
            for (User partnerUser :userList) {
                OpportunityShare share = new OpportunityShare();
                share.OpportunityId = record.Id;
                share.UserOrGroupId = partnerUser.Id;
                share.OpportunityAccessLevel = 'Edit';
                shareList.add(share);
            } // end user iteration
        } // end opportunity iteration

        system.debug(' **** addShareFuture() : shareList - '+shareList);
        if(shareList.isEmpty() == false){
            Database.saveResult[] resultList=  Database.insert(shareList, false);
            for(Database.saveResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** addShareFuture() : error - '+ result.getErrors()[0]);
                    throw new OpportunityShareHelperException(result.getErrors()[0].getMessage());
                }
            }
        }

    } // end of addShareFuture()

    // delete Opportunity share records
    public void deleteShare(List<Opportunity> newList, Map<Id, Opportunity> oldMap){

        if(newList == null || newList.isEmpty()){
            return;
        }

        Set<Id> recordIdSet = new Set<Id>();
        Set<Id> customerIdSet = new Set<Id>();
        Set<Id> partnerIdSet = new Set<Id>();
        for(Opportunity record : newList){
            Opportunity oldRecord = ( oldMap != null ) ? oldMap.get(record.Id) : null;
            // Partner account updated and previous value not blank
            if( oldRecord != null && oldRecord.Partner_Account__c != null && oldRecord.Partner_Account__c != record.Partner_Account__c ){
                recordIdSet.add(record.Id);
                partnerIdSet.add(oldRecord.Partner_Account__c);
            }
        }
        system.debug(' **** deleteShare() : recordIdSet - '+recordIdSet);

        if(recordIdSet.isEmpty()){
            return;
        }

        // Get partner user info
        Map<ID, List<User>> lAccountUserMap = findPartnerUsers(partnerIdSet);
        Set<Id> userIdSet = new Set<Id>();
        for(List<User> userList : lAccountUserMap.values()){
            for(User u : userList){
                userIdSet.add(u.Id);
            }
        }
        system.debug(' **** deleteShare() : userIdSet - '+userIdSet);

        if(userIdSet.isEmpty()){
            return;
        }

        List<OpportunityShare> shareList = [
                Select Id, OpportunityId, UserOrGroupId from OpportunityShare
                where RowCause = 'Manual' and OpportunityId IN :recordIdSet
                and UserOrGroupId IN :userIdSet
        ];
        system.debug('**** deleteShare(): shareList - '+shareList);

        if(shareList.isEmpty() == false){
            Database.DeleteResult[] resultList=  Database.delete(shareList, false);
            for(Database.DeleteResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** deleteShare() : id - '+ result.getId());
                    system.debug('**** deleteShare() : error - '+ result.getErrors()[0]);
                    throw new OpportunityShareHelperException(result.getErrors()[0].getMessage());
                }
            }
        }

    } // end of deleteShare()

    // retrieve partner user info
    public static Map<ID, List<User>> findPartnerUsers(Set<Id> partnerIdSet)
    {
        system.debug(' **** findPartnerUsers() : partnerIdSet - '+partnerIdSet);
        if(accountUserMap != null && accountUserMap.keySet().containsAll(partnerIdSet)){
            return accountUserMap;
        }
        accountUserMap = new Map<ID, List<User>>();
        if(partnerIdSet.isEmpty() == false) {
            for (User partnerUser : [
                    Select Id, ContactId, AccountId
                    from User
                    where IsPortalEnabled = true and IsActive = true
                    and UserType IN ('Partner', 'PowerPartner')
                    and AccountId IN :partnerIdSet
            ]) {
                List<User> userList = accountUserMap.get(partnerUser.AccountId);
                if (userList == null) {
                    userList = new List<User>();
                    accountUserMap.put(partnerUser.AccountId, userList);
                }
                userList.add(partnerUser);
            }
        }
        system.debug(' **** findPartnerUsers() : accountUserMap - '+accountUserMap);
        return accountUserMap;

    } // end of findPartnerUsers()

}