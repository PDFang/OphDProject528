/**
 * Created by mohandaas.rangaswamy on 2/21/2017.
 */

public class OpportunityShareHelper {

    static Map<ID, List<User>> accountUserMap = null; // key account Id
    static Map<Id, List<Account_Partner__c>> partnerMap = null; // key customer Id

    public static final Set<String> opportunityRecordTypeSet = new Set<String>{
            'GSD PS Requests',
            'PM - Standard',
            'New Opportunity',
            'Qualified Opportunity'
    };

    public class OpportunityShareHelperException extends Exception{}

    // Share Opportunities with partner account users
    public void addShare(List<Opportunity> newList, Map<Id, Opportunity> oldMap){

        if(newList == null || newList.isEmpty()){
            return;
        }

        Set<Id> recordIdSet = new Set<Id>();
        for(Opportunity record : newList){
            Opportunity oldRecord = ( oldMap != null ) ? oldMap.get(record.Id) : null;
            // Partner account
            if((record.Partner_Account__c != null && ( oldRecord == null || oldRecord.Partner_Account__c != record.Partner_Account__c )) ||
               (record.Sub_Agent_Account__c != null && ( oldRecord == null || oldRecord.Sub_Agent_Account__c != record.Sub_Agent_Account__c )) ||
               (record.Certified_Implementation_Partner__c != null && ( oldRecord == null ||
                       oldRecord.Certified_Implementation_Partner__c != record.Certified_Implementation_Partner__c ))    ){
                recordIdSet.add(record.Id);
            }
            // iCE Partner account
            else if(record.iCE_Partner__c != null && record.iCE_Partner_Status__c == 'Accepted' && record.StageName == OpportunityTriggerHelper.OPPORTUNITY_STAGE_CLOSED_WON && ( oldRecord == null || oldRecord.iCE_Partner__c != record.iCE_Partner__c || oldRecord.StageName != OpportunityTriggerHelper.OPPORTUNITY_STAGE_CLOSED_WON ) ){
                recordIdSet.add(record.Id);
            }
            // owner change
            else if(oldRecord != null && oldRecord.OwnerId != record.OwnerId && (record.Partner_Account__c != null || (record.iCE_Partner__c != null && record.iCE_Partner_Status__c == 'Accepted' && record.StageName == OpportunityTriggerHelper.OPPORTUNITY_STAGE_CLOSED_WON )) ){
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
        for(Opportunity record : [
                Select Id, Partner_Account__c, iCE_Partner__c, RecordType.Name, Certified_Implementation_Partner__c, Sub_Agent_Account__c from Opportunity
                where Id IN :recordIdSet and (Partner_Account__c != null or iCE_Partner__c != null or Sub_Agent_Account__c != null or Certified_Implementation_Partner__c != null)
        ]){
            recordList.add(record);
            if(record.Partner_Account__c != null){
                partnerIdSet.add(record.Partner_Account__c);
            }
            if(record.Sub_Agent_Account__c != null && opportunityRecordTypeSet.contains(record.RecordType.Name)){
                partnerIdSet.add(record.Sub_Agent_Account__c);
            }
            if(record.Certified_Implementation_Partner__c != null && opportunityRecordTypeSet.contains(record.RecordType.Name)){
                partnerIdSet.add(record.Certified_Implementation_Partner__c);
            }
            if(record.iCE_Partner__c != null){
                partnerIdSet.add(record.iCE_Partner__c);
            }

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
            List<User> userList = new List<User>();
            if(record.Partner_Account__c != null && lAccountUserMap.containsKey(record.Partner_Account__c)){
                userList.addAll(lAccountUserMap.get(record.Partner_Account__c));
            }
            if(record.Sub_Agent_Account__c != null && lAccountUserMap.containsKey(record.Sub_Agent_Account__c)){
                userList.addAll(lAccountUserMap.get(record.Sub_Agent_Account__c));
            }
            if(record.Certified_Implementation_Partner__c != null && lAccountUserMap.containsKey(record.Certified_Implementation_Partner__c)){
                userList.addAll(lAccountUserMap.get(record.Certified_Implementation_Partner__c));
            }
            if(record.iCE_Partner__c != null && lAccountUserMap.containsKey(record.iCE_Partner__c)){
                userList.addAll(lAccountUserMap.get(record.iCE_Partner__c));
            }
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
            }// end user iteration
        } // end opportunity iteration

        system.debug(' **** addShareFuture() : shareList - '+shareList);
        if(shareList.isEmpty() == false){
            Database.saveResult[] resultList=  Database.insert(shareList, false);
            for(Database.saveResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** addShareFuture() : error - '+ result.getErrors()[0]);
                    inContactBaseClass.SendErrorEmail( String.valueOf(result.getErrors()[0]), result.getId());
                    //throw new OpportunityShareHelperException(result.getErrors()[0].getMessage());
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
            if( oldRecord != null && oldRecord.Certified_Implementation_Partner__c != null && oldRecord.Certified_Implementation_Partner__c != record.Certified_Implementation_Partner__c ){
                recordIdSet.add(record.Id);
                partnerIdSet.add(oldRecord.Certified_Implementation_Partner__c);
            }
            if( oldRecord != null && oldRecord.Sub_Agent_Account__c != null && oldRecord.Sub_Agent_Account__c != record.Sub_Agent_Account__c ){
                recordIdSet.add(record.Id);
                partnerIdSet.add(oldRecord.Sub_Agent_Account__c);
            }
            // Partner account updated and previous value not blank
            if( oldRecord != null && oldRecord.iCE_Partner__c != null && oldRecord.iCE_Partner__c != record.iCE_Partner__c ){
                recordIdSet.add(record.Id);
                partnerIdSet.add(oldRecord.iCE_Partner__c);
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
                    inContactBaseClass.SendErrorEmail( String.valueOf(result.getErrors()[0]), result.getId());
                    //throw new OpportunityShareHelperException(result.getErrors()[0].getMessage());
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