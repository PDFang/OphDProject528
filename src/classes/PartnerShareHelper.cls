/* Generic class to share any sobject records related to customer accounts with affiliated partner users */
/* The public methods shall be called from any sobject trigger */
public class PartnerShareHelper {
/*
    static Map<ID, List<User>> accountUserMap = null; // key account Id
    static Map<Id, List<Account_Partner__c>> partnerMap = null; // key customer Id
    
    static final Map<Schema.SobjectType, String> accountFieldMap = new Map<Schema.SobjectType, String>{
        Project__c.SobjectType => 'Account__c'
        //Checklist1__c.SobjectType => 'Account_Name__c',
        //Buildout__c.SobjectType => 'Account__c',
        //Risk__c.SobjectType => 'Account__c',
        //WorkLog__c.SobjectType => 'Project__r.Account__c'
    };
    
    static final Map<Schema.SobjectType, Schema.SobjectType> shareObjectMap = new Map<Schema.SobjectType, Schema.SobjectType>{
        Project__c.SobjectType => Project__Share.SobjectType
        //Checklist1__c.SobjectType => Checklist1__c.SobjectType,
        //Buildout__c.SobjectType => Buildout__c.SobjectType,
        //Risk__c.SobjectType => Risk__Share.SobjectType,
        //WorkLog__c.SobjectType => WorkLog__Share.SobjectType
    };        
              
    private String objectType = null;
    private String accountField = null;
    
    public class PartnerShareHelperException extends Exception{}     
    
    public void addShare(List<sObject> newList, Map<Id, sObject> oldMap){
        
        if(newList == null || newList.isEmpty()){
            return;
        }
        validateSobjectType(newList);        
        Set<Id> recordIdSet = new Set<Id>();
        for(sObject record : newList){
            sObject oldRecord = ( oldMap != null ) ? oldMap.get(record.Id) : null;
            if( record.get(accountField) != null && ( oldRecord == null || oldRecord.get(accountField) != record.get(accountField) ) ){
                recordIdSet.add(record.Id);
            }
        }
        system.debug(' **** addShare() : recordIdSet - '+recordIdSet);

        if(recordIdSet.isEmpty() == false){
            addShareFuture(objectType, recordIdSet, accountField);
        }

    } // end of addShare()    
    
    @Future
    private static void addShareFuture(String objectType, Set<Id> recordIdSet, String accountField){
        
        List<Sobject> recordList = getRecords(objectType, recordIdSet, accountField);
        system.debug(' **** addShareFuture() : recordList - '+recordList);
        if(recordList.isEmpty()){
            return;
        }

        Set<Id> customerIdSet = new Set<Id>();
        for(Sobject record : recordList){
            customerIdSet.add((Id)record.get(accountField));
        }
        
        Set<Id> partnerIdSet = new Set<Id>();
        Set<Id> groupIdSet = new Set<Id>();
        Map<Id, List<Account_Partner__c>> lPartnerMap = findPartners(customerIdSet);
        for(List<Account_Partner__c> partnerList : lPartnerMap.values()) {
            for (Account_Partner__c partner : partnerList) {
                if(partner.Partner__c != null) {
                    partnerIdSet.add(partner.Partner__c);
                }
            }
        }

        system.debug(' **** addShareFuture() : lPartnerMap - '+lPartnerMap);

        Map<ID, List<User>> lAccountUserMap = findPartnerUsers(partnerIdSet);
        if(lAccountUserMap.isEmpty()){
            return;

        }
        List<Sobject> shareList = new List<Sobject>();        
        Schema.SobjectType parentSobjectType = Schema.getGlobalDescribe().get(objectType);
        
        // record iteration
        for(Sobject record : recordList){
            List<Account_Partner__c> partnerList = lPartnerMap.get((Id)record.get(accountField));
            if(partnerList == null || partnerList.isEmpty()){
                continue;
            }
            // partner iteration
            for(Account_Partner__c partner : partnerList){
                if(partner.PublicGroupId__c != null)
                {
                    Sobject share = shareObjectMap.get(parentSobjectType).newSobject();
                    share.put('ParentId', (Id)record.get('Id'));
                    share.put('UserOrGroupId', partner.PublicGroupId__c);
                    share.put('AccessLevel', 'Edit');
                    shareList.add(share);
                }
                else if(partner.Partner__c != null)
                {
                    List<User> userList = lAccountUserMap.get(partner.Partner__c);
                    if (userList == null || userList.isEmpty()) {
                        continue;
                    }
                    // user iteration
                    for (User partnerUser :userList) {
                        try{
                            Sobject share = shareObjectMap.get(parentSobjectType).newSobject();
                            share.put('ParentId', (Id)record.get('Id'));
                            share.put('UserOrGroupId', partnerUser.Id);
                            share.put('AccessLevel', 'Edit');
                            shareList.add(share);
                        } catch(Exception ex){
                            system.debug(parentSobjectType);
                            system.debug(shareObjectMap);
                            throw ex;
                        }                        
                    } // end user iteration
                }
            } // end partner iteration
        } // end record iteration

        system.debug(' **** addShareFuture() : shareList - '+shareList);
        if(shareList.isEmpty() == false){
            Database.saveResult[] resultList=  Database.insert(shareList, false);
            for(Database.saveResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** addShareFuture() : error - '+ result.getErrors()[0]);
                    throw new PartnerShareHelperException(result.getErrors()[0].getMessage());
                }
            }            
        }

    } // end of addShareFuture()
    
    public void deleteShare(List<sObject> newList, Map<Id, sObject> oldMap){
        
        if(newList == null || newList.isEmpty()){
            return;
        }
        validateSobjectType(newList);
        Set<Id> recordIdSet = new Set<Id>();
        Set<Id> customerIdSet = new Set<Id>();
        for(sObject record : newList){
            sObject oldRecord = ( oldMap != null ) ? oldMap.get(record.Id) : null;
            if( oldRecord != null && oldRecord.get(accountField) != null && oldRecord.get(accountField) != record.get(accountField) ){
                recordIdSet.add(record.Id);
                customerIdSet.add((Id)oldRecord.get(accountField));
            }
        }
        system.debug(' **** deleteShare() : recordIdSet - '+recordIdSet);

        if(recordIdSet.isEmpty()){
            return;
        }
        
        Set<Id> partnerIdSet = new Set<Id>();
        set<Id> groupIdSet = new set<Id>();
        Map<Id, List<Account_Partner__c>> lPartnerMap = findPartners(customerIdSet);
        for(List<Account_Partner__c> partnerList : lPartnerMap.values()) {
            for (Account_Partner__c partner : partnerList) {
                if(partner.PublicGroupId__c != null)
                {
                    groupIdSet.add(partner.PublicGroupId__c);
                }
                else if(partner.Partner__c != null) {
                    partnerIdSet.add(partner.Partner__c);
                }
            }
        }

        if(partnerIdSet.isEmpty()){
            return;
        }

        Map<ID, List<User>> lAccountUserMap = findPartnerUsers(partnerIdSet);
        if(lAccountUserMap.isEmpty()){
            return;
        }

        Set<Id> userIdSet = new Set<Id>();
        for(List<User> userList : lAccountUserMap.values()){
            for(User u : userList){
                userIdSet.add(u.Id);
            }
        }
        
        system.debug(' **** deleteShare() : userIdSet - '+userIdSet);
        
        if(userIdSet.isEmpty() && groupIdSet.isEmpty()){
            return;
        }
        
        set<Id> UserOrGroupIdSet = new set<Id>();
        UserOrGroupIdSet.addAll(groupIdSet); // Group ID's
        UserOrGroupIdSet.addAll(userIdSet); // User ID's
        
        Schema.SobjectType parentSobjectType = Schema.getGlobalDescribe().get(objectType);
        Schema.SobjectType shareObject = shareObjectMap.get(parentSobjectType);
        
        String soql = 'Select Id from {0} ';
        soql = string.format(soql, new String[]{string.valueOf(shareObject)});
        soql = soql + 'where RowCause = \'Manual\' and ParentId IN :recordIdSet and UserOrGroupId IN :UserOrGroupIdSet';
        
        List<Sobject> shareList = database.query(soql);
        system.debug(' **** deleteShare() : shareList - '+shareList);

        if(shareList.isEmpty() == false){
            Database.DeleteResult[] resultList=  Database.delete(shareList, false);
            for(Database.DeleteResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** deleteShare() : id - '+ result.getId());
                    system.debug('**** deleteShare() : error - '+ result.getErrors()[0]);
                    throw new PartnerShareHelperException(result.getErrors()[0].getMessage());
                }
            }            
        }

    } // end of deleteShare()
    
    // validate that the Sobject is supported by this class
    private void validateSobjectType(List<sObject> newList)
    {
        Schema.SobjectType sObjectType = newList.getSObjectType();
        if(accountFieldMap.containsKey(sObjectType) == false || shareObjectMap.containsKey(sObjectType) == false){
            throw new PartnerShareHelperException('Apex class PartnerShareHelper does not support SobjectType '+sObjectType);
        }
        accountField = accountFieldMap.get(sObjectType);
        objectType = string.valueOf(sObjectType);
    }
    
    private static List<Sobject> getRecords(String objectType, Set<Id> recordIdSet, String accountField){
        
        String soql = 'Select Id, {0} from {1} where Id IN :recordIdSet';        
        soql = string.format(soql, new String[]{accountField, objectType});
        system.debug(' **** getRecords() : soql - '+soql);
        
        Set<Id> customerIdSet = new Set<Id>();
        List<Sobject> recordList = new List<SObject>();
        for(Sobject record : Database.query(soql)){
            customerIdSet.add((Id)record.get(accountField));
            recordList.add(record);
        }
        return recordList;
    }
    
    // retrieve account partner info
    public static Map<ID, List<Account_Partner__c>> findPartners(Set<Id> customerIdSet)
    {
        system.debug(' **** findPartners() : customerIdSet - '+customerIdSet);
        if(partnerMap != null && partnerMap.keySet().containsAll(customerIdSet)){
            return partnerMap;
        }

        partnerMap = new Map<Id, List<Account_Partner__c>>();
        if(customerIdSet.isEmpty() == false) {
            for (Account_Partner__c partner : [
                    SELECT Customer__c, Partner__c, PublicGroupId__c
                    from Account_Partner__c
                    where Customer__c IN :customerIdSet
            ]) {
                List<Account_Partner__c> partnerList = partnerMap.get(partner.Customer__c);
                if (partnerList == null) {
                    partnerList = new List<Account_Partner__c>();
                    partnerMap.put(partner.Customer__c, partnerList);
                }
                partnerList.add(partner);
            }
        }
        system.debug(' **** findPartners() : partnerMap - '+partnerMap);
        return partnerMap;

    } // end of findPartners()

    // retrieve partner portal user info
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
*/
}